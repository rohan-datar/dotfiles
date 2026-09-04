_:
{
  flake.modules.homeManager.org-notes-sync =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        mkEnableOption
        mkIf
        mkMerge
        mkOption
        types
        ;
      inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
      cfg = config.services.org-notes-sync;

      rcloneConfig = "${config.xdg.configHome}/rclone/org-notes.conf";
      rcloneFilter = "${config.xdg.configHome}/rclone/org-notes.filter";
      knownHosts = "${config.home.homeDirectory}/.ssh/known_hosts-org-storage-box";

      syncCore = pkgs.writeShellApplication {
        name = "org-notes-sync-core";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.openssh
          pkgs.rclone
        ];
        text = builtins.readFile ./org-notes-sync.sh;
      };

      sync = pkgs.writeShellApplication {
        name = "org-notes-sync";
        runtimeInputs = [ syncCore ];
        text = ''
          export ORG_SYNC_HOST_ID=${lib.escapeShellArg cfg.hostId}
          export ORG_SYNC_NOTES_DIR=${lib.escapeShellArg cfg.notesDirectory}
          export ORG_SYNC_SSH_KEY_FILE=${lib.escapeShellArg cfg.sshKeyFile}
          export ORG_SYNC_RCLONE_CONFIG=${lib.escapeShellArg rcloneConfig}
          export ORG_SYNC_RCLONE_FILTER=${lib.escapeShellArg rcloneFilter}
          export ORG_SYNC_KNOWN_HOSTS=${lib.escapeShellArg knownHosts}
          export ORG_SYNC_INITIAL_SOURCE=${lib.escapeShellArg cfg.initialSource}
          export ORG_SYNC_STORAGE_BOX_USER=${lib.escapeShellArg cfg.storageBoxUser}
          exec org-notes-sync-core "$@"
        '';
      };

      gitSnapshot = pkgs.writeShellApplication {
        name = "org-notes-git-snapshot";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.git
        ];
        text = ''
          notes_dir=${lib.escapeShellArg cfg.notesDirectory}
          state_dir=${lib.escapeShellArg "${config.home.homeDirectory}/.local/state/rclone/org-sync/${cfg.hostId}"}
          lock_dir="$state_dir/process.lock"
          mkdir -p "$state_dir"

          if ! mkdir "$lock_dir" 2>/dev/null; then
            echo "Org sync is active; skipping Git snapshot." >&2
            exit 0
          fi
          trap 'rm -rf "$lock_dir"' EXIT INT TERM

          if [[ ! -d "$notes_dir/.git" ]]; then
            echo "Not a Git repository: $notes_dir" >&2
            exit 1
          fi

          cd "$notes_dir"
          git add -A -- . ':(exclude)calendar.org' ':(exclude)reminders.org' ':(exclude)RCLONE_TEST'
          if git diff --cached --quiet; then
            exit 0
          fi

          git commit -m "Automatic Org snapshot $(date '+%Y-%m-%d %H:%M:%S %Z')"
          git push origin HEAD:main
        '';
      };
    in
    {
      options.services.org-notes-sync = {
        enable = mkEnableOption "safe bidirectional Org notes synchronization";

        hostId = mkOption {
          type = types.str;
          description = "Stable identifier used for independent bisync state and backups.";
        };

        notesDirectory = mkOption {
          type = types.str;
          default = "${config.home.homeDirectory}/Documents/Org";
          description = "Local canonical Org notes directory.";
        };

        sshKeyFile = mkOption {
          type = types.str;
          default = "${config.home.homeDirectory}/.ssh/id_ed25519";
          description = "Machine-specific private key used for the Storage Box subaccount.";
        };

        storageBoxUser = mkOption {
          type = types.str;
          default = "u630851-sub4";
          description = "Dedicated Storage Box subaccount for Org synchronization.";
        };

        initialSource = mkOption {
          type = types.enum [
            "path1"
            "path2"
          ];
          description = "Authoritative side for the explicit one-time init command.";
        };

        intervalSeconds = mkOption {
          type = types.ints.positive;
          default = 900;
          description = "Interval between automatic synchronization runs.";
        };

        enableGitSnapshots = mkEnableOption "Mac-only Git snapshots and pushes";
      };

      config = mkIf cfg.enable (mkMerge [
        {
          assertions = [
            {
              assertion = !cfg.enableGitSnapshots || isDarwin;
              message = "Automatic Org Git snapshots must only be enabled on the Mac.";
            }
          ];

          home.packages = [
            pkgs.rclone
            sync
          ]
          ++ lib.optional cfg.enableGitSnapshots gitSnapshot;

          xdg.configFile."rclone/org-notes.conf".text = ''
            [org-storage-box]
            type = sftp
            host = ${cfg.storageBoxUser}.your-storagebox.de
            user = ${cfg.storageBoxUser}
            port = 23
            key_file = ${cfg.sshKeyFile}
            known_hosts_file = ${knownHosts}
            shell_type = unix
            host_key_algorithms = ssh-ed25519
          '';

          xdg.configFile."rclone/org-notes.filter".text = ''
            - /.git/**
            - /.git
            - **/.DS_Store
            - **/*~
            - **/#*#
            - **/.#*
            - **/.org-id-locations
          '';

          home.file.".ssh/known_hosts-org-storage-box".text = ''
            [${cfg.storageBoxUser}.your-storagebox.de]:23 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs
          '';

          home.activation.org-notes-sync-directories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run mkdir -p \
              ${lib.escapeShellArg cfg.notesDirectory} \
              ${lib.escapeShellArg "${config.home.homeDirectory}/.local/state/rclone/org-sync/${cfg.hostId}"} \
              ${lib.escapeShellArg "${config.home.homeDirectory}/.local/share/org-sync/backups/${cfg.hostId}"} \
              ${lib.escapeShellArg "${config.home.homeDirectory}/Library/Logs"}
            run touch ${lib.escapeShellArg "${cfg.notesDirectory}/RCLONE_TEST"}
          '';
        }

        (mkIf isLinux {
          systemd.user.services.org-notes-sync = {
            Unit = {
              Description = "Synchronize canonical Org notes with Storage Box";
              Wants = [ "network-online.target" ];
              After = [ "network-online.target" ];
            };
            Service = {
              Type = "oneshot";
              ExecStart = "${sync}/bin/org-notes-sync run";
              TimeoutStartSec = "50min";
              Nice = 5;
            };
          };

          systemd.user.timers.org-notes-sync = {
            Unit.Description = "Periodic canonical Org notes synchronization";
            Timer = {
              OnBootSec = "5min";
              OnUnitActiveSec = "${toString cfg.intervalSeconds}s";
              RandomizedDelaySec = "90s";
              Persistent = true;
            };
            Install.WantedBy = [ "timers.target" ];
          };
        })

        (mkIf isDarwin {
          launchd.agents.org-notes-sync = {
            enable = true;
            domain = "user";
            config = {
              ProgramArguments = [
                "${sync}/bin/org-notes-sync"
                "run"
              ];
              RunAtLoad = true;
              StartInterval = cfg.intervalSeconds;
              ProcessType = "Background";
              Nice = 5;
              StandardOutPath = "${config.home.homeDirectory}/Library/Logs/org-notes-sync.log";
              StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/org-notes-sync.error.log";
            };
          };
        })

        (mkIf (isDarwin && cfg.enableGitSnapshots) {
          launchd.agents.org-notes-git-snapshot = {
            enable = true;
            domain = "user";
            config = {
              ProgramArguments = [ "${gitSnapshot}/bin/org-notes-git-snapshot" ];
              RunAtLoad = true;
              StartInterval = 14400;
              ProcessType = "Background";
              Nice = 10;
              StandardOutPath = "${config.home.homeDirectory}/Library/Logs/org-notes-git-snapshot.log";
              StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/org-notes-git-snapshot.error.log";
            };
          };
        })
      ]);
    };
}
