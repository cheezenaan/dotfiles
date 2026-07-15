# frozen_string_literal: true

require "minitest/autorun"

load File.expand_path("executable_permission-log.rb", __dir__)

class ExtractCommandKeyTest < Minitest::Test
  def test_git_status
    assert_equal "git status", extract_command_key("git status")
  end

  def test_npm_version_flag
    assert_equal "npm", extract_command_key("npm --version")
  end

  def test_docker_ps
    assert_equal "docker ps", extract_command_key("docker ps")
  end

  def test_plain_command
    assert_equal "ls", extract_command_key("ls -la")
  end

  def test_sudo_prefix_skipped
    assert_nil extract_command_key("sudo git log")
  end

  def test_empty_string
    assert_nil extract_command_key("")
  end

  def test_nil_input
    assert_nil extract_command_key(nil)
  end

  def test_git_dash_c_path_log
    assert_equal "git log", extract_command_key("git -C /some/path log")
  end

  def test_git_dash_c_key_value_commit
    assert_equal "git commit", extract_command_key("git -c user.name=x commit")
  end

  def test_git_dir_and_work_tree
    assert_equal "git log", extract_command_key("git --git-dir /x --work-tree /y log")
  end

  def test_git_chained_flags
    assert_equal "git log", extract_command_key("git -C /x -c a=b log")
  end

  def test_git_unknown_flag_fallback
    assert_equal "git", extract_command_key("git --no-pager log")
  end

  def test_git_equals_form_fallback
    assert_equal "git", extract_command_key("git --git-dir=/x log")
  end

  def test_git_token_exhausted_fallback
    assert_equal "git", extract_command_key("git -C /path")
  end

  def test_git_bare
    assert_equal "git", extract_command_key("git")
  end

  def test_git_truncated_mid_token
    # record 時の 200 文字 truncate でトークンが断たれた場合、断片がサブコマンドとして返る。
    # 防止は record 側の責務なのでここでは現実の挙動を記録する
    truncated = "git -C /some/path checkout"[0, 20] # => "git -C /some/path ch"
    assert_equal "git ch", extract_command_key(truncated)
  end

  def test_pipe_skipped
    assert_nil extract_command_key("git log | head")
  end

  def test_chezmoi_apply
    assert_equal "chezmoi apply", extract_command_key("chezmoi apply")
  end
end
