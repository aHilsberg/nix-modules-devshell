{
    inputs,
    self,
    lib,
    flake-parts-lib,
    ...
}:
{
    perSystem =
        {
            config,
            pkgs,
            ...
        }:
        let
            # Adapted from the evaluation, fixups and source filtering in:
            # https://github.com/hercules-ci/flake.parts-website/blob/main/render/render-module.nix
            # Compare against upstream revision 71970b431ae9cce1ae96db17d26583327bd2be2b.
            # <- We document this single module, rather than upstream's configurable input catalogue.
            failPkgAttr =
                name: _:
                throw ''
                    pkgs.${name} is not available when generating documentation.
                    Add defaultText or a literalExpression example to the option that forces it.
                '';
            pkgsStub = lib.mapAttrs failPkgAttr pkgs;
            fixups = {
                options.perSystem = flake-parts-lib.mkPerSystemOption (
                    { config, ... }: {
                        _module.args.pkgs = pkgsStub // {
                            _type = "pkgs";
                            inherit lib;

                            appendOverlays = _: config._module.args.pkgs;
                            formats = lib.mapAttrs (
                                formatName: formatFn: formatArgs:
                                let
                                    result = formatFn formatArgs;
                                in
                                lib.mapAttrs (
                                    name: _:
                                    throw ''
                                        pkgs.formats.${formatName}.${name} is not available when generating documentation.
                                        Add defaultText or a literalExpression example to the option that forces it.
                                    ''
                                ) result
                                // {
                                    inherit (result) type;
                                }
                            ) pkgs.formats;
                        };
                    }
                );
            };
            eval = evalWith { modules = [ ]; };
            evalWith =
                {
                    modules,
                    extraInputs ? { },
                }:
                inputs.flake-parts.lib.evalFlakeModule
                    {
                        inputs = {
                            inherit (inputs) nixpkgs;
                            self = eval.config.flake // {
                                outPath = throw ''
                                    The self.outPath attribute is not available when generating documentation.
                                    Use --show-trace to find the option default that needs defaultText.
                                '';
                            };
                        }
                        // extraInputs;
                    }
                    {
                        imports = modules ++ [ fixups ];
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
                options = (evalWith { modules = [ self.flakeModule ]; }).options;
                documentType = "none";
                warningsAreErrors = true;
                transformOptions =
                    opt:
                    if builtins.hasAttr (lib.showOption opt.loc) coreOptionsDoc.optionsNix then
                        opt // { visible = false; }
                    else
                        opt;
            };
            optionsCommonMark = optionsDoc.optionsCommonMark.overrideAttrs {
                extraArgs = [
                    "--anchor-prefix"
                    "opt-"
                    "--anchor-style"
                    "legacy"
                ];
            };
            optionsMarkdown = pkgs.runCommand "nix-modules-devshell-options.md" { } ''
                cat > "$out" <<'EOF'
                ---
                role:
                  - developers
                  - maintainers
                topic:
                  - nix-options
                last-substantial-update: null
                type: reference
                ---

                EOF
                cat ${optionsCommonMark} >> "$out"
            '';
        in
        {
            packages.generated-option-docs-json = optionsDoc.optionsJSON;
            packages.generated-option-docs-md = optionsMarkdown;
            packages.documentation =
                pkgs.runCommand "nix-modules-devshell-documentation"
                    {
                        nativeBuildInputs = [
                            pkgs.mdbook
                            pkgs.mdbook-yml-header
                        ];
                    }
                    ''
                        cp -r ${./docs} docs
                        chmod -R u+w docs
                        mkdir -p docs/options docs/source
                        sed 's|(\./docs/|(|g' ${./README.md} > docs/README.md
                        cat ${optionsMarkdown} > docs/options/Nix_Modules_Devshell.md
                        cp ${./flake-module.nix} docs/source/flake-module.nix
                        cp -r ${./modules} docs/source/
                        mdbook build docs --dest-dir "$out"
                    '';
            packages.docsMdBook = config.packages.documentation;

            devshells.default.commands = [
                {
                    name = "docs";
                    category = "documentation";
                    help = "Serve the documentation with live reload on localhost:8000";
                    command = ''
                        set -euo pipefail

                        mkdir -p docs/options docs/source
                        sed 's|(\./docs/|(|g' README.md > docs/README.md
                        cat ${optionsMarkdown} > docs/options/Nix_Modules_Devshell.md
                        cp flake-module.nix docs/source/flake-module.nix
                        cp -r modules docs/source/
                        export PATH="${lib.makeBinPath [ pkgs.mdbook-yml-header ]}:$PATH"
                        exec ${lib.getExe pkgs.mdbook} serve docs \
                            --hostname 127.0.0.1 --port "''${DOCS_PORT:-8001}" "$@"
                    '';
                }
            ];
        };
}
