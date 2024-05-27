{
  description = "A nix-flake-based packaging of narsil";

  inputs = {
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = {
    self,
    nixpkgs,
    pre-commit-hooks,
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    enableSdl2 = false;
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    checks = forAllSystems (system: {
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          alejandra.enable = true;
          alejandra.settings = {
            check = true;
          };
          deadnix.enable = true;
          deadnix.settings = {
            noLambdaArg = true;
            noLambdaPatternNames = true;
          };
          shellcheck.enable = true;
          statix.enable = true;
        };
      };
    });

    packages = forAllSystems (system: {
      default = nixpkgs.legacyPackages.${system}.stdenv.mkDerivation rec {
        pname = "narsil";
        version = "1.3.0-76-g14a3b70ab";

        src = nixpkgs.legacyPackages.${system}.fetchFromGitHub {
          owner = "NickMcConnell";
          repo = "NarSil";
          rev = version;
          hash = "sha256-UI6xwI3r2dpJi9unb7RSveeqpHaCSVZiPmIdkm3xKmk=";
        };

        nativeBuildInputs = [nixpkgs.legacyPackages.${system}.autoreconfHook];
        buildInputs =
          [nixpkgs.legacyPackages.${system}.ncurses]
          ++ nixpkgs.legacyPackages.${system}.lib.optionals enableSdl2 [
            nixpkgs.legacyPackages.${system}.SDL2
            nixpkgs.legacyPackages.${system}.SDL2_image
            nixpkgs.legacyPackages.${system}.SDL2_sound
            nixpkgs.legacyPackages.${system}.SDL2_mixer
            nixpkgs.legacyPackages.${system}.SDL2_ttf
          ];

        enableParallelBuilding = true;

        configureFlags = nixpkgs.legacyPackages.${system}.lib.optional enableSdl2 "--enable-sdl2";

        installFlags = ["bindir=$(out)/bin"];

        meta = with nixpkgs.legacyPackages.${system}.lib; {
          homepage = "https://github.com/NickMcConnell/NarSil/";
          description = "Unofficial rewrite of Sil, a roguelike influenced by Angband";
          mainProgram = "narsil";
          longDescription = ''
            NarSil attempts to be an almost-faithful recreation of Sil 1.3.0,
            but based on the codebase of modern Angband.
          '';
          maintainers = [maintainers.nanotwerp];
          license = licenses.gpl2;
        };
      };
    });

    devShells = forAllSystems (system: {
      default = nixpkgs.legacyPackages.${system}.mkShell {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
        buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
        packages = [
          self.packages.${system}.default
        ];
      };
    });
  };
}
