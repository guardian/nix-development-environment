{ pkgs, ... }:
let
  commandSet = { appName, commandSetName, commands }:
    let
      allCommandsJson = pkgs.writeTextFile {
        name = "${commandSetName}-all-commands.json";
        text = builtins.toJSON commands;
      };
      listCommandsJson = pkgs.writeShellApplication {
        name = "${commandSetName}-list-commands-json";
        runtimeInputs = [ pkgs.jq ];
        text = ''
          jq . "${allCommandsJson}"
        '';
      };
      listCommands = pkgs.writeShellApplication {
        name = "${commandSetName}-list-commands";
        runtimeInputs = [ pkgs.jq ];
        text = "list-commands-json | jq -r 'map([.] | @tsv) | .[]'";
      };

      runAllTmux = pkgs.writeShellApplication {
        name = "${commandSetName}-run-all-tmux";
        runtimeInputs = [ pkgs.tmux ];
        text = builtins.foldl' (acc: command:
          if acc == "" then
            builtins.concatStringsSep " \";\" " [
              ''tmux new-session "${command}/bin/${command.name}"''
              "set-option remain-on-exit on"
              ''rename-session "${appName}:${commandSetName}"''
            ]
          else
            acc
            + " \";\" new-window -n ${command.name} \"${command}/bin/${command.name}\"")
          "" commands;
      };

      runAllBackground = pkgs.writeShellApplication {
        name = "${commandSetName}-run-all-background";
        runtimeInputs = [ ];
        text = builtins.concatStringsSep " &\n"
          (builtins.map (command: "${command}/bin/${command.name}") commands);
      };
    in { };
in {
  devEnv = { name, commands, extraInputs ? [ ], ... }:
    pkgs.mkShellNoCC {
      nativeBuildInputs = let

      in commands ++ extraInputs ++ [
        pkgs.tmux
        pkgs.jq
        listCommandsJson
        listCommands
        runAllTmux
        runAllBackground
      ];
    };
}
