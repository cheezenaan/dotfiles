#!/usr/bin/env ruby
# frozen_string_literal: true

# permission-log.rb record          (hook: stdin JSON → JSONL)
# permission-log.rb audit [--all] [--since YYYY-MM] [--min N]

require "json"
require "fileutils"

REDACT_PATTERN = /(bearer |api[_-]?key[=:]\s*|token[a-z_]*[=:]\s*|password[a-z_]*[=:]\s*|secret[a-z_]*[=:]\s*)/i
REDACT_QUOTED = /#{REDACT_PATTERN}"[^"]*"/
REDACT_BARE = /#{REDACT_PATTERN}\S+/
SUBCOMMAND_TOOLS = %w[gh docker kubectl npm pnpm yarn bun cargo make chezmoi brew mise].freeze
# git 限定: 他ツールは実ログで問題が出てから対応 (YAGNI)
GIT_GLOBAL_OPTS_WITH_ARG = %w[-C -c --git-dir --work-tree].freeze
PATH_TOOLS = %w[Read Write Edit].freeze
# sudo/env prefix は正規化(剥がして集計)ではなく除外。Bash(systemctl:*) は sudo systemctl にマッチしない
SKIP_COMMAND = /[;&|`]|\$\(|\n|\A(sudo|timeout)\s|\A[A-Za-z_][A-Za-z0-9_]*=[^ ]+ /
ALLOW_THRESHOLD = 5
DENY_THRESHOLD = 3

EVENT_DECISION = {
  "PostToolUse" => "allow",
  "PostToolUseFailure" => "allow",
  "PermissionDenied" => "deny"
}.freeze

def log_dir
  ENV["CLAUDE_PERMISSIONS_LOG_DIR"] ||
    File.join(ENV.fetch("XDG_STATE_HOME", File.join(Dir.home, ".local", "state")),
      "claude", "permission-logs")
end

def realpath_safe(path)
  File.realpath(path)
rescue
  path
end

def redact(text)
  text.gsub(REDACT_QUOTED, "[REDACTED]").gsub(REDACT_BARE, "[REDACTED]")
end

# ── Record ─────────────────────────────────────

def build_entry(input)
  return nil unless input["permission_mode"] == "auto"
  return nil if input["tool_name"].to_s.empty? || input["cwd"].to_s.empty?
  return nil unless EVENT_DECISION.key?(input["hook_event_name"])

  tool_name = input["tool_name"]
  tool_input = input["tool_input"]
  tool_input = {} unless tool_input.is_a?(Hash)

  raw_summary = case tool_name
  when "Bash", *PATH_TOOLS
    raw = tool_input["command"] || tool_input["file_path"]
    raw.is_a?(String) ? redact(raw)[0, 200] : ""
  else
    ""
  end

  deny_reason = if input["hook_event_name"] == "PermissionDenied"
    reason = input["reason"]
    reason.is_a?(String) ? redact(reason)[0, 200] : nil
  end

  {
    ts: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
    cwd: input["cwd"],
    hook_event_name: input["hook_event_name"],
    tool_name: tool_name,
    raw_input_summary: raw_summary, # redact + truncate 済みだが既存ログとのキー互換のため改名しない
    deny_reason: deny_reason
  }
end

def write_entry(entry)
  dir = log_dir
  FileUtils.mkdir_p(dir, mode: 0o700)
  cwd = realpath_safe(entry[:cwd]).tr("/", "-")
  path = File.join(dir, "#{cwd}-#{entry[:ts][0, 7]}.jsonl")
  # "a" モードだと mode 引数が効かず TOCTOU になるため flag 指定
  File.open(path, File::WRONLY | File::APPEND | File::CREAT, 0o600) do |f|
    f.write("#{JSON.generate(entry)}\n")
  end
end

def record
  input = JSON.parse($stdin.read)
  entry = build_entry(input)
  write_entry(entry) if entry
rescue => e # fail-open: ログ欠損は許容、ツール実行は止めない
  warn "permission-log: #{e.class}: #{e.message}"
end

# ── Audit ──────────────────────────────────────

def find_log_files(directory, scope, cutoff)
  prefix = (scope == "project") ? Regexp.escape(realpath_safe(Dir.pwd).tr("/", "-")) : ".*"
  month_re = /\A#{prefix}-(\d{4}-\d{2})\.jsonl\z/
  Dir.children(directory)
    .select { |name| (m = name.match(month_re)) && m[1] >= cutoff }
    .map { |name| File.join(directory, name) }
    .sort
end

# 確実に判別できたサブコマンドのみ返す。許可リスト外のフラグは引数の有無が不明なので nil に倒す
def git_subcommand(tokens)
  args = tokens.drop(1)
  args.shift(2) while GIT_GLOBAL_OPTS_WITH_ARG.include?(args[0])
  args[0]&.start_with?("-") ? nil : args[0]
end

def extract_command_key(command)
  return nil if !command.is_a?(String) || command.empty?
  return nil if command.match?(SKIP_COMMAND)

  tokens = command.split
  return nil if tokens.empty?

  # サブコマンド不明の git も "git" として集計に残す
  if tokens[0] == "git"
    sub = git_subcommand(tokens)
    sub ? "git #{sub}" : "git"
  elsif SUBCOMMAND_TOOLS.include?(tokens[0])
    (tokens.length >= 2 && !tokens[1].start_with?("-")) ? "#{tokens[0]} #{tokens[1]}" : tokens[0]
  else
    tokens[0]
  end
end

def load_entries(files)
  files.each_with_object([]) do |path, acc|
    File.foreach(path) do |line|
      parsed = begin
        JSON.parse(line)
      rescue JSON::ParserError
        next
      end
      next unless parsed.is_a?(Hash)

      event = parsed["hook_event_name"]
      decision = EVENT_DECISION[event]
      next unless decision

      parsed["decision"] = decision
      parsed["command_key"] = if parsed["tool_name"] == "Bash"
        extract_command_key(parsed["raw_input_summary"])
      end
      acc << parsed
    end
  end
end

def grouping_key(entry)
  tool = entry["tool_name"] || ""
  if tool == "Bash"
    key = entry["command_key"]
    return nil unless key

    [tool, key]
  elsif PATH_TOOLS.include?(tool)
    path = entry["raw_input_summary"]
    cwd = entry["cwd"]
    dir = if path.nil? || path.empty?
      "."
    else
      norm = (cwd && !cwd.empty? && path.start_with?("#{cwd}/")) ? path[(cwd.length + 1)..] : path
      parts = norm.split("/").reject(&:empty?)
      if parts.length <= 1
        "."
      else
        pfx = norm.start_with?("/") ? "/" : ""
        pfx + parts[0...-1].first(2).join("/")
      end
    end
    [tool, dir]
  else
    [tool, ""]
  end
end

def build_candidates(entries, min_count)
  groups = entries.group_by { |e| grouping_key(e) }
  groups.delete(nil)

  results = groups.map do |(tool, group_key), items|
    next if items.length < min_count

    denied = items.select { |e| e["decision"] == "deny" }
    allow_count = items.length - denied.length
    deny_count = denied.length
    summaries = items.map { |e| e["raw_input_summary"] }.compact.reject(&:empty?).uniq

    target = if PATH_TOOLS.include?(tool) && (group_key == "." || group_key.start_with?("/"))
      "review"
    elsif !(tool == "Bash" || PATH_TOOLS.include?(tool))
      "review"
    elsif allow_count >= ALLOW_THRESHOLD && deny_count.zero?
      "allow"
    elsif deny_count >= DENY_THRESHOLD && allow_count.zero?
      "deny"
    else
      "review"
    end

    pattern = if tool == "Bash"
      (summaries.length == 1 && summaries[0] == group_key) ? "Bash(#{group_key})" : "Bash(#{group_key}:*)"
    elsif PATH_TOOLS.include?(tool)
      (group_key == ".") ? "#{tool}(**)" : "#{tool}(#{group_key}/**)"
    else
      tool
    end

    [target, {
      "pattern" => pattern,
      "allow_count" => allow_count,
      "deny_count" => deny_count,
      "examples" => summaries.first(3),
      "deny_reasons" => denied.map { |e| e["deny_reason"] }.compact.reject(&:empty?).uniq.first(3),
      "last_seen" => items.map { |e| e["ts"] }.compact.max
    }]
  end

  results.compact.sort_by { |_, c| -(c["allow_count"] + c["deny_count"]) }
end

def build_report(entries, candidates)
  buckets = {"allow" => [], "deny" => [], "review" => []}
  candidates.each { |target, candidate| buckets[target] << candidate }
  timestamps = entries.map { |e| e["ts"] }.compact

  {
    "candidates" => buckets,
    "summary" => {
      "date_start" => timestamps.min&.slice(0, 10),
      "date_end" => timestamps.max&.slice(0, 10),
      "total_entries" => entries.length
    }
  }
end

def audit(argv)
  require "date"
  require "optparse"
  options = {scope: "project", since: nil, min: 3}
  OptionParser.new do |opts|
    opts.on("--all") { options[:scope] = "all" }
    opts.on("--since MONTH") { |v| options[:since] = v }
    opts.on("--min N", Integer) { |v| options[:min] = v }
  end.parse!(argv)

  directory = log_dir
  unless File.directory?(directory)
    puts JSON.generate("error" => "log_dir_not_found", "message" => "Permission log directory not found: #{directory}")
    return
  end

  if options[:since] && options[:since] !~ /\A\d{4}-\d{2}\z/
    puts JSON.generate("error" => "invalid_since", "message" => "Invalid --since format: #{options[:since]} (expected YYYY-MM)")
    return
  end
  cutoff = options[:since] || (Date.today - 90).strftime("%Y-%m")
  files = find_log_files(directory, options[:scope], cutoff)
  if files.empty?
    puts JSON.generate("error" => "no_logs", "message" => "No permission log files found for this project.")
    return
  end

  entries = load_entries(files)
  candidates = build_candidates(entries, options[:min])
  puts JSON.pretty_generate(build_report(entries, candidates))
end

if __FILE__ == $PROGRAM_NAME
  case ARGV.shift
  when "record" then record
  when "audit" then audit(ARGV)
  else
    warn "Usage: #{$PROGRAM_NAME} {record|audit} [options]"
    exit 1
  end
end
