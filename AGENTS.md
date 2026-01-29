# AGENTS Code System Instructions

## Project Context
This is my development environment. Follow these preferences and conventions.

## Code Style Preferences
- Use 2 spaces for indentation (not tabs)
- Prefer async/await over promises
- Use meaningful variable names, avoid single letters except for loop indices
- Always use const/let, never var in JavaScript/TypeScript
- Use camelCase for variables and functions
- Use PascalCase for classes and components
- Use SCREAMING_SNAKE_CASE for constants
- Be descriptive and avoid abbreviations
- Ensure names reflect purpose
- Avoid using barrel imports

## Node.js Development
- **Always use `bun` by default** for Node.js projects
  - `bun install` - install dependencies
  - `bun run <script>` - run package.json scripts
  - `bun add <package>` - add dependencies
  - `bun remove <package>` - remove dependencies
  - `bun <file.ts>` - run TypeScript files directly
- Only use npm or yarn if the project explicitly requires it (e.g., existing lock files)

## iOS Development
- **Verify builds with xcbeautify** for cleaner output
  - `xcodebuild -scheme <SchemeName> -configuration Debug -sdk iphonesimulator build | xcbeautify`
  - Example: `xcodebuild -scheme iGotYouHaha -configuration Debug -sdk iphonesimulator build | xcbeautify`
- Use XcodeGen (`project.yml`) for project generation instead of committing `.xcodeproj`
- Install xcbeautify: `brew install xcbeautify`

## Git Commit Conventions
- Follow Conventional Commits format (feat, fix, docs, style, refactor, test, chore)
- Keep commit messages under 72 characters
- Write commit messages in imperative mood

## Testing Requirements
- Always run tests after making changes if test scripts exist
- Run linting and type checking before completing tasks

## Development Workflow
- **Use `using-superpowers` skill when starting any conversation** - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions
- **Always create a todo list before starting any operation** to track tasks and provide visibility
- Always read existing code before making changes
- Follow existing patterns and conventions in the codebase
- Prefer modifying existing files over creating new ones
- **Avoid running background tasks** like `bun run dev` - use foreground execution instead for better visibility and control

## File Operations
- **ALWAYS use `trash` instead of `rm`** for file deletion
  - `trash file.txt` - moves to trash (recoverable)
  - `trash -r directory/` - recursively trash directory
  - `trash-list` - view trashed files
  - `trash-restore` - recover deleted files
- Never use `rm -rf` as it permanently deletes files

## Security Guidelines
- Never commit sensitive information (API keys, passwords, tokens)
- Always use environment variables for configuration

## Tool Usage Preferences
- Use ripgrep (`rg`) instead of grep for searching
- Prefer using Glob and Grep tools over bash find/grep commands
- Always use absolute paths when working with files
