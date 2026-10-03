{
    self,
    lib,
    ...
}: {
    testing = {
        that,
        should,
        utils,
        pkgs,
        system,
        ...
    }: {
        devshell.stdout = {
            # string
            name,
            # flake module that declares the devshell configuration
            module,
            # non-empty list containing the executable and its arguments
            command,
            # devShells attribute to start
            shellName ? "default",
            # fixed repo content that should be present where the command runs
            repoContent ? {}, # { editorConfig: string, files: { <relative path>: string } }
        }:
            assert lib.assertMsg (builtins.isList command && command != [] && lib.all builtins.isString command)
            "devshell.stdout: command must be a non-empty list of strings"; let
                repoFiles =
                    {"flake.nix" = "{}\n";}
                    // (repoContent.files or {})
                    // lib.optionalAttrs (repoContent ? editorConfig) {
                        ".editorconfig" = repoContent.editorConfig;
                    };
                fixtureRepo = pkgs.runCommand "devshell-repo-fixture-${name}" {
                    preferLocalBuild = true;
                    allowSubstitutes = false;
                } ''
                    mkdir -p "$out"
                    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (path: contents: ''
                        install -Dm644 ${pkgs.writeText "${name}-${baseNameOf path}" contents} "$out"/${lib.escapeShellArg path}
                    '')
                    repoFiles)}
                '';
                evaluatedFlake = utils.evaluate.flake {
                    inputs = {};
                    systems = [system];
                    module = {...}: {
                        imports = [self.flakeModule module];
                        flake.outPath = fixtureRepo;
                        perSystem._module.args.pkgs = pkgs;
                    };
                };
                shell = evaluatedFlake.devShells.${system}.${shellName};
            in
                pkgs.runCommand "devshell-${name}-stdout" {
                    nativeBuildInputs = [pkgs.coreutils];
                    requiredSystemFeatures = ["recursive-nix"];
                    preferLocalBuild = true;
                    allowSubstitutes = false;
                } ''
                    workspace=$(mktemp -d)
                    trap 'rm -rf "$workspace"' EXIT
                    cp -R ${fixtureRepo}/. "$workspace"
                    chmod -R u+w "$workspace"
                    mkdir -p "$workspace/.home"
                    cd "$workspace"
                    ${lib.getExe pkgs.git} init --quiet
                    export HOME="$workspace/.home"
                    export NIX_CONFIG="''${NIX_CONFIG:-}"$'\n'"extra-experimental-features = nix-command recursive-nix"
                    # Keep the recipe available without realizing its entire bootstrap closure.
                    ${lib.getExe pkgs.nix} develop ${builtins.unsafeDiscardOutputDependency shell.drvPath} --command ${lib.escapeShellArgs command} > "$out"
                '';

        asserts = {
            formatingAsExpected = {
                # string
                name,
                # flake module that declares the configuration for the formater
                formatterModule,
                # derivation/path containing the files to be formated
                filetreeToFormat,
                # path passed as `relativeTo` to snapshot assertions
                snapshotPathRelativeTo,
                # fixed repo content that should be present where the formatter runs
                repoContent ? {}, # { editorConfig: string, files: { <relative path>: string } }
            }: let
                # The real module resolves EditorConfig against self.outPath at evaluation time.
                repoFiles =
                    {"flake.nix" = "{}\n";}
                    // (repoContent.files or {})
                    // lib.optionalAttrs (repoContent ? editorConfig) {
                        ".editorconfig" = repoContent.editorConfig;
                    };
                fixtureRepo = pkgs.runCommand "formating-repo-fixture-${name}" {
                    preferLocalBuild = true;
                    allowSubstitutes = false;
                } ''
                    mkdir -p "$out"
                    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (path: contents: ''
                        install -Dm644 ${pkgs.writeText "${name}-${baseNameOf path}" contents} "$out"/${lib.escapeShellArg path}
                    '')
                    repoFiles)}
                '';
                formaterDefiningFlakeOutput = utils.evaluate.flake {
                    inputs = {};
                    systems = [system];
                    module = {...}: {
                        imports = [self.flakeModule formatterModule];
                        flake.outPath = fixtureRepo;
                        perSystem._module.args.pkgs = pkgs;
                    };
                };
                formatter = formaterDefiningFlakeOutput.formatter.${system};

                # create writable workspace, with samples copied in `<workspace>/samples` and thair formated out to
                # `<workspace>/formatted`; returns `<workspace>/formatted` as derivation output
                formatSamples = pass: samples:
                    utils.command.capturePath {
                        inherit pkgs;
                        name = "formatting-${name}-${pass}";
                        path = "formatted";
                        package = pkgs.writeShellApplication {
                            name = "formatting-${name}-${pass}";
                            runtimeInputs = [pkgs.coreutils];
                            text = ''
                                workspace=$(mktemp -d)
                                trap 'rm -rf "$workspace"' EXIT
                                cp -R ${fixtureRepo}/. "$workspace"
                                cp -R ${samples} "$workspace/samples"
                                chmod -R u+w "$workspace"
                                (
                                    cd "$workspace"
                                    export PRJ_ROOT="$workspace"
                                    ${lib.getExe formatter} --no-cache samples
                                )
                                cp -R "$workspace/samples" formatted
                            '';
                        };
                    };
                firstPass = formatSamples "first-pass" filetreeToFormat;
                secondPass = formatSamples "second-pass" firstPass;
            in [
                (that firstPass (should.matchSnapshot {
                    snapshotPath = {
                        path = "snapshots/formatting/${name}";
                        relativeTo = snapshotPathRelativeTo;
                    };
                    reason = "The consumer's real formatter must produce the reviewed sample bytes in one pass.";
                }))
                (that secondPass (should.haveSameContents {
                    expected = firstPass;
                    name = "Formatting is idempotent";
                    reason = "Running the same consumer formatter again must not change any sample bytes.";
                }))
            ];
        };
    };
}
