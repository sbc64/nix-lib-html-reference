# nix-lib-html-reference

HTML reference for Nixpkgs `lib.*` functions and Nix language `builtins`,
generated from upstream `nixdoc` output, rendered with `pandoc`, and
served as an [htmx](https://htmx.org/)-driven fragment site.

Hosted on GitHub Pages: <https://sbc64.github.io/nix-lib-html-reference/>

## Build

```bash
nix build .#default                   # → result/ contains the site
python3 -m http.server -d result 8000
xdg-open http://localhost:8000
```

All inputs (`lib` docs, builtins JSON, htmx, theme) are pinned by the
flake; nothing else needs to be installed.

## Dev shell

```bash
nix develop
make site
python3 -m http.server -d site 8000
```

The dev shell exports `LIB_DOCS`, `HTMX_JS`, `THEME_REPO`, and
`BUILTINS_JSON` so `make` can find its inputs directly out of the
Nix store.

## CI / Pages

`.github/workflows/pages.yml` runs `nix build .#default` on every push to
`main` and publishes the result via `actions/deploy-pages`.

One-time manual setup: GitHub repo → Settings → Pages → Source: GitHub Actions.
