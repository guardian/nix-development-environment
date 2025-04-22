{ pkgs, ... }:

{
  devEnv = { name, commands, extraInputs ? [ ], ... }:
    pkgs.mkShellNoCC {
      nativeBuildInputs = let
        allCommandsJson = pkgs.writeTextFile {
          name = "all-commands.json";
          text = builtins.toJSON commands;
        };
        listCommandsJson = pkgs.writeShellApplication {
          name = "list-commands-json";
          runtimeInputs = [ pkgs.jq ];
          text = ''
            jq . "${allCommandsJson}"
          '';
        };
        listCommands = pkgs.writeShellApplication {
          name = "list-commands";
          runtimeInputs = [ pkgs.jq ];
          text = "list-commands-json | jq -r 'map([.] | @tsv) | .[]'";
        };

        runAllTmux = pkgs.writeShellApplication {
          name = "run-all-tmux";
          runtimeInputs = [ pkgs.tmux ];
          text = builtins.foldl' (acc: command:
            if acc == "" then
              builtins.concatStringsSep " \";\" " [
                ''tmux new-session "${command}/bin/${command.name}"''
                "set-option remain-on-exit on"
                ''rename-session "${name}"''
              ]
            else
              acc
              + " \";\" new-window -n ${command.name} \"${command}/bin/${command.name}\"")
            "" commands;
        };

        runAllBackground = pkgs.writeShellApplication {
          name = "run-all-background";
          runtimeInputs = [ ];
          text = builtins.concatStringsSep " &\n"
            (builtins.map (command: "${command}/bin/${command.name}") commands);
        };
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
