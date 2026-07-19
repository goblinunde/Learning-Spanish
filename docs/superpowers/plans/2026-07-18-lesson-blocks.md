# SpanishCards Lesson Blocks Implementation Plan

## File Responsibilities

- `/home/yyt/Documents/xiyu/spanishcards.sty`: define lesson title keys, block rendering helpers, public lesson environments, and example line command.
- `/home/yyt/Documents/xiyu/tests/test-lesson.tex`: compile fixture covering title, all lesson block types, examples, and vocabulary card interleaving.
- `/home/yyt/Documents/xiyu/tests/run-tests.sh`: add `lesson` target and assertions.
- `/home/yyt/Documents/xiyu/example.tex`: demonstrate lesson content before vocabulary output.
- `/home/yyt/Documents/xiyu/README.md`: document the lesson-block input model and add it to the table of contents.

## Task 1: Add Failing Lesson Test

1. Create `/home/yyt/Documents/xiyu/tests/test-lesson.tex`.
2. Use `\SpanishLessonTitle`, all block environments, `\SpanishExampleLine`, one `\AddSpanishWord`, and `\PrintVocabularyCards`.
3. Add `test_lesson` to `/home/yyt/Documents/xiyu/tests/run-tests.sh`.
4. Add `lesson)` and include `test_lesson` in `all)`.
5. Run `./tests/run-tests.sh lesson`.
6. Expected result: compilation fails because lesson commands are undefined.

## Task 2: Implement Minimal Lesson API

1. Modify `/home/yyt/Documents/xiyu/spanishcards.sty`.
2. Add token lists for lesson title fields.
3. Add keys under `spanishcards / lesson-title`.
4. Add an internal reusable lesson block environment using `tcolorbox`.
5. Define:
   - `\SpanishLessonTitle`
   - `SpanishTheoryBlock`
   - `SpanishTipBlock`
   - `SpanishNoteBlock`
   - `SpanishExampleBlock`
   - `SpanishPracticeBlock`
   - `\SpanishExampleLine`
6. Run `./tests/run-tests.sh lesson`.
7. Expected result: lesson test passes.

## Task 3: Update Example Document

1. Modify `/home/yyt/Documents/xiyu/example.tex`.
2. Insert a short lesson title, theory block, tip block, example block, and practice block before vocabulary data.
3. Run `make pdf`.
4. Expected result: `example.pdf` compiles without LaTeX errors, undefined control sequences, overfull boxes, or missing characters.

## Task 4: Update README

1. Modify `/home/yyt/Documents/xiyu/README.md`.
2. Add table-of-contents entry for `正文课程板块`.
3. Document the new commands and environments near `卡片与表格输出`.
4. Explain that long prose should be split into multiple blocks because the default page size is 160 mm x 100 mm.
5. Run README scans:
   - `rg -n "正文课程板块|SpanishTheoryBlock|SpanishExampleLine" README.md`
   - `git diff --check`

## Task 5: Full Verification

1. Run `./tests/run-tests.sh all`.
2. Run `git diff --check`.
3. Inspect `git status --short`.
4. Report changed files and verification results.
