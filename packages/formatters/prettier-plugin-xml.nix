{lib, ...}: {
    perSystem = {pkgs, ...}: {
        packages.prettier-plugin-xml = pkgs.stdenv.mkDerivation rec {
            pname = "prettier-plugin-xml";
            version = "3.4.1";

            src = pkgs.fetchFromGitHub {
                owner = "prettier";
                repo = "plugin-xml";
                rev = "v${version}";
                hash = "sha256-7/0a00fdDso8yZyFkrBUwA2uxlN/pifSrKHGDjJS5Y0=";
            };

            yarnOfflineCache = pkgs.fetchYarnDeps {
                yarnLock = src + "/yarn.lock";
                hash = "sha256-VRUnlE8AQQJfPTMdexPZ/5jPFtU/qSV5GFM0pSLH9zI=";
            };

            nativeBuildInputs = [
                pkgs.nodejs_20
                pkgs.yarnConfigHook
            ];

            buildPhase = ''
                runHook preBuild
                # Generate src/languages.js
                node bin/languages.js
                runHook postBuild
            '';

            installPhase = ''
                runHook preInstall

                pkgDir="$out/lib/node_modules/@prettier/plugin-xml"
                mkdir -p "$(dirname "$pkgDir")"

                cp -R . "$pkgDir"

                runHook postInstall
            '';

            meta = with lib; {
                description = "Prettier plugin for XML (library, not a standalone CLI tool)";
                homepage = "https://github.com/prettier/plugin-xml";
                changelog = "https://github.com/prettier/plugin-xml/releases/tag/v${version}";
                license = licenses.mit;
                platforms = platforms.all;
                maintainers = [];
                # No mainProgram - this is a Prettier plugin library, not a CLI tool
            };
        };
    };
}
