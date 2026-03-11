---
name: android-book-writer
description: Rewrite, expand, and editorially polish an Android tutorial or book repository in Markdown. Use when Codex needs to turn outline-heavy or bullet-heavy chapters into full teaching prose, add runnable examples and step-by-step practice, align content with modern Android and Kotlin/Jetpack guidance, or run consistency passes across repos organized around SUMMARY.md, book-plan.md, book/, docs/, and prompts/.
---

# Android Book Writer

Use this skill for Android book repositories where chapter structure is defined in `SUMMARY.md` and chapter files live under `book/`.

## Read in this order

1. Read `SUMMARY.md` first and treat it as the source of truth for structure and file paths.
2. Read `book-plan.md` to understand scope, sequencing, and rewrite priorities.
3. Read `docs/style-guide.md`, `docs/chapter-template.md`, and `docs/source-policy.md`.
4. If present, read `docs/full-prose-standard.md`.
5. For deeper guidance, read `references/full-prose-standard.md` when chapters feel outline-heavy and `references/practice-and-code-guidelines.md` when practice sections or examples are weak.
6. Then read only the target chapter and its neighboring chapters unless the task is a whole-book pass.

## Classify the task before editing

- `scaffold`: create missing files and headings from `SUMMARY.md`
- `chapter-draft`: write a new chapter from notes or section goals
- `full-prose-rewrite`: turn a thin, bullet-heavy draft into publication-ready teaching prose
- `consistency-pass`: unify titles, terms, modern-vs-legacy framing, and cross-references
- `structural-refactor`: rename or move files and update navigation

## Full-prose rewrite workflow

1. Diagnose what is missing.
- Headings with only one or two filler sentences
- Bullet lists standing in for explanation
- No problem framing, no mental model, or no implementation path
- Practice tasks that do not say what to do, what to observe, or how to self-check

2. Rewrite for reader action rather than author notes.
- Start from the practical problem the reader is trying to solve
- Explain the model before the API
- Convert most explanatory bullet lists into paragraphs
- Keep lists only when the content is inherently list-shaped
- If the chapter still reads like translated platform documentation, bring in examples, codelab-style teaching flow, migration context, counterexamples, or sample-project structure

3. Make the chapter teachable.
- Add one minimal runnable example when the topic benefits from code
- Explain where the code lives, why it is written that way, and what the reader should observe
- Add a practice task with steps, expected result, and one or two debugging hints
- Distinguish recommended modern practice from legacy or historical material

4. Close the loop.
- End with a prose recap instead of a heading list
- Add a bridge to the next chapter
- Verify title, terminology, links, and neighboring chapter continuity

## Non-negotiable chapter outcomes

Every chapter should let a reader answer:

- What problem this chapter solves
- Why the recommended approach exists
- How to implement a minimal version
- How to verify that it works
- Which mistakes to avoid

If the chapter cannot answer those questions, it is still a note set rather than book prose.

## Android guidance

- Prefer Kotlin, AndroidX, Jetpack, and current recommended practice unless the repo explicitly chooses otherwise.
- Mark outdated APIs as legacy or migration content instead of default solutions.
- When a claim depends on current platform behavior, permissions, or Play policy, verify it before writing it as fact.
- Do not rely on Android Developers API docs alone. When available, combine official docs with official codelabs, official sample apps, Kotlin/JetBrains docs, library primary docs, and other high-quality first-hand material to produce more textbook-like prose.

## Editing rules

- Preserve the meaning of existing code unless it is clearly wrong.
- Do not inflate scope with unrelated side topics.
- Prefer 2 to 4 paragraph subsections over serial bullet dumps.
- Keep examples minimal but executable in principle.
- Update `SUMMARY.md`, `README.md`, and local navigation files if titles or paths change.
- Prefer repo-local writing guides over generic habits when they conflict.
