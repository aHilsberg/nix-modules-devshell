{inputs, self, ...}: {
    imports = [
        (inputs.flake-parts-website + "/render/render-module.nix")
    ];

    perSystem = {config, pkgs, ...}: {
        render = {
            officialFlakeInputs = {};
            inputs = {
                flake-parts = {
                    flake = inputs.flake-parts;
                    getModules = _: [];
                    baseUrl = "https://github.com/hercules-ci/flake-parts/blob/main";
                    intro = "Core flake-parts options.";
                    menu.enable = false;
                };
                nix-modules-devshell = {
                    flake = self;
                    baseUrl = "../source";
                    installation = ''
                        ## Usage

                        Import `inputs.nix-modules-devshell.flakeModule` in your flake-parts configuration
                        and add the `inputs.devshell.overlays.default` overlay to pkgs.
                        See the [getting started guide](../getting-started.md) for examples.
                    '';
                    intro = "Private option reference for nix-modules-devshell.";
                };
            };
        };

        packages.docsMdBook = pkgs.runCommand "nix-modules-devshell-documentation" {
            nativeBuildInputs = [pkgs.mdbook];
        } ''
            mkdir -p src/options src/source
            cp -r ${./docs}/. src/
            sed 's|(\./docs/|(|g' ${./README.md} > src/README.md
            cp ${config.render.inputs.nix-modules-devshell.rendered.file} src/options/nix-modules-devshell.md
            cp ${./flake-module.nix} src/source/flake-module.nix
            cp -r ${./modules} ${./devshell-submodules} src/source/
            cat > book.toml <<'EOF'
            [book]
            title = "nix-modules-devshell"
            language = "en"
            src = "src"
            [output.html]
            site-url = "/"
            EOF
            cat > src/SUMMARY.md <<'EOF'
            # Summary

            - [Overview](README.md)
            - [Installation](installation.md)
            - [Getting started](getting-started.md)
            - [Developer guide](developer-guide.md)
            - [Formatting](formatting.md)
            - [Option reference](options/nix-modules-devshell.md)
            EOF
            mdbook build --dest-dir "$out"
        '';

        apps.documentation = {
            type = "app";
            meta.description = "Preview private documentation on localhost:8000";
            program = "${pkgs.writeShellScript "preview-documentation" ''
                echo "Documentation: http://127.0.0.1:8000"
                exec ${pkgs.python3}/bin/python3 -m http.server 8000 \
                    --bind 127.0.0.1 --directory ${config.packages.docsMdBook}
            ''}";
        };
    };
}
