.DEFAULT_GOAL := help

TEXLUA ?= texlua
LATEXMK ?= latexmk

INPUT ?= data/example.json
OUTPUT ?= generated/custom.tex
FORMAT ?= fragment
VIEW ?= cards

TEXMFVAR ?= build/texmf-var
TEXMFCACHE ?= build/texmf-cache
export TEXMFVAR
export TEXMFCACHE

JSON_FILES := $(wildcard data/*.json)
JSON_FRAGMENT_TARGETS := $(patsubst data/%.json,generated/fragments/%.tex,$(JSON_FILES))
JSON_DOCUMENT_TARGETS := $(patsubst data/%.json,generated/documents/%.tex,$(JSON_FILES))

.PHONY: help test pdf convert-json json-fragments json-documents clean distclean

help:
	@printf '%s\n' \
	  'SpanishCards build commands' \
	  '' \
	  '  make help' \
	  '      Show this help.' \
	  '' \
	  '  make test' \
	  '      Run the complete test suite.' \
	  '' \
	  '  make pdf' \
	  '      Compile example.tex with LuaLaTeX and update example.pdf.' \
	  '' \
	  '  make convert-json INPUT=... OUTPUT=... FORMAT=fragment VIEW=cards' \
	  '      Convert one JSON file. FORMAT: fragment|document.' \
	  '      VIEW: cards|table (used by document format).' \
	  '' \
	  '  make json-fragments' \
	  '      Convert data/*.json to generated/fragments/*.tex.' \
	  '' \
	  '  make json-documents' \
	  '      Convert data/*.json to generated/documents/*.tex.' \
	  '' \
	  '  make clean' \
	  '      Remove build files, generated TeX, and LaTeX auxiliaries.' \
	  '' \
	  '  make distclean' \
	  '      Run clean and also remove example.pdf.' \
	  '' \
	  'Defaults:' \
	  '  INPUT=data/example.json' \
	  '  OUTPUT=generated/custom.tex' \
	  '  FORMAT=fragment' \
	  '  VIEW=cards'

test:
	@mkdir -p "$(TEXMFVAR)" "$(TEXMFCACHE)"
	./tests/run-tests.sh all

pdf:
	@mkdir -p build/example "$(TEXMFVAR)" "$(TEXMFCACHE)"
	$(LATEXMK) -lualatex -interaction=nonstopmode -halt-on-error \
	  -outdir=build/example example.tex
	cp build/example/example.pdf example.pdf

convert-json:
	$(TEXLUA) scripts/json-to-tex.lua \
	  --input "$(INPUT)" \
	  --output "$(OUTPUT)" \
	  --format "$(FORMAT)" \
	  --view "$(VIEW)"

json-fragments: $(JSON_FRAGMENT_TARGETS)
	@printf 'Generated %s JSON fragment(s).\n' "$(words $(JSON_FRAGMENT_TARGETS))"

json-documents: $(JSON_DOCUMENT_TARGETS)
	@printf 'Generated %s JSON document(s).\n' "$(words $(JSON_DOCUMENT_TARGETS))"

generated/fragments/%.tex: data/%.json scripts/json-to-tex.lua spanishcards-data.lua
	$(TEXLUA) scripts/json-to-tex.lua \
	  --input "$<" \
	  --output "$@" \
	  --format fragment \
	  --view cards

generated/documents/%.tex: data/%.json scripts/json-to-tex.lua spanishcards-data.lua
	$(TEXLUA) scripts/json-to-tex.lua \
	  --input "$<" \
	  --output "$@" \
	  --format document \
	  --view cards

clean:
	rm -rf build generated
	rm -f example.aux example.fdb_latexmk example.fls example.log \
	  example.out example.synctex.gz cache-probe.log

distclean: clean
	rm -f example.pdf
