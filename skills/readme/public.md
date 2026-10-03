# Public product README

The reader found the project through a search, a link, or a package registry.
The reader does not know the project.
In the first screen, the reader decides if the project is worth more time.
After that, the reader wants to install the project and get one result fast.

## Structure

Use these sections in this order.
Remove an optional section if it has no real content.

````markdown
<div align="center">

# <project-name>

<One sentence: what the project does and for whom. Under 120 characters.>

<badges on one line: optional, at most 4>

<img src="<path-to-proof>" width="720" alt="<what the image shows>">

[Installation](#installation) · [Usage](#usage) · [<Section>](#<section>)

</div>

## Highlights

- **<Short label>.** <A capability, with a number or a concrete detail.>
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

- **<Short label>.** <What the project does not do.>

## Contributing

## License
````

## Layout

The README must look clean on GitHub and on npm.
The reader scans before the reader reads.

- Center the header block with `<div align="center">`. Put a blank line after the opening tag and before the closing tag, so that Markdown inside the block still renders.
- Put all badges on one line. Some previews show each source line on its own line.
- Use `<img>` with `width="720"` for screenshots and GIFs, so that an image does not fill the full page.
- Below the proof, add one line of links to the main sections, separated by ` · `. Use this line instead of a full table of contents.
- Start each item in Highlights and Limitations with a bold short label that ends with a period. The reader can then scan the labels only.
- When the product has two or more commands or modes, start Usage with a table that compares them: the name, when to use it, and what it gives.
- When the output of the product is Markdown or rich text, show the sample output as a blockquote, not as a code block. A code block shows raw syntax and can scroll sideways.
- Do not depend on line breaks for layout. GitHub and npm join the lines of one paragraph. Use a blank line or a list to separate items.

### Tables

- Put the key column first and short columns, such as Default or Required, right after it. Put the long text column last.
- If every row has the same value in a column, remove the column and state the value once above the table.
- If one table mixes two kinds of rows, split it into two tables under two `###` headings.
- Keep cell text short. If a cell needs more than one sentence, move the details below the table.

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
