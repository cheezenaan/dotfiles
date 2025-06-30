# Capture session record

Generate comprehensive session records with technical insights and emotional reflections from current interactions

## Instructions

1. **Prerequisites Verification**
   - Detect working directory type (git repository or standard directory)
   - Verify write permissions for target output directory
   - Check template file availability at ~/.claude/templates/02.LOG.md
   - Validate system datetime accessibility for filename generation
   - Confirm session context availability for comprehensive analysis

2. **Session Analysis and Content Extraction**
   - Analyze all interactions within current session comprehensively
   - Extract primary activities, decisions, and outcomes
   - Identify encountered problems and their resolution methods
   - Capture technical discoveries, learning moments, and insights
   - Determine key concepts and themes for filename generation
   - Recognize emotional journey and thought processes throughout session
   - Document notable quotes, breakthrough moments, and frustrations

3. **Output Configuration and Generation**
   - Determine optimal output path based on directory type:
     - Git repository: $(git rev-parse --show-toplevel)/.tmp/_logs
     - Non-git directory: $(pwd)/.tmp/_logs
   - Create output directory structure if it doesn't exist
   - Generate filename in format: YYYYmmdd_HHmm_description.md
   - Request description from user or intelligently auto-generate from session context
   - Load template from ~/.claude/templates/02.LOG.md
   - Populate all template sections with extracted and analyzed content

4. **Quality Validation and Enhancement**
   - Verify all template sections contain meaningful, relevant content
   - Check technical accuracy of captured information and code examples
   - Validate authenticity and depth of emotional insights
   - Ensure no sensitive information (passwords, keys, personal data) is exposed
   - Confirm proper markdown syntax and formatting
   - Add contextual improvements and cross-references where beneficial
   - Enhance readability with appropriate structure and emphasis

5. **Delivery and Continuous Improvement**
   - Write formatted content to target file location
   - Provide user with confirmation of successful file creation and location
   - Offer preview option before final write if requested
   - Suggest related actions based on captured insights and next steps
   - Collect implicit feedback signals for future session analysis improvements

## Error Handling Strategy

1. **Primary Path**: Load external template from ~/.claude/templates/02.LOG.md
2. **Secondary Path**: If template missing, use embedded minimal template with core sections
3. **Tertiary Path**: If file write fails, output formatted content to stdout
4. **Final Fallback**: Provide step-by-step manual creation instructions with template structure

## Success Criteria

- Session record generated and saved within 30 seconds of request
- All major session activities and insights captured with >90% completeness
- Emotional journey authentically documented without loss of professional value
- Technical insights clearly articulated with actionable takeaways
- Output file successfully created and accessible at specified location
- User finds genuine value in the generated record for future reference

## Context Adaptation

This command automatically adapts to:

- Session complexity, duration, and interaction patterns
- Balance between technical and non-technical content
- User's communication style and preferences
- Current project context and domain
- Available template customizations and organizational preferences

## Best Practices Integration

This command demonstrates key principles:

- **Implicit Parameter Design**: No complex configuration required from user
- **Systematic Multi-Phase Approach**: Clear progression through analysis, generation, and validation
- **Graceful Degradation**: Multiple fallback paths ensure delivery under various conditions  
- **Educational Value**: Structured reflection promotes learning and knowledge retention
- **Measurable Outcomes**: Defined success metrics enable continuous improvement
- **Emotional Intelligence**: Recognizes the human aspects of technical work

## User Interaction Guidelines

Remember to:

- Ask clarifying questions when session context is ambiguous
- Confirm output location and filename before writing
- Provide content preview if user requests it
- Explain the value of each template section when generating content
- Suggest logical next steps based on captured insights and plans
- Offer to customize sections based on specific user needs or preferences
