---
name: create-clickup-ticket
description: >
  Create ClickUp task and bug tickets using the installed ClickUp MCP. Use when
  the user asks to create, raise, file, or draft a ClickUp ticket, turn a
  conversation into a ClickUp task, or report a bug in ClickUp. Produces concise
  names, product-focused task acceptance criteria, and bug reports that use
  existing ClickUp fields and supplied evidence.
---

# Create ClickUp Ticket

## Gather the essentials

Use the current request and conversation to identify the ticket type, desired
outcome, destination list, and relevant references or artifacts. Ask only for
missing information that affects the ticket's meaning or destination. Do not
invent requirements, reproduction steps, observed results, or links.

Write a high-level ticket name, aiming for 40 characters or fewer including
spaces. Put detail in the body heading rather than crowding the name. Preserve
an exact name when the user explicitly requests it.

Read the template for the ticket type; paths are relative to this skill:

- Task: [Task template](assets/task-template.md).
- Bug: [Bug template](assets/bug-template.md).

## Use ClickUp

Use the installed ClickUp MCP for ClickUp reads and writes. Inspect the available
tool schemas; tool prefixes may differ between clients. If the MCP is unavailable,
provide a draft and explain that it has not been created.

1. Resolve the user's destination list with `clickup_get_list`. Reuse a list
   already specified in the conversation; ask if it is missing or ambiguous.
2. Inspect the list's custom field definitions with `clickup_get_custom_fields`,
   including inherited fields where needed. Use the returned IDs, types, and
   options. Ask for missing required values instead of guessing them. A failed
   lookup does not mean fields are absent; resolve it before creating the ticket.
3. For a bug, use existing writable fields whose meaning matches what happened
   and what was expected, even if their names differ. Map each independently:
   populate a matching field and omit its corresponding description section;
   keep the template section for any field that does not exist. Ask about an
   ambiguous mapping. Do not create or change field definitions.
4. Create the ticket with `clickup_create_task`, using `markdown_description` and
   any applicable `custom_fields`. Enable required-field validation when supported.
   Use an existing task type when available; do not assume the list defines a
   type named `Bug`. Leave status, assignees, priority, and dates at their defaults
   unless the user supplied them. For a draft-only request, return the prepared
   name, body, and field values without creating a ticket.
5. Attach relevant user-supplied files to the created ticket through the MCP's
   attachment flow. For local files, use `clickup_request_attachment_upload` and
   complete the returned upload instructions; a local path alone is not an
   attachment. Use `clickup_attach_task_file` for supported remote file sources.
   Preserve supplied reference links in Context or Evidence with descriptive
   link text. Report attachment failures without recreating the ticket.
6. Verify the saved description, populated fields, and attachments with
   `clickup_get_task`, requesting those sections explicitly. If creation times
   out, check for the ticket before retrying so the user does not get duplicates.

Return the created ticket as a Markdown link using its name and the URL returned
by ClickUp. Mention any incomplete fields or attachments. Do not claim success
for a draft or an unverified write.
