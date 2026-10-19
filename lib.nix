{
    inputs,
    lib,
    self,
    ...
}:
let
    # type: showPath :: [string] -> string
    showPath = path: if path == [ ] then "<project root>" else lib.concatStringsSep "." path;

    # Values that should be treated as opaque leaves rather than namespaces.
    #
    # In particular:
    # - Nix option types
    # - callable attribute sets
    # - derivations
    # - string-coercible sets (see https://nix.dev/manual/nix/2.34/language/builtins.html:
    #      defined as a set containing { __toString = self: ...; } or { outPath = ...; })
    isNamespace =
        value:
        builtins.isAttrs value
        && !lib.isDerivation value
        && !(value ? __functor)
        && !(value ? __toString)
        && !(value ? outPath)
        && (value._type or null) != "option-type";

    # Strict recursive merge:
    #
    # - namespace attribute sets may be contributed by multiple files;
    # - individual leaf exports must have exactly one definition;
    # - collisions fail rather than depending on import order.
    #
    # Types:
    # ```
    # mergeDefinitions :: [string] -> [{ file: path, value: a }] -> a
    # ```
    mergeDefinitions =
        path: definitions:
        if builtins.length definitions == 1 then
            (builtins.head definitions).value

        # for attr sets whose are specified under the same key, combine them
        else if lib.all (definition: isNamespace definition.value) definitions then
            definitions
            |> lib.concatMap (definition: builtins.attrNames definition.value)
            |> lib.unique
            |> builtins.sort builtins.lessThan
            |> map (name: {
                inherit name;

                value =
                    definitions
                    |> lib.concatMap (
                        definition:
                        lib.optional (builtins.hasAttr name definition.value) {
                            inherit (definition) file;
                            value = definition.value.${name};
                        }
                    )
                    |> mergeDefinitions (path ++ [ name ]);
            })
            |> builtins.listToAttrs
        else
            throw ''
                Duplicate library export `${showPath path}`.

                Defined by:
                ${lib.concatMapStringsSep "\n" (definition: "  - ${toString definition.file}") definitions}
            '';

    libFiles = inputs.import-tree (i: i.withLib lib) (
        i: i.filter (path: lib.hasSuffix ".lib.nix" path)
    ) (i: i.leaves ./.);

    buildProjectLib =
        projectLib:
        mergeDefinitions [ ] (
            [
                {
                    file = ./lib.nix;
                    value = {
                        mkPkgs =
                            system:
                            let
                                overlayNames = lib.sort lib.lessThan (builtins.attrNames self.overlays);
                                overlays = map (name: self.overlays.${name}) overlayNames;
                            in
                            import inputs.nixpkgs {
                                inherit system overlays;
                                config.allowUnfree = true;
                            };
                        mkDevShellDefault = lib.mkOverride 60;
                        types.strOrPackage = lib.types.either lib.types.str lib.types.package;
                    };
                }
            ]
            ++ map (
                file:
                let
                    fragment = import file;
                in
                assert lib.assertMsg (builtins.isFunction fragment)
                    "Library fragment `${toString file}` must return a function.";
                {
                    inherit file;
                    value = fragment {
                        inherit
                            inputs
                            lib
                            self
                            projectLib
                            ;
                    };
                }
            ) libFiles
        );
in
lib.fix buildProjectLib
