# Developer tool README

The reader is the owner, a teammate, or a new team member.
The reader already knows why the project exists.
The reader wants to run the project, change it, and not break it.
Keep the README under about 100 lines.

## Structure

Use these sections in this order.
Remove an optional section if it has no real content.

````markdown
# <project-name>

<One sentence: what the project does.>
<One sentence: where it fits in the larger system, and what it talks to.>
<Status, only if it is not in active use: deprecated, experimental, or replaced by <other-project>.>

## Setup

<Requirements: tools and versions that the setup script does not install.>

```sh
<one command that installs the dependencies and prepares the project>
```

<Manual steps: only the steps that no script does, such as getting a secret.>

## Commands

| Command | What it does |
|---|---|
| `<command>` | Start the project for development |
| `<command>` | Run all tests and lint |
| `<command>` | <other common tasks, such as build, deploy, or release> |

## Configuration

| Variable | Required | What it does |
|---|---|---|
| `<NAME>` | <yes / no> | <purpose and where to get the value> |

## Nomenclature

- **<term>**: <meaning in this project>

## Architecture

## Further docs

- [<topic>](docs/<file>.md)
````

## Rules for each section

### Description

- Say what the project does in one sentence.
- Say what the project depends on and what depends on it. Name the other services, repos, or tools.
- If the project is deprecated, experimental, or replaced, say so in the first lines. If it is in active use, do not add a status line.

### Setup

- List only the tools that the setup script does not install. Give the required version for each tool.
- Give one command that does the full setup. If the project has no such command, suggest that the user add one.
- List only the steps that no script can do, such as getting a secret or an account.
- Tell the reader how to confirm that the setup worked.

### Commands

- List the commands that a developer runs every week.
- Make one command run all tests and lint. If the project has no such command, suggest that the user add one.
- Use the names that the project already uses, such as `package.json` scripts, `Makefile` targets, or `script/` files. Do not invent new names in the README.
- If a command changes shared state, such as deploy or a database migration, say so in its row.

### Configuration

- List every environment variable and config file that the project reads.
- Say where to get each value. Do not put real secrets or real values in the README.
- If `.env.example` or a similar file exists, link to it and do not repeat its content.

### Nomenclature

- Define the terms that a new team member will not know: names in the domain, short forms, and internal project names.
- Skip this section if there are no such terms.

### Architecture

Use this section only when the code has more than one main part.
If the code has more than about 10,000 lines, move this content to `ARCHITECTURE.md` and link to it.

- Start with one paragraph about the problem that the code solves.
- Give a code map. For each main directory or module, write one line that says what it does.
- The code map must answer "Where is the code that does X?"
- Name important files, modules, and types. Do not link to them, because links go stale. The reader can search for a name.
- State the rules that the code must not break, such as "the model layer never imports from the view layer". These rules are often hard to see in the code.
- Show the boundaries between layers and systems.
- Write only facts that do not change often. Do not describe how each module works inside.

### Further docs

- Link to each file in `docs/` with one line about its topic.
- Link to `AGENTS.md` if it exists. Do not repeat its content.

## Do not

- Do not explain why the project exists at length. The reader already knows.
- Do not add Highlights, badges, a License section, or a Contributing section. Add a License section only if the repo is public.
- Do not write a tutorial. Write commands and facts.
