# SpanishCards Lesson Blocks Design

## Goal

SpanishCards should support lesson-style explanatory pages in addition to vocabulary cards and overview tables. A learner should be able to write introductory Spanish content, grammar notes, examples, tips, and exercises directly in LaTeX, then place vocabulary cards before or after those sections.

## User-facing Outcome

The document author can write:

```latex
\SpanishLessonTitle{
  title = {西班牙语入门},
  subtitle = {字母、发音与基本问候},
  goal = {认识常见西语字符和基础问候句}
}

\begin{SpanishTheoryBlock}{西班牙语是什么}
西班牙语属于罗曼语族，使用拉丁字母。
\end{SpanishTheoryBlock}

\begin{SpanishExampleBlock}{基础问候}
\SpanishExampleLine{Hola.}{Hello.}{你好。}
\SpanishExampleLine{Buenos días.}{Good morning.}{早上好。}
\end{SpanishExampleBlock}

\begin{SpanishPracticeBlock}{小练习}
请写出 Hola、gracias、adiós 的中文意思。
\end{SpanishPracticeBlock}

\PrintVocabularyCards
```

## Scope

- Add lesson title page command.
- Add reusable full-width lesson block environments for theory, tip, example, practice, and note content.
- Add a three-language example line command usable inside and outside lesson blocks.
- Keep existing vocabulary card, table, CSV, JSON, and quiz behavior unchanged.
- Keep the default `spanishcards` class as a 160 mm x 100 mm screen-first layout.
- Update example and README to teach the new input pattern.

## Non-goals

- No separate A4 textbook class in this iteration.
- No external JSON/CSV schema for lesson content in this iteration.
- No automatic lesson generation.
- No changes to vocabulary entry fields.

## Interface

- `\SpanishLessonTitle{title=..., subtitle=..., goal=...}`
- `\begin{SpanishTheoryBlock}{标题} ... \end{SpanishTheoryBlock}`
- `\begin{SpanishTipBlock}{标题} ... \end{SpanishTipBlock}`
- `\begin{SpanishNoteBlock}{标题} ... \end{SpanishNoteBlock}`
- `\begin{SpanishExampleBlock}{标题} ... \end{SpanishExampleBlock}`
- `\begin{SpanishPracticeBlock}{标题} ... \end{SpanishPracticeBlock}`
- `\SpanishExampleLine{西语}{English}{中文}`

## Layout

- Lesson title page uses the current theme accent colors, a prominent title, subtitle, optional goal panel, and a small label.
- Lesson blocks use `tcolorbox` with restrained styling matching existing cards.
- Blocks are not fixed to full page height; multiple short blocks can appear on one page.
- Blocks should compile without overfull boxes for normal A1-level lesson text.
- Existing `\PrintVocabularyCards` still renders one word per page and can follow lesson blocks.

## Verification

- Add a `tests/test-lesson.tex` document using all new commands.
- Extend `tests/run-tests.sh` with `lesson` target.
- Verify compiled PDF text contains title, theory body, example rows, practice prompt, and later vocabulary card text.
- Verify page count is at least two pages, proving lesson pages and vocabulary card output coexist.
- Run the full test suite.

## Self-review

- Ambiguity: block names use English LaTeX command names for consistency with existing API.
- Compatibility: no existing public command names are reused.
- Risk: fixed 160 mm x 100 mm pages can still overflow if users write very long paragraphs. README will recommend short paragraphs or separate blocks.
- Gap accepted for this iteration: lesson content is manual LaTeX only, not CSV/JSON-driven.
