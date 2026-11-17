{ self, config, ... }:
let
  topology = config.flake.meta.topology;
  ioAddress = topology.hosts.io.lanAddress;
  scraperAddress = topology.hosts.home-controller.lanAddress;
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
        "net.bridge.bridge-nf-call-ip6tables" = 1;
        "net.bridge.bridge-nf-call-iptables" = 1;
        "net.ipv4.ip_forward" = 1;
      };

      # Required for NFS and iSCSI PersistentVolumeClaims against home-nas.
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
        memoryPercent = 25;
      };

      # Cilium (ADR 0013): native routing between the nodes, so no VXLAN port. Pod traffic
      # to the node arrives on Cilium's host/veth devices. The reverse-path check stays
      # "loose" (strict drops Cilium's asymmetric routes).
      networking.firewall = {
        trustedInterfaces = [
          "cilium_host"
          "cilium_net"
          "lxc+"
        ];
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
        # Cilium agent (9962) and Hubble (9965) metrics: Prometheus on home-controller only.
        extraCommands = ''
          iptables -A nixos-fw -p tcp -s ${scraperAddress} -m multiport --dports 9962,9965 -j nixos-fw-accept
        '';
      };
    };

  # Single-server or control-plane k3s node (e.g. N100 cluster node).
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
    { lib, pkgs, ... }:
    {
      imports = [ self.modules.nixos.k3s-node ];

      services.k3s = {
        enable = true;
        role = "server";
        clusterInit = lib.mkDefault true;
        extraFlags = toString [
          "--write-kubeconfig-mode=0640"
          "--write-kubeconfig-group=wheel"
          "--kube-apiserver-arg=authentication-config=/etc/rancher/k3s/authentication-config.yaml"
          # Cilium replaces flannel, kube-router, kube-proxy, ServiceLB and Traefik (ADR 0013).
          # Agents take these from the server.
          "--flannel-backend=none"
          "--disable-network-policy"
          "--disable-kube-proxy"
          "--disable=traefik,servicelb"
        ];

        # Gateway API standard CRDs: Cilium checks for them at start-up.
        manifests.gateway-api-crds.source = pkgs.fetchurl {
          url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.3/standard-install.yaml";
          hash = "sha256-NWwrjihqlk3CCZVDVlmtEJU4YymXR5OvELv+Pv+Xf+U=";
        };

        # The CNI belongs to the node layer: it must exist before any pod (Flux included)
        # can run. Its configuration objects (IP pools, L2 policy, Gateway, policies) live in
        # oort-cloud infrastructure/network and are applied by Flux.
        autoDeployCharts.cilium = {
          name = "cilium";
          repo = "https://helm.cilium.io";
          version = "1.20.4";
          hash = "sha256-UFq/+DhYEd8alJd2/ELp8QaXmJozKsyG1uiTPvy4Ve0=";
          targetNamespace = "kube-system";
          # Install on the host network before any CNI exists (k3s HelmChart `bootstrap`).
          extraFieldDefinitions.spec.bootstrap = true;
          values = {
            kubeProxyReplacement = true;
            k8sServiceHost = ioAddress;
            k8sServicePort = 6443;
            # Both nodes share one L2 segment: route pod CIDRs directly, no tunnel.
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

      environment = {
        variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
        etc."rancher/k3s/authentication-config.yaml".text = builtins.toJSON oidcConfig;
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
