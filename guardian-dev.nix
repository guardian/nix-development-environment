{ pkgs, ... }:

{
  devEnv = { name, commands, ... }:
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
              acc + " \";\" split-window -v \"${command}/bin/${command.name}\"")
            "" commands;
        };
      in commands
      ++ [ pkgs.tmux pkgs.jq listCommandsJson listCommands runAllTmux ];
    };
}
