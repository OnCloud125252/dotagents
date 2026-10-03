# Public product README

The reader found the project through a search, a link, or a package registry.
The reader does not know the project.
In the first screen, the reader decides if the project is worth more time.
After that, the reader wants to install the project and get one result fast.

## Structure

Use these sections in this order.
Remove an optional section if it has no real content.

````markdown
# <project-name>

<badges: optional, at most 4>

<One sentence: what the project does and for whom. Under 120 characters.>

<Proof: a screenshot, a GIF, a terminal recording, or a benchmark chart. Optional for libraries.>

## Highlights

- <A capability, with a number or a concrete detail>
- <3 to 6 items>

## Installation

```sh
<the fastest install command>
```

<Other methods: one line each, or a link to the full install page.>

## Usage

```<language>
<the smallest complete example>
```

<Expected output.>

## <Feature section, optional, one per major feature>

## Limitations

## Contributing

## License
````

## Rules for each section

### Title and badges

- Use the name that people type to install or run the project.
- Put at most 4 badges. Use only badges that answer a question of the reader, such as the latest version, the CI status, or the supported runtime versions.
- Do not add badges for social counts, sponsors, or chat links. Put those links in Contributing.

### One-line description

- Say what the project does and for whom. Do not describe how good it is.
- Keep it under 120 characters.
- Use the same text in the package manifest and the repo description.
- If you need more context, add a second paragraph of at most 3 sentences.

### Proof

- Show the project at work. Use an image, a GIF, a terminal recording, or a chart.
- Add alt text that says what the image shows.
- For a library with no visual output, skip the proof. The Usage example does the same job.

### Highlights

- List 3 to 6 capabilities.
- Put a number, a comparison, or a concrete detail in each item.
- Link each item to its feature section or to the full docs.

### Installation

- Put the fastest method first. The reader must be able to copy and run it.
- List the required runtime or OS versions before the command, if there are any.
- Give each other method one line. If there are more than 4 methods, link to a full install page.
- Show how to check that the install worked, such as `<command> --version`.

### Usage

- The first example must be complete. Include the imports, the setup, and the call.
- Show the expected output.
- Later examples can be shorter and can build on the first example.
- Link to the full docs or to the examples directory for more cases.

### Feature sections

- Write one section for each major feature. Each section gets one short example and a link to the details.
- Mention every public feature, even advanced ones. One line and a link are enough for an advanced feature.
- Do not copy the full reference of options or APIs into the README. Link to the reference.

### Limitations

- State what the project does not do, and when another tool is a better choice.
- An honest limit makes the reader trust the rest of the README.

### Contributing

- Say where to ask questions and where to report bugs.
- Say if pull requests are welcome.
- Put the build and test steps in `CONTRIBUTING.md` and link to it.

### License

- Put the SPDX license name and link to the `LICENSE` file.
- This section is always last.

## Do not

- Do not add an FAQ section. Put each answer in the section where the reader looks for it.
- Do not add a changelog to the README. Link to `CHANGELOG.md` or to the releases page.
- Do not list every platform install command in the README. Link to an install page.
