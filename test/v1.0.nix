let
  pkgs = import <nixpkgs> { };
  guardianNix = builtins.fetchGit {
    url = "git@github.com:guardian/guardian-nix.git";
    ref = "refs/tags/v1";
  };
  guardianDev = import "${guardianNix.outPath}/guardian-dev.nix" pkgs;

  firstCommand = pkgs.writeShellApplication {
    name = "first-command";
    runtimeInputs = [ ];
    text = ''
      echo "first-command"
    '';
  };
in guardianDev.devEnv {
  name = "test-v1.0";
  commands = [ firstCommand ];
}
