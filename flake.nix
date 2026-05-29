{
  description = "Nixpkgs lib + builtins HTML reference (htmx, GitHub Pages)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAll = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs { inherit system; };

      htmxJs = system: (pkgsFor system).fetchurl {
        url = "https://github.com/bigskysoftware/htmx/releases/download/v2.0.9/htmx.min.js";
        hash = "sha256-V9kZFRUzmSK9E1bXstgLHuOynxs6LGWgeLuLLo/Zrl8=";
      };

      pandocTheme = system: (pkgsFor system).fetchFromGitHub {
        owner = "jez";
        repo = "pandoc-markdown-css-theme";
        rev = "a8046cc48ed68d219206d98ebb5604cc09104096";
        hash = "sha256-LmTlEl30bP44T+P1a/5Q1VoizwnawW8Wkvhkx8zIkWI=";
      };

      libDocs = system:
        let pkgs = pkgsFor system; in
        pkgs.callPackage (pkgs.path + "/doc/doc-support/lib-function-docs.nix") {
          nixpkgs = { rev = nixpkgs.rev or "nixos-26.05"; };
        };

      builtinsJson = system:
        let pkgs = pkgsFor system; in
        pkgs.runCommand "nix-builtins.json" { nativeBuildInputs = [ pkgs.nix ]; } ''
          export HOME=$TMPDIR
          nix __dump-language > $out
        '';
    in {
      packages = forAll (system:
        let
          pkgs = pkgsFor system;
        in {
          lib-docs = libDocs system;
          builtins-json = builtinsJson system;

          default = pkgs.stdenv.mkDerivation {
            pname = "nix-lib-html-reference";
            version = self.shortRev or "dirty";
            src = ./.;

            nativeBuildInputs = [ pkgs.pandoc pkgs.jq pkgs.gnumake ];

            LIB_DOCS = libDocs system;
            HTMX_JS = htmxJs system;
            THEME_REPO = pandocTheme system;
            BUILTINS_JSON = builtinsJson system;

            buildPhase = ''
              runHook preBuild
              make site
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p $out
              cp -r site/. $out/
              runHook postInstall
            '';
          };
        });

      devShells = forAll (system:
        let pkgs = pkgsFor system; in {
          default = pkgs.mkShell {
            packages = [
              pkgs.pandoc
              pkgs.nixdoc
              pkgs.jq
              pkgs.gnumake
              pkgs.python3
            ];
            shellHook = ''
              export LIB_DOCS=${libDocs system}
              export HTMX_JS=${htmxJs system}
              export THEME_REPO=${pandocTheme system}
              export BUILTINS_JSON=${builtinsJson system}
              echo "nix-lib-html-reference dev shell"
              echo "  LIB_DOCS=$LIB_DOCS"
              echo "  HTMX_JS=$HTMX_JS"
              echo "  THEME_REPO=$THEME_REPO"
              echo "  BUILTINS_JSON=$BUILTINS_JSON"
            '';
          };
        });
    };
}
