# Required env (set automatically by `nix develop` or the flake's packages.default):
#   LIB_DOCS       - directory of *.md from nixpkgs lib-function-docs derivation
#   HTMX_JS        - path to htmx.min.js
#   THEME_REPO     - root of jez/pandoc-markdown-css-theme  (only skylighting css used)
#   BUILTINS_JSON  - path to JSON dump produced by `nix __dump-language`

SHELL := bash

LIB_CATEGORIES := $(filter-out index,$(notdir $(basename $(wildcard $(LIB_DOCS)/*.md))))
LIB_FRAGMENTS  := $(LIB_CATEGORIES:%=site/fragments/lib-%.html)

PANDOC_FLAGS := -f markdown -t html --toc --toc-depth=2

.PHONY: all site clean fragments builtins assets landing

all: site

site: assets fragments landing

assets: site/assets/htmx.min.js site/assets/skylighting-solarized-theme.css

site/assets/htmx.min.js: $(HTMX_JS)
	@mkdir -p site/assets
	cp $< $@

site/assets/skylighting-solarized-theme.css: $(THEME_REPO)/public/css/skylighting-solarized-theme.css
	@mkdir -p site/assets
	cp $< $@

# Landing depends on fragments since the sidebar nav is generated from them.
landing: site/index.html site/fragments/intro.html

site/index.html: web/index.html site/nav.html
	@mkdir -p site
	awk '/<!-- NAV -->/{system("cat site/nav.html"); next} {print}' web/index.html > $@

site/nav.html: $(LIB_FRAGMENTS) site/fragments/builtins.html scripts/gen-nav.sh
	bash scripts/gen-nav.sh site/fragments > $@

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
