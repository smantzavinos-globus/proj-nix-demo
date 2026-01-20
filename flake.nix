{
  description = "Nix demo umbrella - local development builds against uncommitted corelib";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      repoRoot = builtins.getEnv "PWD";

      corelibSrc = builtins.toPath "${repoRoot}/corelib";
      viewerSrc = builtins.toPath "${repoRoot}/viewer";
      editorSrc = builtins.toPath "${repoRoot}/editor";

      corelibDefaultNix = builtins.toPath "${repoRoot}/corelib/default.nix";

      corelib =
        if builtins.pathExists corelibDefaultNix then
          import "${corelibSrc}/default.nix" { inherit pkgs; src = corelibSrc; }
        else
          abort ''
            Expected to run from the proj-nix-demo umbrella repo root.

            Could not find:
              ${toString corelibDefaultNix}

            Fix:
              cd <path-to-proj-nix-demo>
              nix run .#viewer-local --impure
          '';

      viewer = import "${viewerSrc}/default.nix" { inherit pkgs corelib; src = viewerSrc; };
      editor = import "${editorSrc}/default.nix" { inherit pkgs corelib; src = editorSrc; };

    in
    {
      packages.${system} = {
        corelib-local = corelib;
        viewer-local = viewer;
        editor-local = editor;
      };

      apps.${system} = {
        viewer-local = {
          type = "app";
          program = "${viewer}/bin/nix-demo-viewer";
        };
        editor-local = {
          type = "app";
          program = "${editor}/bin/nix-demo-editor";
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          clang
          cmake
          ninja
          clang-tools
          catch2_3
          qt5.qtbase
          qt5.qtdeclarative
          qt5.qtquickcontrols2
          corelib
        ];

        shellHook = ''
          export CMAKE_EXPORT_COMPILE_COMMANDS=1
          export CC=clang
          export CXX=clang++
          export QT_QUICK_BACKEND=software
          export CMAKE_PREFIX_PATH="${corelib}:$CMAKE_PREFIX_PATH"
        '';
      };
    };
}
