# home/home.nix
{ config, lib, pkgs, username, systemUsername, email, system, everything-claude-code, gstack, ... }:
let
  # Import new module structures
  homeInstalls = import ./packages.nix {
    inherit config lib pkgs email system;
    inherit systemUsername username;
  };
  homeExec = import ../executions/home.nix {
    inherit config lib pkgs system;
    inherit systemUsername username;
  };
  homeConfig = import ../configurations/home.nix {
    inherit config lib pkgs email system;
    inherit systemUsername username;
  };
  commonExec = import ../executions/default.nix { inherit pkgs system; };

  # Claude Code configuration
  claudeCode = import ./claude-code.nix {
    inherit config lib pkgs everything-claude-code gstack;
  };

  # Codex CLI configuration (shares ECC + gstack skills via the Agent Skills standard)
  codex = import ./codex.nix {
    inherit config lib pkgs everything-claude-code gstack;
  };

  # Register a GitHub access token in user nix.conf so `nix develop github:...`
  # needs no NIX_CONFIG prefix (avoids api.github.com rate-limit 403).
  nixAccessToken = import ./nix-access-token.nix { inherit lib pkgs; };
in
{
  home.username = systemUsername;
  home.stateVersion = "24.05";

  # Disable manual generation to avoid "builtins.toFile options.json" warning
  # See: https://github.com/nix-community/home-manager/issues/7935
  manual.manpages.enable = false;
  manual.html.enable = false;
  manual.json.enable = false;

  home.packages = homeInstalls.packages ++ claudeCode.packages ++ codex.packages;

  # Neovim: disable mouse so terminal-native drag-select/copy works over SSH.
  home.file.".config/nvim/init.lua".text = ''
    vim.opt.mouse = ""
  '';

  # Activation scripts: Claude Code + Codex + nix access token
  home.activation = claudeCode.activation // codex.activation // nixAccessToken.activation;

  programs = lib.recursiveUpdate homeInstalls.programs {
    # Git
    git = homeInstalls.programs.git // homeConfig.git;

    # Starship
    starship = homeInstalls.programs.starship // homeConfig.starship;

    # Zsh
    zsh = homeInstalls.programs.zsh // homeConfig.zsh // {
      shellAliases = homeExec.aliases // claudeCode.aliases // codex.aliases // {
        # Noglob settings for nix commands (prevents "no matches found" errors with .#flake syntax)
        nix = "noglob nix";
      };
      initContent = homeExec.zshConfig.initExtra;
    };

    # Bash
    bash = homeInstalls.programs.bash // {
      shellAliases = homeExec.aliases // claudeCode.aliases // codex.aliases;
      initExtra = homeExec.bashConfig.initExtra;
    };

    # Bat configuration
    bat = homeInstalls.programs.bat // homeConfig.bat;

  };

  # Set session variables from configuration module
  home.sessionVariables = homeConfig.environment // claudeCode.sessionVariables;
}
