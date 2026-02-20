---
name: Agent Search
description: Provides a `/search` command that makes AI Agent act as a search engine, performing web searches and returning summarized results with citations.
model: claude-sonnet-4-5
argument-hint: [query]
---

# Search Command

## Description
Provides a `/search` command that makes AI Agent act as a search engine, performing web searches and returning summarized results with citations.

## Triggers
- User types `/search` followed by a query
- User asks to "search for [query]"
- User wants to perform a web search

## Instructions
1. When the user invokes `/search [query]`, extract the search query
2. Use the WebSearch tool to search for the query
3. Present the results in a clear, organized format with:
   - A brief summary of what was found
   - Key findings from the top results
   - Inline citations using [1], [2], etc.
   - Links to the sources at the end
4. If the query is empty or unclear, ask the user to provide a specific search query
5. Focus on the most relevant and authoritative information
6. Synthesize information across multiple sources when possible
