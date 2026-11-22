{ self, config, ... }:
let
  topology = config.flake.meta.topology;
  scraperAddress = topology.hosts.callisto.lanAddress;
  apiAddress = topology.k3sApiAddress;
  ciliumChart =
    pkgs:
    pkgs.fetchurl {
      name = "helm.cilium.io-cilium-1.20.4.tgz";
      url = "https://helm.cilium.io/cilium-1.20.4.tgz";
      hash = "sha256-UFq/+DhYEd8alJd2/ELp8QaXmJozKsyG1uiTPvy4Ve0=";
    };
  serverNames = [
    "io"
    "ceres"
    "callisto"
  ];
in
{
  # Shared baseline for all k3s cluster nodes (both control-plane servers and
  # worker agents such as the N100 sandbox and HPE ProLiant ML350 Gen9).
  flake.modules.nixos.k3s-node =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      boot.kernelModules = [
        "br_netfilter"
        "ip_vs"
        "ip_vs_rr"
        "ip_vs_sh"
        "ip_vs_wrr"
        "nf_conntrack"
        "overlay"
      ];

      boot.kernel.sysctl = {
        "net.bridge.bridge-nf-call-ip6tables" = lib.mkDefault 1;
        "net.bridge.bridge-nf-call-iptables" = lib.mkDefault 1;
        # lib.mkDefault so VPN-Confinement (which sets plain `= 1`) can coexist on europa.
        "net.ipv4.ip_forward" = lib.mkDefault 1;
      };

      # Required for NFS and iSCSI PersistentVolumeClaims against ceres.
      services.rpcbind.enable = true;
      services.openiscsi = {
        enable = true;
        name = "iqn.2026-10.com.rdatar:${config.networking.hostName}";
      };

      environment.systemPackages = [
        pkgs.k9s
        pkgs.kubectl
        pkgs.kubernetes-helm
        pkgs.nfs-utils
      ];

      # Interactive work (SSH sessions, nix shells, evaluations) must never starve the
      # control plane or kubelet. On 2026-11-09 a nix-index run left behind after logout
      # ate all of io's RAM and the node thrashed until power-cycled. A hard cgroup cap
      # with little swap makes the kernel OOM-kill the largest process in user.slice
      # quickly. No MemoryHigh: throttling turned a runaway into a minutes-long crawl.
      # systemd-oomd is off for user slices here: in testing it killed an idle SSH
      # session instead of the process using the memory.
      systemd.slices.user.sliceConfig = {
        MemoryMax = "50%";
        MemorySwapMax = "512M";
      };
      systemd.oomd.enableUserSlices = lib.mkForce false;

      # A little compressed swap absorbs spikes and gives systemd-oomd the swap signal it
      # needs. Pods stay off swap (kubelet's default NoSwap behaviour; k3s runs kubelet
      # with fail-swap-on=false).
      zramSwap = {
        enable = true;
        memoryPercent = lib.mkDefault 25;
      };

      # Kubelet budget (io memory incident 2026-11-09, media-k3s migration): reserve memory and
      # CPU for the OS, native services and k3s itself, and evict pods before the node runs
      # out. Hosts with heavier native services override with plain values (europa).
      services.k3s.extraKubeletConfig = {
        systemReserved = lib.mkDefault {
          cpu = "250m";
          memory = "1Gi";
        };
        kubeReserved = lib.mkDefault {
          cpu = "250m";
          memory = "512Mi";
        };
        evictionHard = lib.mkDefault {
          "memory.available" = "300Mi";
          "nodefs.available" = "10%";
          "imagefs.available" = "10%";
        };
      };

      # Advertise the LAN address explicitly: nodes can be multi-homed (storage links, VPN
      # bridges), and k3s would otherwise pick by default route. From topology.
      services.k3s.nodeIP = lib.mkDefault (
        topology.hosts.${config.networking.hostName}.lanAddress or null
      );

      # Let the kubelet stop pods cleanly when the host shuts down or reboots.
      services.k3s.gracefulNodeShutdown.enable = true;

      # Cilium (ADR 0013): native routing between the nodes, so no VXLAN port. Pod traffic
      # to the node arrives on Cilium's host/veth devices. The reverse-path check stays
      # "loose" (strict drops Cilium's asymmetric routes).
      networking.firewall = {
        trustedInterfaces = [
          "cilium_host"
          "cilium_net"
          "cilium_wg0" # decrypted pod traffic from other nodes (Cilium transparent encryption)
          "lxc+"
        ];
        # Cilium transparent encryption: WireGuard between the nodes' pods (kernel WireGuard).
        allowedUDPPorts = [ 51871 ];
        # 6443/tcp: Kubernetes API server
        # 10250/tcp: Kubelet metrics & logs
        # 4240/tcp: Cilium health checks between nodes
        # 4244/tcp: Hubble server (Hubble Relay connects to every node)
        allowedTCPPorts = [
          6443
          10250
          4240
          4244
        ];
        # Cilium agent (9962) and Hubble (9965) metrics: Prometheus on callisto only.
        # Cilium's Gateway/L7 proxy uses TPROXY: packets of proxied connections carry fwmark
        # 0x200 and are routed to local delivery (ip rule → table 2004). The loose reverse-path
        # check evaluates the source with that mark, finds the local route, and drops them, so
        # the TCP handshake never completes. Exempt only those marked packets.
        extraCommands = ''
          iptables -A nixos-fw -p tcp -s ${scraperAddress} -m multiport --dports 9962,9965 -j nixos-fw-accept
          iptables -t mangle -I nixos-fw-rpfilter 1 -m mark --mark 0x200/0xf00 -m comment --comment "cilium proxy (tproxy)" -j RETURN
        '';
      };
    };

  # Common settings for embedded-etcd servers. Keep critical settings identical
  # across all three; only io has clusterInit. Joining servers use the API VIP.
  flake.modules.nixos.k3s-server =
    let
      oidcConfig = {
        apiVersion = "apiserver.config.k8s.io/v1";
        kind = "AuthenticationConfiguration";
        jwt = [
          {
            issuer = {
              url = "https://auth.datars.org";
              audiences = [
                "kubernetes"
                "headlamp"
              ];
              # Required with more than one audience: accept a token issued to any of them.
              audienceMatchPolicy = "MatchAny";
            };
            claimMappings = {
              username = {
                claim = "preferred_username";
                prefix = "oidc:";
              };
              groups = {
                claim = "groups";
                prefix = "oidc:";
              };
            };
          }
        ];
      };
    in
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      lanAddress = topology.hosts.${config.networking.hostName}.lanAddress;
      apiVip = config.services.keepalived.vrrpInstances.k3s-api;
      peers = map (name: topology.hosts.${name}.lanAddress) (
        lib.remove config.networking.hostName serverNames
      );
    in
    {
      imports = [ self.modules.nixos.k3s-node ];

      services.keepalived = {
        enable = true;
        enableScriptSecurity = true;
        vrrpScripts.k3s-ready = {
          # Readiness includes etcd; a listening TCP socket can still be unready.
          script = toString (
            pkgs.writeShellScript "k3s-ready" ''
              response="$(${lib.getExe pkgs.curl} --noproxy '*' --fail --silent --max-time 1 \
                --cacert /var/lib/rancher/k3s/server/tls/server-ca.crt \
                https://127.0.0.1:6443/readyz)" || exit 1
              test "$response" = ok
            ''
          );
          user = "root";
          interval = 2;
          timeout = 2;
          rise = 2;
          fall = 2;
          weight = 0; # An unready server faults rather than offering a bad VIP.
          extraConfig = "init_fail";
        };
        vrrpInstances.k3s-api = {
          state = "BACKUP";
          virtualRouterId = 51;
          unicastSrcIp = lanAddress;
          unicastPeers = peers;
          virtualIps = [
            {
              addr = "${apiAddress}/32";
              dev = apiVip.interface;
            }
          ];
          trackScripts = [ "k3s-ready" ];
          extraConfig = "check_unicast_src";
        };
      };

      # Enforce peer-only access ahead of the trusted Cilium interfaces. Local
      # etcd clients use loopback; VRRP has no loopback/IPv6 use here.
      networking.firewall.extraCommands = ''
        ip46tables -I nixos-fw 1 ! -i lo -p tcp --dport 2379:2380 -j DROP
        ip46tables -I nixos-fw 1 -p 112 -j DROP
      ''
      + lib.concatMapStrings (peer: ''
        iptables -I nixos-fw 1 -i ${apiVip.interface} -s ${peer} -d ${lanAddress} -p 112 -j nixos-fw-accept
        iptables -I nixos-fw 1 -i ${apiVip.interface} -s ${peer} -d ${lanAddress} -p tcp --dport 2379:2380 -j nixos-fw-accept
      '') peers;

      services.k3s = {
        enable = true;
        role = "server";
        # These flags, and the k3s defaults for pod/service CIDRs, are shared.
        extraFlags = [
          "--write-kubeconfig-mode=0640"
          "--write-kubeconfig-group=wheel"
          "--kube-apiserver-arg=authentication-config=/etc/rancher/k3s/authentication-config.yaml"
          # Cilium replaces flannel, kube-router, kube-proxy, ServiceLB and Traefik (ADR 0013).
          # Agents take these from the server.
          "--flannel-backend=none"
          "--disable-network-policy"
          "--disable-kube-proxy"
          "--disable=traefik,servicelb"
        ]
        ++ map (san: "--tls-san=${san}") ([ apiAddress ] ++ serverNames);
      };

      environment = {
        systemPackages = [ pkgs.etcd_3_6.deps.etcdctl ];
        variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
        etc."rancher/k3s/authentication-config.yaml".text = builtins.toJSON oidcConfig;
      };
    };

  # Joiners use the existing cluster's token, not a new cluster-init token.
  flake.modules.nixos.k3s-joining-server = { config, pkgs, ... }: {
    imports = [ self.modules.nixos.k3s-server ];

    age.secrets.k3s-token.file = ../../secrets/k3s-token.age;
    services.k3s = {
      serverAddr = "https://${apiAddress}:6443";
      tokenFile = config.age.secrets.k3s-token.path;
      # Helm fetches this from the Kubernetes API Service, which can route
      # to any server. Only io publishes the AddOn, not the archive itself.
      charts.cilium = ciliumChart pkgs;
    };
  };

  # One writer for cluster-wide K3s AddOns: server manifest directories are not
  # synchronized. io owns these files, but running workloads do not depend on it.
  flake.modules.nixos.k3s-bootstrap = { pkgs, ... }: {
    services.k3s = {
      # Gateway API standard CRDs: Cilium checks for them at start-up.
      manifests.gateway-api-crds.source = pkgs.fetchurl {
        url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.3/standard-install.yaml";
        hash = "sha256-NWwrjihqlk3CCZVDVlmtEJU4YymXR5OvELv+Pv+Xf+U=";
      };

      # The CNI belongs to the node layer: it must exist before any pod (Flux included)
      # can run. Its configuration objects (IP pools, L2 policy, Gateway, policies) live in
      # oort-cloud infrastructure/network and are applied by Flux.
      autoDeployCharts.cilium = {
        package = ciliumChart pkgs;
        targetNamespace = "kube-system";
        # Install on the host network before any CNI exists (k3s HelmChart `bootstrap`).
        extraFieldDefinitions.spec.bootstrap = true;
        values = {
          kubeProxyReplacement = true;
          # LAN L3 interfaces only. br0 owns callisto's host IP; never select
          # its bridge ports eno1/vnet*. Names absent on a node do not match.
          devices = [
            "enp1s0"
            "ens1f0"
            "enp2s0"
            "br0"
          ];
          k8sServiceHost = apiAddress;
          k8sServicePort = 6443;
          # All nodes share one L2 segment: route pod CIDRs directly, no tunnel.
          routingMode = "native";
          autoDirectNodeRoutes = true;
          ipv4NativeRoutingCIDR = "10.42.0.0/16";
          # Keep k3s's per-node pod CIDRs (10.42.<n>.0/24).
          ipam.mode = "kubernetes";
          bpf.masquerade = true;
          # LoadBalancer VIPs announced by ARP; leader leases go through the API server.
          l2announcements.enabled = true;
          k8sClientRateLimit = {
            qps = 20;
            burst = 40;
          };
          gatewayAPI.enabled = true;
          # Encrypt pod-to-pod traffic between nodes with WireGuard (keys managed by Cilium).
          # Host-to-host traffic (kubelet, etcd, iSCSI/NFS to the NAS) is not covered.
          encryption = {
            enabled = true;
            type = "wireguard";
          };
          operator.replicas = 1;
          prometheus.enabled = true;
          hubble = {
            relay.enabled = true;
            ui.enabled = true;
            metrics.enabled = [
              "dns"
              "drop"
              "tcp"
              "flow"
              "icmp"
              "httpV2"
            ];
          };
        };
      };
    };
  };

  # Worker-only k3s agent node
  # Set `services.k3s.serverAddr` and `services.k3s.tokenFile` in the host module.
  flake.modules.nixos.k3s-agent = {
    imports = [ self.modules.nixos.k3s-node ];

    services.k3s = {
      enable = true;
      role = "agent";
    };
  };
}
