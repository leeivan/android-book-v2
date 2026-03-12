---
name: android-reference-polisher
description: Polish and restructure Android book chapters by synthesizing local reference PDFs under D:\android-book-v2\reference together with repo writing rules. Use when Codex must improve chapter quality from reference materials, extract ideas and teaching structure from those sources, and rewrite the chapter in original textbook-style prose without quoting, translating, or closely mirroring source wording.
---

# Android Reference Polisher

Use this skill when a chapter should be polished or rewritten with help from the local reference books in `..\..\..\reference`, and the output must be original teaching prose rather than translated or lightly edited source material.

## Read in this order

1. Read the target chapter and its neighboring chapters first.
2. Read `..\..\docs\style-guide.md`, `..\..\docs\chapter-template.md`, `..\..\docs\source-policy.md`, and `..\..\docs\full-prose-standard.md`.
3. Read `references/reference-map.md` to choose the most relevant local books by topic.
4. Read `references/paraphrase-policy.md` before using any reference text.
5. Use the scripts in `scripts/` to enumerate references or extract text when needed.

## Core rule

Do not quote, translate, or line-by-line restate the reference books.

The chapter must be rewritten in fresh Chinese textbook prose. Reference books are there to improve:

- conceptual framing
- chapter sequencing
- examples and case choices
- practice task realism
- terminology accuracy
- comparison depth

They are not there to supply sentences for reuse.

## When to use which references

- For Kotlin language and modern Jetpack usage, start from the Kotlin- and Jetpack-focused reference books listed in `references/reference-map.md`.
- For chapter practice sections and project-style explanations, prefer the project-oriented references.
- For broad chapter reframing, combine one platform-focused reference with one project-oriented reference instead of leaning on a single book.

## Required workflow

1. Diagnose the chapter before opening references.
- What is thin, unclear, too bullet-heavy, too API-like, or poorly sequenced?
- Which teaching gap are you trying to close: concept, example, comparison, practice, or project context?

2. Choose only 1 to 3 relevant references.
- Do not open every book by default.
- Pick the smallest set that matches the chapter topic.

3. Extract notes, not prose.
- Capture ideas as short bullets in your own words.
- Focus on models, patterns, chapter flow, example types, pitfalls, and practice design.
- Do not carry full sentences from the source into the rewrite.

4. Rewrite the chapter from scratch or near-scratch.
- Start from the reader problem, not from the source chapter order.
- Prefer paragraph explanation over bullet dumping.
- Add one small example or scenario where it materially improves teachability.
- Add practice steps, expected outcomes, and debugging hints when the chapter needs them.

5. Run a similarity sanity check on yourself.
- If any paragraph feels like a translation of a source paragraph, rewrite it again.
- If the chapter depends too heavily on one source's outline, reorder it into the book's own teaching flow.

## Hard constraints

- Never copy source paragraphs.
- Never preserve source wording just because it is “already well written”.
- Never append a “reference summary” or “source digest” section to compensate for weak prose.
- Never cite page-by-page details inside the chapter body unless the user explicitly asks for source notes.
- Never let one reference book dictate the full chapter structure if the repo's existing chapter sequence suggests a better teaching flow.

## PDF handling

Use `scripts\list-reference-files.ps1` to list available references and `scripts\extract-reference-text.ps1` to extract text from a selected PDF.

If no PDF extraction tool is available, stop and tell the user extraction is blocked. Do not guess what the PDF says from the title alone.

## Output standard

After polishing, the chapter should read like an original textbook chapter that:

- explains why the topic matters
- builds a mental model before API detail
- uses reference materials only as background support
- contains no obvious translated-source smell
- fits the repo's chapter tone and terminology

