{ inputs, self, ... }:
let
  topology = self.meta.topology;
  name = "pallas";
  # Locally administered MAC (second nibble 2); stable so the router sees one client.
  mac = "02:a1:be:d0:00:01";
  tap = "vm-${name}";
  stateDir = "/var/lib/microvms/${name}";
  # The guest writes a consistent copy of its state here nightly (virtiofs share);
  # the host backs it up with its own restic credentials, which never enter the guest.
  exportDir = "${stateDir}/backup-export";
  webPort = 4317;
  publicUrl = "https://ai.rdatar.com";

  guest =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      albedo = inputs.albedo.packages.${pkgs.stdenv.hostPlatform.system}.albedo;
      home = config.users.users.rdatar.home;
      albedoHome = "${home}/.albedo";
      # Same PATH shape as upstream's Home Manager unit: system profile only (no HM here).
      servicePath = lib.makeBinPath [
        config.nix.package
        "/run/current-system/sw"
      ];
      unitEnv = [
        "ALBEDO_HOME=${albedoHome}"
        "PATH=${servicePath}"
      ];
    in
    {
      imports = [
        inputs.microvm.nixosModules.microvm
        inputs.home-manager.nixosModules.home-manager
        self.modules.nixos.rdatar # owner account + SSH keys (owner-approved, 2026-11-22)
      ];

      microvm = {
        hypervisor = "cloud-hypervisor";
        # Readiness via systemd-notify; any unique CID >= 3 on this host.
        vsock.cid = 16;
        vcpu = 4;
        # Measured 2026-11-22 on the Mac: daemon ~215 MiB, web ~25 MiB, kernels
        # 15-50 MiB each (~0.5 GiB for 7 sessions). Headroom is for Nix evaluation,
        # headless Chrome and project builds; raise if zram shows sustained use.
        mem = 6144; # owner-chosen 2026-11-22
        interfaces = [
          {
            type = "tap";
            id = tap;
            inherit mac;
          }
        ];
        shares = [
          {
            # Host store, read-only; guest builds land in the writable overlay below.
            proto = "virtiofs";
            tag = "ro-store";
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
          }
          {
            proto = "virtiofs";
            tag = "backup-export";
            source = exportDir;
            mountPoint = "/srv/backup-export";
          }
        ];
        writableStoreOverlay = "/nix/.rw-store";
        volumes = [
          {
            image = "home.img";
            mountPoint = "/home";
            size = 65536; # MiB: albedo home + project checkouts
          }
          {
            image = "var.img";
            mountPoint = "/var";
            size = 8192;
          }
          {
            image = "nix-rw.img";
            mountPoint = "/nix/.rw-store";
            size = 32768; # guest-side Nix builds (nix develop etc.)
          }
        ];
      };

      # Mount the /home volume in the initrd: activation's createHome runs before systemd
      # mounts ordinary filesystems, so otherwise the home lands under the mount point.
      fileSystems."/home".neededForBoot = true;

      networking = {
        hostName = name;
        useNetworkd = true;
        firewall = {
          allowedTCPPorts = [ 22 ];
          # Web gateway: OPNsense Caddy only (LAN and NetBird both arrive through it).
          extraCommands = ''
            iptables -A nixos-fw -p tcp -s ${topology.gatewayAddress} --dport ${toString webPort} -j nixos-fw-accept
          '';
        };
      };
      systemd.network = {
        enable = true;
        networks."20-lan" = {
          matchConfig.MACAddress = mac;
          networkConfig = {
            Address = [ "${topology.hosts.${name}.lanAddress}/19" ];
            Gateway = topology.gatewayAddress;
            DNS = [ topology.gatewayAddress ];
            DHCP = "no";
          };
        };
      };

      # Local names (luna.lan, sol.lan) come from the router's DNS; never fall back to
      # public resolvers, which can't answer them.
      services.resolved.settings.Resolve.FallbackDNS = [ "" ];

      # Org notes, synchronized like the workstations (rclone bisync with the dedicated
      # Storage Box subaccount; Git snapshots stay Mac-only). Home Manager only for this.
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.rdatar = {
          imports = [ self.modules.homeManager.org-notes-sync ];
          services.org-notes-sync = {
            enable = true;
            hostId = "pallas";
            initialSource = "path2"; # Storage Box is authoritative for the first run
            scheduleOffsetMinutes = 7; # Mac :00, desktop :05
            sshKeyFile = "${home}/.ssh/org-storage-box"; # VM's own key, owner-authorized
          };
          home.stateVersion = "25.11";
        };
      };

      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };

      # Inside the VM the owner account may be a trusted Nix user: the guest kernel is
      # the boundary, not this setting (ADR 0012 threat model).
      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [ "@wheel" ];
      };
      # Root inside its own VM is intended (owner, 2026-11-22): the guest kernel is the
      # boundary. The account has no password, so sudo must not ask for one.
      security.sudo.wheelNeedsPassword = false;

      environment.systemPackages = [
        albedo
        pkgs.git
        pkgs.openssh
        pkgs.ripgrep
        pkgs.sqlite
        pkgs.rsync
        pkgs.just
        # Remote kernels and session moves stage albedo's Python env with the host
        # interpreter; without one uv downloads a generic CPython NixOS can't run.
        pkgs.python311
      ];

      # Generic Linux binaries (uv-managed tools, prebuilt CLIs) run inside this VM.
      programs.nix-ld.enable = true;

      zramSwap.enable = true;

      # Long-lived user services without an interactive login.
      users.users.rdatar.linger = true;

      # Mirrors upstream nix/home-manager/module.nix (albedo 96aeaa8): the CLI recognises
      # the stable albedo.service name for lifecycle operations.
      systemd.user.services.albedo = {
        description = "albedo daemon";
        unitConfig = {
          ConditionUser = "rdatar";
          StartLimitIntervalSec = 60;
          StartLimitBurst = 5;
        };
        serviceConfig = {
          Type = "exec";
          ExecStart = "${albedo}/bin/albedo daemon --serve";
          Environment = unitEnv;
          KillMode = "process";
          Restart = "on-failure";
          RestartSec = 3;
          RestartPreventExitStatus = "75 78";
          TimeoutStopSec = 45;
          StandardOutput = "append:${albedoHome}/daemon.log";
          StandardError = "append:${albedoHome}/daemon.log";
        };
        wantedBy = [ "default.target" ];
      };

      # Upstream's web unit plus --public-url, which `albedo web --save` cannot persist.
      systemd.user.services.albedo-web = {
        description = "Albedo web gateway";
        after = [ "albedo.service" ];
        unitConfig.ConditionUser = "rdatar";
        serviceConfig = {
          Type = "exec";
          ExecStart = lib.concatStringsSep " " [
            "${albedo}/bin/albedo-web"
            "--foreground"
            "--service"
            "--no-open"
            "--port ${toString webPort}"
            # --allow names the network the listener serves: it binds this machine's
            # address inside it and accepts its clients. The guest firewall then limits
            # 4317 to OPNsense Caddy.
            "--allow 10.10.0.0/19"
            "--public-url ${publicUrl}"
          ];
          Environment = unitEnv;
          KillMode = "process";
          Restart = "on-failure";
          RestartSec = 3;
          StandardOutput = "append:${albedoHome}/web.log";
          StandardError = "append:${albedoHome}/web.log";
        };
        wantedBy = [ "default.target" ];
      };

      # Nightly consistent export for the host's restic job: an online SQLite backup
      # (backup API, safe beside the running daemon) plus everything else in the home.
      systemd.tmpfiles.rules = [ "d /srv/backup-export/rdatar 0700 rdatar users -" ];
      systemd.services.albedo-backup-export = {
        description = "Export albedo state for the host backup";
        serviceConfig = {
          Type = "oneshot";
          User = "rdatar";
        };
        path = [
          pkgs.sqlite
          pkgs.rsync
          pkgs.coreutils
        ];
        script = ''
          out=/srv/backup-export/rdatar
          mkdir -p "$out/albedo-db"
          if [ -f ${albedoHome}/albedo.sqlite ]; then
            sqlite3 ${albedoHome}/albedo.sqlite ".backup '$out/albedo-db/albedo.sqlite.tmp'"
            sqlite3 "$out/albedo-db/albedo.sqlite.tmp" "PRAGMA integrity_check;" | grep -qx ok
            mv "$out/albedo-db/albedo.sqlite.tmp" "$out/albedo-db/albedo.sqlite"
          fi
          rsync -a --delete \
            --exclude '/.albedo/albedo.sqlite' --exclude '/.albedo/albedo.sqlite-wal' \
            --exclude '/.albedo/albedo.sqlite-shm' --exclude '/.albedo/cache/' \
            --exclude '/.cache/' \
            ${home}/ "$out/home/"
          date -Is > "$out/exported-at"
        '';
      };
      systemd.timers.albedo-backup-export = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "02:45";
          Persistent = true;
        };
      };

      time.timeZone = "America/Chicago";
      system.stateVersion = "25.11";
    };
in
{
  # Persistent albedo harness (ADR 0012): a microVM on ganymede bridged onto the LAN.
  flake.modules.nixos.pallas-vm =
    { config, pkgs, ... }:
    {
      imports = [ inputs.microvm.nixosModules.host ];

      # Same Storage Box credentials as onedev-restic, separate repository.
      age.secrets.restic-password.file = ../../../secrets/restic-password.age;
      age.secrets.storagebox-ssh-key.file = ../../../secrets/storagebox-ssh-key.age;

      microvm.vms.${name} = {
        inherit pkgs;
        config = guest;
      };
      microvm.autostart = [ name ];

      # Host scripted networking does not manage the tap microvm.nix creates; enslave it
      # to br0 once the tap exists (the VM itself sits directly on the LAN).
      systemd.services."microvm-tap-interfaces@${name}".serviceConfig.ExecStartPost = [
        "${pkgs.iproute2}/bin/ip link set ${tap} master br0 up"
      ];

      # VM images (up to ~104 GiB sparse) live on the Btrfs RAID1, not the 128 GB boot
      # SSD. Same bind pattern as /srv/restic-nas. +C (no copy-on-write) is set on the
      # empty directory so new raw images inherit it and don't fragment under CoW.
      systemd.tmpfiles.rules = [
        "d /var/lib/rancher/k3s/storage/microvms 0755 root root -"
        "h /var/lib/rancher/k3s/storage/microvms - - - - +C"
        "d ${exportDir} 0700 root root -"
      ];
      fileSystems."/var/lib/microvms" = {
        device = "/var/lib/rancher/k3s/storage/microvms";
        fsType = "none";
        options = [
          "bind"
          "x-systemd.requires-mounts-for=/var/lib/rancher/k3s/storage"
        ];
      };
      systemd.services."microvm@${name}".unitConfig.RequiresMountsFor = [ "/var/lib/microvms" ];

      services.restic.backups.${name} = {
        repository = "sftp:u630851-sub1@u630851.your-storagebox.de:restic/${name}";
        passwordFile = config.age.secrets.restic-password.path;
        extraOptions = [
          "sftp.command='ssh -p 23 -i ${config.age.secrets.storagebox-ssh-key.path} -o StrictHostKeyChecking=accept-new u630851-sub1@u630851.your-storagebox.de -s sftp'"
        ];
        initialize = true;
        paths = [ exportDir ];
        timerConfig = {
          OnCalendar = "03:45";
          Persistent = true;
          RandomizedDelaySec = "15m";
        };
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-monthly 12"
        ];
        runCheck = true;
        checkOpts = [ "--read-data-subset=2%" ];
      };
      systemd.services."restic-backups-${name}".unitConfig.OnFailure = [
        "backup-failure-email@%n.service"
      ];
    };
}
