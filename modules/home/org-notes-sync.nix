_: {
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
      stateDirectory = "${config.home.homeDirectory}/.local/state/rclone/org-sync/${cfg.hostId}";
      workDirectory = "${stateDirectory}/work";
      initializedMarker = "${stateDirectory}/initialized";
      remoteNotes = "org-storage-box:/home/org";
      logDirectory = "${config.home.homeDirectory}/Library/Logs";

      syncMinutes = map (step: cfg.scheduleOffsetMinutes + (step * 10)) (lib.range 0 5);
      minuteString = minute: if minute < 10 then "0${toString minute}" else toString minute;

      commonArguments = [
        "--config"
        rcloneConfig
        "bisync"
        cfg.notesDirectory
        remoteNotes
        "--filter-from"
        rcloneFilter
        "--workdir"
        workDirectory
        "--check-access"
        "--check-filename"
        "RCLONE_TEST"
        "--create-empty-src-dirs"
        "--compare"
        "size,modtime"
        "--modify-window"
        "2s"
        "--conflict-resolve"
        "newer"
        "--conflict-loser"
        "pathname"
        "--conflict-suffix"
        "conflict-${cfg.hostId}"
        "--max-delete"
        "10"
        "--max-lock"
        "45m"
        "--resilient"
        "--recover"
        "--check-first"
        "--checkers"
        "2"
        "--transfers"
        "2"
        "--retries"
        "3"
        "--retries-sleep"
        "10s"
        "--low-level-retries"
        "10"
        "--contimeout"
        "15s"
        "--timeout"
        "1m"
        "--log-level"
        "INFO"
        "--stats-one-line"
      ];

      sync = pkgs.writeShellScriptBin "org-notes-sync" ''
        set -euo pipefail
        if [[ ! -e ${lib.escapeShellArg initializedMarker} ]]; then
          echo "Org synchronization is not initialized. Run org-notes-sync-init once." >&2
          exit 0
        fi
        exec ${pkgs.rclone}/bin/rclone ${lib.escapeShellArgs commonArguments}
      '';

      initialize = pkgs.writeShellScriptBin "org-notes-sync-init" ''
        set -euo pipefail
        ${pkgs.coreutils}/bin/mkdir -p \
          ${lib.escapeShellArg cfg.notesDirectory} \
          ${lib.escapeShellArg workDirectory}
        if [[ ! -e ${lib.escapeShellArg "${cfg.notesDirectory}/RCLONE_TEST"} ]]; then
          ${pkgs.coreutils}/bin/printf 'org-sync-access-check\n' \
            >${lib.escapeShellArg "${cfg.notesDirectory}/RCLONE_TEST"}
        fi
        ${pkgs.rclone}/bin/rclone ${lib.escapeShellArgs commonArguments} \
          --resync --resync-mode ${lib.escapeShellArg cfg.initialSource}
        ${pkgs.coreutils}/bin/touch ${lib.escapeShellArg initializedMarker}
      '';

      gitSnapshot = pkgs.writeShellScriptBin "org-notes-git-snapshot" ''
        set -euo pipefail
        notes_dir=${lib.escapeShellArg cfg.notesDirectory}
        if [[ ! -d "$notes_dir/.git" ]]; then
          echo "Not a Git repository: $notes_dir" >&2
          exit 1
        fi
        cd "$notes_dir"
        ${pkgs.git}/bin/git add -A
        if ${pkgs.git}/bin/git diff --cached --quiet; then
          exit 0
        fi
        ${pkgs.git}/bin/git commit -m \
          "Automatic Org snapshot $(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S %Z')"
        ${pkgs.git}/bin/git push origin HEAD:main
      '';
    in
    {
      options.services.org-notes-sync = {
        enable = mkEnableOption "bidirectional Org notes synchronization";

        hostId = mkOption {
          type = types.str;
          description = "Stable identifier for this computer's independent bisync state.";
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
          description = "Authoritative side for the explicit one-time initialization command.";
        };

        scheduleOffsetMinutes = mkOption {
          type = types.ints.between 0 9;
          default = 0;
          description = "Minute offset for the ten-minute schedule; use a different value per computer.";
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
            initialize
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
            md5sum_command = md5sum
            sha1sum_command = sha1sum
            connections = 3
            concurrency = 8
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
              ${lib.escapeShellArg workDirectory}
            if [[ ! -e ${lib.escapeShellArg "${cfg.notesDirectory}/RCLONE_TEST"} ]]; then
              run touch ${lib.escapeShellArg "${cfg.notesDirectory}/RCLONE_TEST"}
            fi
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
              ExecStart = "${sync}/bin/org-notes-sync";
              TimeoutStartSec = "50min";
              Nice = 5;
            };
          };

          systemd.user.timers.org-notes-sync = {
            Unit.Description = "Periodic canonical Org notes synchronization";
            Timer = {
              OnCalendar = map (minute: "*-*-* *:${minuteString minute}:00") syncMinutes;
              AccuracySec = "30s";
              Persistent = true;
            };
            Install.WantedBy = [ "timers.target" ];
          };
        })

        (mkIf isDarwin {
          home.activation.org-notes-sync-logs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run mkdir -p ${lib.escapeShellArg logDirectory}
          '';

          launchd.agents.org-notes-sync = {
            enable = true;
            domain = "user";
            config = {
              ProgramArguments = [ "${sync}/bin/org-notes-sync" ];
              RunAtLoad = true;
              StartCalendarInterval = map (minute: { Minute = minute; }) syncMinutes;
              ProcessType = "Background";
              Nice = 5;
              StandardOutPath = "${logDirectory}/org-notes-sync.log";
              StandardErrorPath = "${logDirectory}/org-notes-sync.error.log";
            };
          };
        })

        (mkIf (isDarwin && cfg.enableGitSnapshots) {
          launchd.agents.org-notes-git-snapshot = {
            enable = true;
            domain = "user";
            config = {
              ProgramArguments = [ "${gitSnapshot}/bin/org-notes-git-snapshot" ];
              StartCalendarInterval =
                map
                  (hour: {
                    Hour = hour;
                    Minute = 5;
                  })
                  [
                    0
                    4
                    8
                    12
                    16
                    20
                  ];
              ProcessType = "Background";
              Nice = 10;
              StandardOutPath = "${logDirectory}/org-notes-git-snapshot.log";
              StandardErrorPath = "${logDirectory}/org-notes-git-snapshot.error.log";
            };
          };
        })
      ]);
    };
}
