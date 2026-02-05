---
name: Changelog Generator
description: Generate a user-facing changelog of new features and bug fixes since a commit
model: claude-sonnet-4-5
argument-hint: [from_commit] [language]
---

Generate a concise, user-facing changelog with intelligent grouping and natural language descriptions inMarkdown format.

### Arguments
- $1: starting ref (commit/tag/branch). Default: latest tag; fallback HEAD~20
- $2: output language. Default: "English". Common: "Traditional Chinese", "Simplified Chinese", "Japanese", "Korean"

### Process

1. **Parse Arguments**: Extract `$1` (ref), `$2` (language), and `$3` (flag) from $ARGUMENTS. Trim quotes.
   - If $1 missing: try `git describe --tags --abbrev=0`; fallback to HEAD~20
   - If $2 missing: use "English"
   - If $3 is `--show-commits`: include commit hashes in output; otherwise omit them

2. **Validate Start Ref**: Run `git rev-parse --verify $1`. If invalid, ask for a valid ref.

3. **Collect Commits**: Use `git log --no-merges --pretty=format:%H::%s::%b $1..HEAD`
   - If no commits found, state "No new changes since <ref>"
   - Parse each commit: hash, subject, body
   - For each commit, determine type by prefix: feat, fix, refactor, perf, docs, chore, test, style, ci, build
   - Extract scope if present (e.g., `feat(auth):` → scope="auth")

4. **Categorize Commits**:
   - `feat*` subjects → **New Features**
   - `fix*` subjects → **Bug Fixes**
   - Commits with `BREAKING CHANGE:` in body → **Breaking Changes**
   - `perf*` → **Performance Improvements**
   - `docs*` → **Documentation Updates**
   - Ignore: chore, refactor, test, style, ci, build
   - Strip conventional commit prefixes (`feat(scope): description` → `description`)

5. **Intelligent Grouping & Summarization**:
   - **Group by feature area**: If multiple commits affect the same scope/area, combine them into a single bullet
   - **Create descriptive titles**: Transform technical commit messages into user-friendly descriptions
   - **Examples**:
     - `feat(auth): add oauth2` + `feat(auth): add token refresh` → "**OAuth2 authentication system**: Implemented OAuth2 login with automatic token refresh"
     - `fix(ui): button alignment` + `fix(ui): mobile layout` → "**UI layout fixes**: Corrected button alignment and mobile responsiveness"
   - **Use bold for feature/fix names**: `**Feature name**: Description of what changed`
   - Keep descriptions concise but informative

6. **Build Changelog**:
   - **No header/title** - start directly with sections
   - **Sections** (only include if non-empty):
     - Breaking Changes (⚠️ emoji if English)
     - New Features
     - Bug Fixes
     - Performance Improvements
     - Documentation Updates
   - **Section format**:
     - H2 heading with colon: `## New Features:` or `## 新功能：`
     - Bullet points directly after (no blank line): `* **Bold title**: Description`
     - If `--show-commits` flag present: append ` (hash)` to each bullet
   - **Language-specific formatting**:
     - Traditional Chinese: Use full-width colon `：` for section headers
     - English: Use regular colon `:` for section headers
   - Combine related commits intelligently
   - Use natural, user-facing language

7. **Translate Content**: 
   - Translate section headings based on language:
     - Traditional Chinese: "新功能：", "錯誤修復：", "重大變更：", "效能改善：", "文件更新："
     - Simplified Chinese: "新功能：", "错误修复：", "重大变更：", "性能改进：", "文档更新："
     - Japanese: "新機能：", "バグ修正：", "破壊的変更：", "パフォーマンス改善：", "ドキュメント更新："
   - Translate feature/fix titles and descriptions naturally
   - Keep technical terms (API names, component names, variable names) in English
   - Ensure natural phrasing in target language

8. **Output & Copy**: 
   - Display the changelog
   - Copy to clipboard using `pbcopy` (macOS) or `xclip` (Linux) if available
   - Show success message: "✓ Changelog copied to clipboard" (or translated equivalent)

### Tips
- Use semantic commit messages (conventional commits) for better categorization
- Related commits in the same area will be automatically grouped
- The command intelligently summarizes multiple commits into coherent feature descriptions
- Omit `--show-commits` for cleaner, more user-facing changelogs (recommended for release notes)
- Include `--show-commits` for internal team changelogs or detailed tracking
