{
    inputs,
    self,
    lib,
    flake-parts-lib,
    ...
}: {
    perSystem = {
        config,
        pkgs,
        ...
    }: let
        # Adapted from the evaluation, fixups and source filtering in:
        # https://github.com/hercules-ci/flake.parts-website/blob/main/render/render-module.nix
        # Compare against upstream revision 71970b431ae9cce1ae96db17d26583327bd2be2b.
        # <- We document this single module, rather than upstream's configurable input catalogue.
        failPkgAttr = name: _:
            throw ''
                pkgs.${name} is not available when generating documentation.
                Add defaultText or a literalExpression example to the option that forces it.
            '';
        pkgsStub = lib.mapAttrs failPkgAttr pkgs;
        fixups = {
            options.perSystem = flake-parts-lib.mkPerSystemOption ({config, ...}: {
                _module.args.pkgs =
                    pkgsStub
                    // {
                        _type = "pkgs";
                        inherit lib;

                        appendOverlays = _: config._module.args.pkgs;
                        formats = lib.mapAttrs (formatName: formatFn: formatArgs: let
                            result = formatFn formatArgs;
                        in
                            lib.mapAttrs (name: _:
                                throw ''
                                    pkgs.formats.${formatName}.${name} is not available when generating documentation.
                                    Add defaultText or a literalExpression example to the option that forces it.
                                '')
                            result
                            // {inherit (result) type;})
                        pkgs.formats;
                    };
            });
        };
        eval = evalWith {modules = [];};
        evalWith = {
            modules,
            extraInputs ? {},
        }:
            inputs.flake-parts.lib.evalFlakeModule {
                inputs =
                    {
                        inherit (inputs) nixpkgs;
                        self =
                            eval.config.flake
                            // {
                                outPath = throw ''
                                    The self.outPath attribute is not available when generating documentation.
                                    Use --show-trace to find the option default that needs defaultText.
                                '';
                            };
                    }
                    // extraInputs;
            } {
                imports = modules ++ [fixups];
                systems = [
                    (throw ''
                        The systems option value is not available when generating documentation.
                        Use --show-trace to find the option default that needs defaultText.
                    '')
                ];
            };
        # baseline option set; to exclude flake-parts options or other builtin options
        coreOptionsDoc = pkgs.nixosOptionsDoc {
            options = eval.options;
        };
        optionsDoc = pkgs.nixosOptionsDoc {
            options = (evalWith {modules = [self.flakeModule];}).options;
            documentType = "none";
            warningsAreErrors = true;
            transformOptions = opt: let
                sourcePath = toString self.outPath;
                declarations =
                    opt.declarations
                    |> lib.concatMap (decl:
                        lib.optional (lib.hasPrefix sourcePath (toString decl)) {
                            url = "../source" + lib.removePrefix sourcePath (toString decl);
                            name = "nix-modules-devshell" + lib.removePrefix sourcePath (toString decl);
                        });
            in
                if declarations == [] || builtins.hasAttr (lib.showOption opt.loc) coreOptionsDoc.optionsNix
                then opt // {visible = false;}
                else opt // {inherit declarations;};
        };
        optionsCommonMark = optionsDoc.optionsCommonMark.overrideAttrs {
            extraArgs = ["--anchor-prefix" "opt-" "--anchor-style" "legacy"];
        };
    in {
        packages.generated-docs-json = optionsDoc.optionsJSON;
        packages.generated-docs-md = optionsCommonMark;
        packages.docsMdBook = pkgs.runCommand "nix-modules-devshell-documentation" {
            nativeBuildInputs = [pkgs.mdbook];
        } ''
            mkdir -p src/options src/source
            cp -r ${./docs}/. src/
            sed 's|(\./docs/|(|g' ${./README.md} > src/README.md
            cat ${optionsCommonMark} >> src/options/nix-modules-devshell.md
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
