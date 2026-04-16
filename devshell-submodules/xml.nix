{
    lib,
    config,
    customPkgs,
    ...
}: {
    options.xml = {
        enable = lib.mkEnableOption "XML formatting for this shell";
    };

    config = lib.mkIf config.xml.enable (let
        xmlFilePatterns = [
            "*.xml"
            "*.resx"
        ];
    in {
        formatting.treefmt = {
            programs.prettier = {
                enable = true;
                includes = xmlFilePatterns;

                settings = {
                    editorconfig = true;
                    plugins = ["${customPkgs.prettier-plugin-xml}/lib/node_modules/@prettier/plugin-xml/src/plugin.js"];
                    overrides = [
                        {
                            files = xmlFilePatterns;
                            options = {
                                parser = "html";
                                xmlWhitespaceSensitivity = "preserve";
                            };
                        }
                    ];
                };
            };
        };
    });
}
