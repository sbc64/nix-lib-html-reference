# Required env (set automatically by `nix develop` or the flake's packages.default):
#   LIB_DOCS       - directory of *.md from nixpkgs lib-function-docs derivation
#   HTMX_JS        - path to htmx.min.js
#   THEME_REPO     - root of jez/pandoc-markdown-css-theme
#   BUILTINS_JSON  - path to `nix __dump-builtins` output

SHELL := bash

LIB_CATEGORIES := $(filter-out index,$(notdir $(basename $(wildcard $(LIB_DOCS)/*.md))))
LIB_FRAGMENTS  := $(LIB_CATEGORIES:%=site/fragments/lib-%.html)

PANDOC_FLAGS := -f markdown -t html --toc --toc-depth=2

.PHONY: all site clean fragments builtins assets landing

all: site

site: assets landing fragments

assets: site/assets/htmx.min.js site/assets/theme.css

site/assets/htmx.min.js: $(HTMX_JS)
	@mkdir -p site/assets
	cp $< $@

site/assets/theme.css: $(THEME_REPO)/public/css/theme.css
	@mkdir -p site/assets
	cp $< $@
	cp $(THEME_REPO)/public/css/skylighting-solarized-theme.css site/assets/

landing: site/index.html site/fragments/intro.html

site/index.html: web/index.html
	@mkdir -p site
	cp $< $@

site/fragments/intro.html: web/intro.md
	@mkdir -p site/fragments
	pandoc $(PANDOC_FLAGS) -o $@ $<

fragments: builtins $(LIB_FRAGMENTS)

builtins: site/fragments/builtins.html

doc-gen/fragments/builtins.md: $(BUILTINS_JSON) scripts/gen-builtins.sh
	@mkdir -p doc-gen/fragments
	bash scripts/gen-builtins.sh < $(BUILTINS_JSON) > $@

site/fragments/builtins.html: doc-gen/fragments/builtins.md
	@mkdir -p site/fragments
	pandoc $(PANDOC_FLAGS) -o $@ $<

site/fragments/lib-%.html: $(LIB_DOCS)/%.md
	@mkdir -p site/fragments
	pandoc $(PANDOC_FLAGS) -o $@ $<

clean:
	rm -rf site doc-gen
