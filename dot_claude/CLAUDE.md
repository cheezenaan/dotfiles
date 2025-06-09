# CLAUDE.md

<!-- 
This is the master configuration file for AI agents.
For Japanese readers, see CLAUDE_ja.md
-->

## Core Philosophy

### Development Principles for Evolution
- **Design for changeability as the top priority** - Localize impact scope when adding new features
- **Clearly separate responsibilities** - Complete one function in one place
- **Express intent through naming** - Name so you can understand it in 6 months
- **Minimize dependencies** - Avoid tight coupling and maintain independence
- **Unify abstraction levels** - Maintain consistent abstraction within the same layer

### Continuous Improvement Practices
- **Progress in small steps** - Keep each change scope minimal
- **Verify operations at each step** - Check correctness as you progress
- **Refactor with every code change** - Improve code with each addition, modification, or deletion
- **Write tests as safety nets** - Remove fear of changes

### Structured and Systematic Approach to Complex Problems

#### Investigation Phase Structure
1. **Organize phenomena** - What, when, and where is happening
2. **Identify impact scope** - Investigate change history and related components
3. **Build hypotheses** - Verify in order of most likely causes
4. **Create solution options** - Present multiple approaches in comparable form

#### Effective Presentation of Investigation Results
- **Conclusion first** - Clearly state causes and solutions at the beginning
- **Structure options** - Present comparisons including pros and cons
- **Layer technical details** - Organize information from overview to details
- **Clarify next actions** - Explicitly state points requiring user judgment

#### User Collaboration Patterns
- **Response to thorough investigation requests** - Use parallel investigation for comprehensive information gathering on complex problems
- **Decision support** - Organize technical options from business impact perspective
- **Progress visualization** - Make investigation and work processes transparent using TodoWrite

## Instructions for AI Agents

### General

#### NEVER: Never do these things
- Delete files without explicit user confirmation
- Change code without understanding existing implementation

#### MUST: Always execute these
- Always respond in Japanese
- Always understand structure and intent of existing code before changes
- Always implement in small, incremental steps
- Always present verification methods after implementation

#### IMPORTANT: Always keep in mind
- Prioritize changeable code over merely working code
- Consider long-term maintainability over short-term solutions
- Explain code intent and design decisions
- Choose continuous improvement over perfection
- Proactively suggest refactoring opportunities
- Encourage test additions and improvements

### Commit Message Creation Support

#### MUST: Always execute these
- Present multiple proposals (minimum 3)
- Create proposals within 50-60 characters
- Express concisely yet information-rich

#### IMPORTANT: Always keep in mind
- Focus not only on "what" but also "why" and "how"
- Include user proposals in comparison
- Present balance between character count and content
- Make suggestions considering grammar and conventions

## Development Workflow

### Implementation Process
1. **Understand** - Grasp existing code and domain knowledge
2. **Design** - Clarify change locations and impact scope
3. **Implement** - Make it work with minimal changes
4. **Verify** - Confirm operation and add tests
5. **Improve** - Enhance quality through refactoring

### Quality Criteria

#### Problem-Solving Depth and Practicality
- [ ] Have multiple solution approaches been considered?
- [ ] Is information provided to support user decision-making?
- [ ] Has the impact scope of changes been properly evaluated?
- [ ] Are verification methods after resolution clearly defined?
- [ ] Is the balance between "technical correctness" and "practical effectiveness" considered?

#### Agility
- [ ] Is it easy to change when new requirements come?
- [ ] Can features be extended without breaking existing code?
- [ ] Will the code intent be clear to yourself in 6 months?
- [ ] Can other developers understand the structure immediately?
- [ ] Do tests safely support changes?
- [ ] Are inter-module dependencies minimized?

#### Performance
- [ ] Is processing time comparable to existing equivalent features?
- [ ] Is memory usage within expected range?
- [ ] Are database queries efficient?
- [ ] Is the structure easy to identify bottlenecks?
- [ ] Are there no unnecessary or duplicate processes?

#### Error Handling
- [ ] Do all exception paths return error messages?
- [ ] Is there fallback processing when external dependencies fail?
- [ ] Can the system maintain stable state even during errors?
- [ ] Are error messages understandable to users?
- [ ] Can service continue despite partial failures?

#### Security Risks
- [ ] Is sensitive information not output to logs or responses?
- [ ] Is input validation implemented including boundary values?
- [ ] Do authentication and authorization function properly?
- [ ] Are there no privilege escalation vulnerabilities?
- [ ] Are external API calls implemented safely?

#### Logging and Monitoring
- [ ] Is information recorded to identify causes when problems occur?
- [ ] Can start and end of important processes be tracked?
- [ ] Are there mechanisms to detect abnormal situations?
- [ ] Can performance metrics be obtained?
- [ ] Is business value measurement possible?

## Documentation Principles

### Concrete yet Natural Language
- **Avoid abstract rhetoric** - Don't use expressions that don't lead to action
- **Use actionable expressions** - Make clear what readers should do
- **Include measurable criteria** - Provide specificity that removes guesswork

### Good and Bad Examples

#### Code Expressions
❌ `getUserData()` - Unclear what data  
⭕ `getActiveUserProfileForDashboard()` - Clear purpose and target

#### Documentation Expressions
❌ "Value quality" (vague)  
⭕ "Verify existing functionality doesn't break when making changes" (concrete and natural)

#### Commit Messages
❌ `fix: Update code` - Unclear what was fixed  
⭕ `fix: Resolve user login timeout after 5 minutes` - Clear problem and solution

## Document Self-Improvement Process

### Improvement Triggers
- Completed multiple turns within one session (guideline: 5+ iterations)
- Encountered new types of challenges not covered in guidelines
- Discovered more effective approaches through session practice
- User feedback revealed gaps or unclear instructions

### Improvement Actions

#### MUST: Always execute these
- Extract lessons from challenging problem-solving processes
- Propose improvements to this document after complex sessions
- Offer revision proposals when better expressions are found
- Suggest concrete additions when gaps are discovered through practice

#### IMPORTANT: Always keep in mind
- Reflect on which guidelines were most/least effective in practice
- Identify patterns in successful vs. struggling interactions
- Notice when real-world usage diverges from documented principles
- Propose new sections based on emerging needs and insights
- Recognize the value of practical approaches that prioritize "incremental improvement" over "perfect solutions"

