#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build/tests"
TARGET="${1:-all}"

mkdir -p "$BUILD"
cd "$ROOT"
export TEXMFCACHE="build/texmf-cache"
export TEXMFVAR="build/texmf-var"
mkdir -p "$TEXMFCACHE" "$TEXMFVAR"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

compile_test() {
  local name="$1"
  local tex_file="$ROOT/tests/test-$name.tex"
  local stdout_file="$BUILD/$name.stdout"

  rm -f "$BUILD/test-$name."{aux,log,pdf,txt}
  if ! lualatex \
    -interaction=nonstopmode \
    -halt-on-error \
    -output-directory="$BUILD" \
    "$tex_file" >"$stdout_file" 2>&1; then
    cat "$stdout_file" >&2
    fail "$name did not compile"
  fi

  if rg -n 'LaTeX Error|Undefined control sequence|Overfull \\[hv]box|Missing character' \
    "$BUILD/test-$name.log"; then
    fail "$name contains LaTeX errors or overfull boxes"
  fi

  pdftotext "$BUILD/test-$name.pdf" "$BUILD/test-$name.txt"
}

compile_generated() {
  local name="$1"
  local tex_file="$2"
  local stdout_file="$BUILD/$name.stdout"

  rm -f "$BUILD/$name."{aux,log,pdf,txt}
  if ! lualatex \
    -jobname="$name" \
    -interaction=nonstopmode \
    -halt-on-error \
    -output-directory="$BUILD" \
    "$tex_file" >"$stdout_file" 2>&1; then
    cat "$stdout_file" >&2
    fail "$name did not compile"
  fi

  if rg -n 'LaTeX Error|Undefined control sequence|Overfull \\[hv]box|Missing character' \
    "$BUILD/$name.log"; then
    fail "$name contains LaTeX errors or overfull boxes"
  fi

  pdftotext "$BUILD/$name.pdf" "$BUILD/$name.txt"
}

assert_contains() {
  local file="$1"
  local expected="$2"
  rg -F -q -- "$expected" "$file" || fail "expected '$expected' in $file"
}

assert_not_contains() {
  local file="$1"
  local unexpected="$2"
  if rg -F -q -- "$unexpected" "$file"; then
    fail "did not expect '$unexpected' in $file"
  fi
}

assert_pages() {
  local file="$1"
  local expected="$2"
  local actual
  actual="$(pdfinfo "$file" | awk '/^Pages:/ {print $2}')"
  [[ "$actual" == "$expected" ]] || \
    fail "expected $expected pages in $file, got $actual"
}

test_manual() {
  compile_test manual
  local text="$BUILD/test-manual.txt"
  local pdf="$BUILD/test-manual.pdf"

  assert_contains "$text" 'la estación'
  assert_contains "$text" 'station'
  assert_contains "$text" '车站'
  assert_contains "$text" 'sustantivo'
  assert_contains "$text" 'f.'
  assert_contains "$text" '/la es.taˈsjon/'
  assert_contains "$text" 'La estación está cerca.'
  assert_contains "$text" 'The station is nearby.'
  assert_contains "$text" '车站就在附近。'
  assert_pages "$pdf" 1
}

test_quiz() {
  compile_test quiz
  local text="$BUILD/test-quiz.txt"
  local pdf="$BUILD/test-quiz.pdf"

  assert_contains "$text" 'recordar'
  assert_contains "$text" 'visibleChinese'
  assert_contains "$text" 'visibleEnglish'
  assert_contains "$text" 'visibleCustomChinese'
  assert_not_contains "$text" 'recallEnglish'
  assert_not_contains "$text" '回忆中文答案'
  assert_not_contains "$text" 'recallExampleEnglish'
  assert_not_contains "$text" '回忆例句答案'
  assert_not_contains "$text" 'quizEnglishHidden'
  assert_not_contains "$text" '英语例句隐藏'
  assert_not_contains "$text" '中文测验隐藏'
  assert_not_contains "$text" 'chineseExampleHidden'
  assert_not_contains "$text" 'exampleEnglishHidden'
  assert_not_contains "$text" '例句中文隐藏'
  assert_not_contains "$text" 'customEnglishHidden'
  assert_not_contains "$text" '自定义例句隐藏'
  assert_pages "$pdf" 5
}

test_csv() {
  compile_test csv
  local text="$BUILD/test-csv.txt"
  local pdf="$BUILD/test-csv.pdf"

  assert_contains "$text" 'el billete'
  assert_contains "$text" 'ticket'
  assert_contains "$text" '票'
  assert_contains "$text" 'Compré un billete, ida y vuelta.'
  assert_contains "$text" 'round-trip'
  assert_contains "$text" 'la maleta'
  assert_contains "$text" 'suitcase'
  assert_contains "$text" '行李箱'
  assert_contains "$text" 'Mi maleta'
  assert_contains "$text" 'es azul.'
  assert_contains "$text" '50% & práctico'
  assert_pages "$pdf" 2
}

test_json() {
  compile_test json
  local text="$BUILD/test-json.txt"
  local pdf="$BUILD/test-json.pdf"

  assert_contains "$text" 'el corazón'
  assert_contains "$text" 'heart'
  assert_contains "$text" '心脏'
  assert_contains "$text" 'The heart beats.'
  assert_contains "$text" 'Every day.'
  assert_contains "$text" '2'
  assert_contains "$text" 'true'
  assert_contains "$text" 'mañana'
  assert_contains "$text" 'tomorrow'
  assert_contains "$text" '明天'
  assert_contains "$text" 'Nos vemos mañana.'
  assert_pages "$pdf" 2
}

test_table() {
  compile_test table
  local text="$BUILD/test-table.txt"
  local pdf="$BUILD/test-table.pdf"

  assert_contains "$text" 'VOCABULARY OVERVIEW'
  assert_contains "$text" 'la casa'
  assert_contains "$text" 'house'
  assert_contains "$text" '房子'
  assert_contains "$text" 'comer'
  assert_contains "$text" 'to eat'
  assert_contains "$text" '吃'
  [[ "$(rg -F -c 'la casa' "$text")" -ge 2 ]] || \
    fail "expected la casa in both cards and table"
  assert_pages "$pdf" 3
}

test_style() {
  compile_test style
  local text="$BUILD/test-style.txt"
  local pdf="$BUILD/test-style.pdf"

  assert_contains "$text" 'pronunciar'
  assert_contains "$text" 'to pronounce'
  assert_contains "$text" '发音'
  assert_contains "$text" '/pɾonunˈsjaɾ/'
  assert_pages "$pdf" 1
}

test_converter() {
  local converter_build="$BUILD/converter"
  local fragment="$converter_build/fragment.tex"
  local fragment_copy="$converter_build/fragment-copy.tex"
  local cards_document="$converter_build/cards-document.tex"
  local table_document="$converter_build/table-document.tex"

  rm -rf "$converter_build"
  mkdir -p "$converter_build"

  texlua scripts/json-to-tex.lua --help >"$converter_build/converter-help.txt"
  assert_contains "$converter_build/converter-help.txt" '--format FORMAT'
  assert_contains "$converter_build/converter-help.txt" '--view VIEW'

  if texlua scripts/json-to-tex.lua \
      --input tests/fixtures/complex.json \
      --output "$converter_build/invalid.tex" \
      --format invalid >"$converter_build/invalid.stdout" 2>&1; then
    fail 'invalid converter format unexpectedly succeeded'
  fi
  assert_contains "$converter_build/invalid.stdout" \
    "--format must be 'fragment' or 'document'"

  texlua scripts/json-to-tex.lua \
    --input tests/fixtures/complex.json \
    --output "$fragment" \
    --format fragment \
    --view cards

  assert_contains "$fragment" 'Generated by SpanishCards. Do not edit manually.'
  assert_contains "$fragment" '\AddSpanishWord{'
  assert_contains "$fragment" 'spanish={el corazón}'
  assert_not_contains "$fragment" '\documentclass'

  texlua scripts/json-to-tex.lua \
    --input tests/fixtures/complex.json \
    --output "$fragment_copy" \
    --format fragment
  [[ "$(sha256sum "$fragment" | awk '{print $1}')" == \
     "$(sha256sum "$fragment_copy" | awk '{print $1}')" ]] || \
    fail 'fragment conversion is not deterministic'

  compile_test generated-fragment
  assert_contains "$BUILD/test-generated-fragment.txt" 'el corazón'
  assert_contains "$BUILD/test-generated-fragment.txt" 'mañana'
  assert_pages "$BUILD/test-generated-fragment.pdf" 2

  texlua scripts/json-to-tex.lua \
    --input tests/fixtures/complex.json \
    --output "$cards_document" \
    --format document \
    --view cards
  assert_contains "$cards_document" '\documentclass{spanishcards}'
  assert_contains "$cards_document" '\PrintVocabularyCards'
  compile_generated generated-cards "$cards_document"
  assert_pages "$BUILD/generated-cards.pdf" 2

  texlua scripts/json-to-tex.lua \
    --input tests/fixtures/complex.json \
    --output "$table_document" \
    --format document \
    --view table
  assert_contains "$table_document" '\PrintVocabularyTable'
  compile_generated generated-table "$table_document"
  assert_contains "$BUILD/generated-table.txt" 'VOCABULARY OVERVIEW'
  assert_pages "$BUILD/generated-table.pdf" 1

  make help >"$converter_build/make-help.txt"
  assert_contains "$converter_build/make-help.txt" 'convert-json'
  assert_contains "$converter_build/make-help.txt" 'json-fragments'
  assert_contains "$converter_build/make-help.txt" 'json-documents'

  make convert-json \
    INPUT=tests/fixtures/complex.json \
    OUTPUT="$converter_build/make-fragment.tex" \
    FORMAT=fragment \
    VIEW=cards
  assert_contains "$converter_build/make-fragment.tex" '\AddSpanishWord{'

  rm -rf generated
  make json-fragments json-documents
  assert_contains generated/fragments/example.tex '\AddSpanishWord{'
  assert_not_contains generated/fragments/example.tex '\documentclass'
  assert_contains generated/documents/example.tex '\documentclass{spanishcards}'
  assert_contains generated/documents/example.tex '\PrintVocabularyCards'

  assert_contains README.md '## JSON 预生成 TeX'
  assert_contains README.md 'make json-fragments'
  assert_contains README.md 'FORMAT=fragment'
  assert_contains README.md 'scripts/json-to-tex.lua'
  assert_contains README.md '## 项目结构'
}

case "$TARGET" in
  manual)
    test_manual
    ;;
  quiz)
    test_quiz
    ;;
  csv)
    test_csv
    ;;
  json)
    test_json
    ;;
  table)
    test_table
    ;;
  style)
    test_style
    ;;
  converter)
    test_converter
    ;;
  all)
    test_manual
    test_quiz
    test_csv
    test_json
    test_table
    test_style
    test_converter
    ;;
  *)
    fail "unknown test target: $TARGET"
    ;;
esac

printf 'PASS: %s\n' "$TARGET"
