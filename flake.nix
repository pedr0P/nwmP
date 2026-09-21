{
    description = "NWM - A scrollable tiling window manager";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs =
        {
            self,
            nixpkgs,
            flake-utils,
        }:
        let
            nixosModulesOutput = {
                nixosModules.default =
                    {
                        config,
                        lib,
                        pkgs,
                        ...
                    }:
                    with lib;
                    let
                        cfg = config.services.xserver.windowManager.nwm;
                    in
                    {
                        options.services.xserver.windowManager.nwm = {
                            enable = mkEnableOption "nwm window manager";
                            package = mkOption {
                                type = types.package;
                                default = self.packages.${pkgs.system}.default;
                                description = "nwm package to use";
                            };
                        };

                        config = mkIf cfg.enable {
                            services.xserver.windowManager.session = [
                                {
                                    name = "nwm";
                                    start = ''
                                        ${cfg.package}/bin/nwm &
                                        waitPID=$!
                                    '';
                                }
                            ];
                            environment.systemPackages = [ cfg.package ];
                        };
                    };
            };

            systemOutputs = flake-utils.lib.eachDefaultSystem (
                system:
                let
                    pkgs = import nixpkgs { inherit system; };

                    nwm = pkgs.callPackage ./default.nix { };

                in
                {
                    packages = {
                        default = nwm;
                        nwm = nwm;
                    };

                    devShells.default = pkgs.mkShell {
                        name = "nwm-dev";

                        packages = with pkgs; [
                            pkg-config
                            gcc
                            gnumake
                            git
                            xrandr
                            libX11
                            libxft
                            libxrender
                            libxinerama
                            fontconfig
                            freetype
                            nerd-fonts.iosevka
                            gdb
                            valgrind
                            xorgserver
                            xinit
                            xev
                            xdpyinfo
                            feh
                            st
                            dmenu
                        ];

                        PKG_CONFIG_PATH = pkgs.lib.makeSearchPath "lib/pkgconfig" [
                            pkgs.libx11.dev
                            pkgs.libxrandr.dev
                            pkgs.libxft.dev
                            pkgs.libxrender.dev
                            pkgs.libxinerama.dev
                        ];
                        XINERAMA = "1";
                        FREETYPEINC = "${pkgs.freetype.dev}/include/freetype2";
                        X11INC = "${pkgs.libx11.dev}/include";
                        X11LIB = "${pkgs.libx11}/lib";
                    };

                    devShells.minimal = pkgs.mkShell {
                        packages = with pkgs; [
                            pkg-config
                            libX11
                            libXft
                            libxrender
                            xrandr
                            fontconfig
                            freetype
                            gcc
                            gnumake
                        ];
                    };
                }
            );
        in
        nixosModulesOutput // systemOutputs;
}
