# Bug template

Describe the observed problem and expected behaviour using the user's evidence.
Keep the ticket name concise and use the body heading to expand on the symptom.
Separate observations from any suspected cause; do not invent a diagnosis.

Populate existing ClickUp fields for what happened and what was expected first.
Use the corresponding sections below only for information without a matching
field. If only one matching field exists, keep only the other section in the
body. Do not duplicate field content in the description.

Replace the placeholders. Include reproduction steps and environment details
only when known. Omit optional Context, Steps to reproduce, Environment, and
Evidence sections when there is nothing to include. Attach relevant supplied
artifacts through the ClickUp MCP and include supplied links in Context or
Evidence. A filename or local path in the body does not replace an attachment.

If it is an observed behaviour with a flow of an application then it should be
written for a less technical audience, for example don't including git commits
and code snippets unless explicitly asked. Any verbosity should be removed.

```markdown
# <Expanded description of the problem>

<Brief summary of the observed symptom and known user impact.>

## Context

<Relevant background and links to related tickets, PRs, or documents.>

## Steps to reproduce

1. <Known starting situation or action>
2. <Action that exposes the problem>

## What happened

<Observed behaviour; omit this section when captured in an existing field.>

## What we expected to happen

<Expected behaviour; omit this section when captured in an existing field.>

## Environment

<Known affected environment, device, browser, or version.>

## Evidence

<Supplied evidence links and descriptions of attached artifacts.>
```
