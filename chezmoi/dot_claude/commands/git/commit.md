---
allowed-tools: Bash(git:*)
description: Create a git commit using conventional commits
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

Using conventional commits and based on the above changes, create a single git commit. If the changes can be split into
further logical commits without breaking the code, do this instead.

The British English language MUST be used.

The format of the conventional commit should be as follows:

```
<type>(scope): <description>

<body>

<footer>
```

Avoid the need to provide a body/footer unless it would provide further context to a reader.

### Type

Commits MUST be prefixed with a type, followed by the optional scope, optional !, and required terminal colon and space.
The type should be either:

- fix: A bug has been patched/fixed.
- feat: A new feature has been added.
- build: Changes that affect the build system locally or externally such as CI/CD pipelines.
- chore: when a change doesn't match any other type.
- docs: Documentation has been added/changed, such as .md files or openapi specs.
- style: Changes that do not affect code output, such as formatting or CSS styles have been updated.
- refactor: A code change that neither fixes a bug nor adds a feature.
- perf: An improvement/optimisation has been made in code.
- test: A test has been created/updated.

### Scope

The scope is optional, it should supplement the type and give more context what has changed.

A scope MUST consist of a noun describing a section of the codebase surrounded by parenthesis, e.g., fix(parser):

### Description

A description MUST immediately follow the colon and space after the type/scope prefix. e.g., fix(parser): array parsing
issue when multiple spaces were contained in string.

The description MUST be in present tense and should be around 50 characters summarising the change. DO NOT go over 72 characters.

### Body

A longer commit body MAY be provided after the short description, providing additional contextual information about the
code changes. The body MUST begin one blank line after the description.

The body MUST be concise and MAY consist of any number of newline separated paragraphs.

### Footer

One or more footers MAY be provided one blank line after the body. Each footer MUST consist of a word token, followed by
a :<space>. e.g. Co-authored-by: NAME

The footer token MUST use - in place of whitespace characters, e.g., Acked-by (this helps differentiate the footer
section from a multi-paragraph body). An exception is made for BREAKING CHANGE, which MAY also be used as a token.

The footer value MAY contain spaces and newlines, and parsing MUST terminate when the next valid footer token/separator
pair is observed.

Breaking changes MUST be indicated in the type/scope prefix of a commit, or as an entry in the footer.

If included as a footer, a breaking change MUST consist of the uppercase text BREAKING CHANGE, followed by a colon,
space, and description, e.g., BREAKING CHANGE: environment variables now take precedence over config files.

If included in the type/scope prefix, breaking changes MUST be indicated by a ! immediately before the :. If ! is used,
BREAKING CHANGE: MAY be omitted from the footer section, and the commit description SHALL be used to describe the
breaking change.
