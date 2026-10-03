---
name: readme
description: Write or edit a README.md for a project or a directory. Use it when the user asks to create, rewrite, review, or update a README, or says "寫 README", "改 README", or "整理 README". It covers two audiences - public products that people outside the team install and use, and developer tools that only the owner or the team uses.
user-invocable: true
disable-model-invocation: false
---

# README

A README is the entry page of a project.
It answers the first questions of one reader and links to the rest.
It is not a manual.

## Workflow

1. Read the code before you write.
   Read the package manifest, the scripts, the entry points, the existing README, `AGENTS.md`, and `docs/`.
2. Find the source of the README.
   If a script or a command generates the README, edit that source and run it. Do not edit the output.
3. Pick the audience with the table below.
   If the signals conflict or are missing, ask the user.
4. Read the template for that audience and follow it:
   - Public product: [public.md](public.md)
   - Developer tool: [developer.md](developer.md)
5. Write the README with the rules in this file and in the template.
6. Verify the README with the checklist below.
7. Tell the user which commands you ran and which commands you did not run.

## Pick the audience

| Signal | Public product | Developer tool |
|---|---|---|
| Who uses it | People outside the team | The owner or the team |
| How people get it | Package registry, release binaries, app store, website | Clone the repo |
| First question of the reader | "Do I want this? How do I start?" | "How do I run it? How do I change it?" |
| Template | [public.md](public.md) | [developer.md](developer.md) |

A public product can also have developer content, such as build steps.
Put that content in `CONTRIBUTING.md` and link to it from the public README.

A README in a subdirectory describes only that directory.
Use the developer template for it, unless the directory is a package that people outside the team install.

## Language

- Public product: write in English.
- Developer tool: write in the language of the existing docs in the project. If there are no docs, ask the user.

## Rules for both audiences

### Content

- Put the one-line description first. It says what the project does, not how good it is.
- Every command must be copy-paste ready. Include the working directory if it matters.
- Show the expected output after a command when the output is not obvious.
- Keep the README short. If a section grows past about 40 lines, move the details to `docs/` and link to them.
- Link to files in the repo with relative paths. Absolute URLs break in forks and clones.
- If the project is deprecated or no longer maintained, say so in the first lines.
- Do not copy content that already lives in another file. Link to it instead.

### `AGENTS.md`

`AGENTS.md` holds build steps, code style, and rules for coding agents.
The README is for people.
If `AGENTS.md` already explains a topic, link to it from the README. Do not repeat it.

### Prose

- Write short sentences in active voice.
- Use one name for one thing in the whole README.
- Do not write "just", "simply", "easy", or "obviously". The reader may not know the project.
- Do not use marketing words, such as "powerful", "seamless", or "blazing fast". Show a number or an example instead.
- Explain each project-specific term the first time you use it.
- In Markdown source, put each full sentence on its own line.

### Format

- Use one `#` heading, the project name.
- Use `##` for sections and `###` for subsections. Do not go deeper than `###`.
- Add a table of contents only if the README is longer than about 100 lines.
- Use tables for options, environment variables, and commands.
- Mark every code block with a language, such as `sh`, `ts`, or `toml`.

## Verify

Do all of these steps before you report that the README is done:

1. Run every install, setup, and usage command in the README.
   If a command changes shared state or costs money, such as deploy or publish, do not run it. Tell the user instead.
2. Make sure the output in the README matches the real output.
3. Make sure every relative link points to a file that exists.
4. Make sure the one-line description matches the package manifest description and the repo description.
5. Make sure the README names no command, flag, or file that the code does not have.
