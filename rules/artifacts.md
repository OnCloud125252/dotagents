# Artifacts MCP

- **Offer an Artifacts page for rich results.** When a result is a report, a comparison, a measurement, a timeline, or a diagram that chat Markdown shows poorly, offer to publish it with the Artifacts MCP server (`labs_artifacts_*` tools). Keep short answers in chat.
- **Ask before you publish.** Anyone with the link can open a published artifact. Publish only after the user agrees. Do not put secrets, tokens, internal hostnames, or private data in the page.
- **Read the guide first.** Call `labs_artifacts_guide` before you write the content, and follow it: HTML by default, the starter CSS unchanged, no scripts, no external resources.
- **Pick the region.** Call `labs_artifacts_list_regions`. If it returns more than one region, ask the user which one to use.
- **Update, do not publish again.** To fix a page, call `labs_artifacts_update` with the artifact `id` and the last `versionId` as `ifMatch`. The URL stays the same.
- **Do not preview.** Do not start a local server, open a browser, or take a screenshot. Fix the `warnings` from the publish answer instead.
