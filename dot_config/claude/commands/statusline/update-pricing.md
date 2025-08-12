# Update Claude Pricing

Scrape latest Claude model pricing from Anthropic official documentation and save as JSON

## Instructions

1. **Official Pricing Data Retrieval**
   - Access <https://docs.anthropic.com/en/docs/about-claude/pricing#model-pricing>
   - Extract pricing table data for all Claude models
   - Verify data integrity and completeness before processing

2. **Model Pricing Analysis and Extraction**
   - Parse HTML table structure to extract pricing information
   - Focus on these columns: Model, Base Input Tokens, 5m Cache Writes, Cache Hits & Refreshes, Output Tokens  
   - Convert pricing format from "$X/MTok" to per-token decimal (divide by 1,000,000)
   - Map model display names to technical identifiers used in statusline.js:
     - "Claude Sonnet 4" → "claude-sonnet-4-20250514"
     - "Claude 3.5" → "claude-3-5-sonnet-20241022"
     - "Claude Opus 4" → "claude-opus-4"
     - Keep other models using normalized lowercase-dash format

3. **JSON Structure Generation**
   - Create structured JSON with metadata:

   ```json
   {
     "last_updated": "2025-08-12T10:30:00.000Z",
     "source": "https://docs.anthropic.com/en/docs/about-claude/pricing",
     "models": {
       "claude-sonnet-4-20250514": {
         "input": 0.000003,
         "output": 0.000015, 
         "cacheCreate": 0.00000375,
         "cacheRead": 0.0000003
       }
     }
   }
   ```

4. **File System Integration**
   - Save JSON to: ~/.config/claude/pricing.json
   - Ensure proper file permissions and backup existing file if present
   - Verify JSON validity before saving
   - Create parent directories if they don't exist

5. **Validation and Quality Assurance**
   - Verify all expected models are present in scraped data
   - Check numerical values are reasonable (input < output, cache rates logical)
   - Ensure model identifiers match statusline.js expectations
   - Validate JSON syntax and structure

6. **User Feedback and Reporting**
   - Report number of models successfully updated
   - List model names and key pricing points
   - Show timestamp of update completion
   - Indicate any models that couldn't be processed

## Success Criteria

- JSON file created at ~/.config/claude/pricing.json with valid structure
- All active Claude models included with accurate pricing
- Model identifiers match those expected by statusline.js
- Pricing values converted correctly from $/MTok to per-token decimals
- Metadata includes update timestamp and source URL

## Error Handling

- If website is unreachable, provide clear error message
- If table structure changes, report parsing failure details
- If model names change, suggest identifier mapping updates
- Preserve existing pricing.json as backup before updates

## Integration Notes

This command updates pricing data consumed by:

- ~/.config/claude/statusline.js (cost calculation)
- Any other scripts relying on ~/.config/claude/pricing.json

Run this command when:

- Starting new projects to ensure latest pricing
- Hearing about Anthropic pricing changes
- Statusline shows outdated cost information
