# Create commit message

Generate optimized commit messages with high information density and context-aware analysis

## Instructions

1. **Environment Analysis and Prerequisites**
   - Verify git repository status and working directory state
   - Check for staged changes availability using git status
   - Validate git configuration and repository health
   - Identify project type, framework, and development context
   - Analyze existing commit history patterns for consistency

2. **Staged Changes Deep Analysis**
   - Execute comprehensive diff analysis of staged changes
   - Categorize modifications by impact scope (feat/fix/refactor/etc.)
   - Identify affected components, modules, and architectural layers
   - Assess change complexity and cross-cutting concerns
   - Map changes to business value and technical debt impact

3. **Context-Aware Message Generation Strategy**
   - Analyze recent commit patterns for style consistency
   - Detect project-specific conventions and scope preferences
   - Evaluate change motivation through code structure analysis
   - Prioritize "why" reasoning over "what" descriptions
   - Balance information density with character constraints (50-72 chars)

4. **Multi-Option Message Creation**
   - Generate 3 distinct conventional commit proposals
   - Optimize each message for different emphasis priorities:
     - Business impact focus (user/stakeholder value)
     - Technical improvement focus (code quality/architecture)
     - Problem resolution focus (bug fixes/performance)
   - Ensure each proposal captures the essential "why" behind changes
   - Validate scope accuracy and type classification

5. **Quality Assurance and Validation**
   - Verify conventional commits format compliance
   - Check character count adherence (50-72 character target)
   - Validate grammar, spelling, and technical terminology
   - Ensure message uniqueness and information density
   - Cross-reference with existing commit history for consistency

6. **Intelligent Fallback Strategy**
   - Primary: Generate context-aware messages based on full analysis
   - Secondary: If complex changes detected, offer component-based breakdown
   - Tertiary: If analysis fails, provide template-based suggestions
   - Final: Always maintain workflow continuity with manual guidance

7. **Educational Enhancement and Best Practices**
   - Explain rationale behind each message proposal
   - Highlight conventional commits best practices applied
   - Provide context about information density optimization techniques
   - Suggest improvements for future commit message patterns
   - Reference authoritative guidelines and standards

8. **Adaptive Output Formatting**
   - Present messages in order of recommendation strength
   - Include brief rationale for each proposal's focus
   - Provide character count metrics for each option
   - Highlight scope and type reasoning for transparency
   - Offer copy-paste ready format for immediate use

## Success Criteria

- All 3 proposals follow conventional commits format strictly
- Character count maintained between 50-72 characters per message
- Each message captures distinct "why" perspective with high information density
- Proposals demonstrate clear understanding of change context and impact
- Educational value provided through rationale explanations

## User Interaction Guidelines

Remember to:

- Ask clarifying questions when change context is ambiguous
- Provide multiple perspectives on the same changes
- Explain the reasoning behind scope and type selections
- Suggest logical next steps after message selection
- Offer learning resources for conventional commits mastery

## Framework Adaptation

- Detect project framework automatically (React, Vue, Angular, etc.)
- Adapt scope suggestions to framework-specific conventions
- Provide framework-appropriate technical terminology
- Align message style with project's established patterns
- Consider framework-specific impact areas in analysis