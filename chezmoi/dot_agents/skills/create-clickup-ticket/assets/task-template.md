# Task template

Describe the outcome in language a product owner, tester, or business analyst can
follow. Do not include code-level implementation details unless explicitly asked:
no code snippets, file paths, functions, database changes, or prescribed technical
approaches. If requested, put implementation notes after the acceptance criteria
and keep the criteria focused on observable product behaviour.

Use the following body structure. Replace the placeholders and omit Context when
there are no relevant references. The body heading can expand on the short ticket
name. Context may link related tickets, previous PRs, or external documents.

Add one numbered `AC<NUM> - <short description>` subheading per scenario, starting
at AC1. Keep each Given/When/Then statement on its own line and bold the exact
words **Given**, **When**, and **Then**. Describe the starting situation, user
action or event, and observable outcome. Include only scenarios supported by the
request or conversation. Optional succinct bullets after Then can highlight
specific checks; omit them when the scenario is sufficient.

```markdown
# <Expanded description of the task>

<Brief description of the desired product outcome.>

## Context

<Relevant background and links to related tickets, PRs, or documents.>

## Acceptance criteria

### AC1 - <Short description>

**Given** <Starting situation>

**When** <User action or event>

**Then** <Observable product outcome>

- <Optional specific thing to check>
```
