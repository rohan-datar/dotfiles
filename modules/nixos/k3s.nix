{ self, ... }:
{
  # Shared baseline for all k3s cluster nodes (both control-plane servers and
  # worker agents such as the N100 sandbox and HPE ProLiant ML350 Gen9).
  flake.modules.nixos.k3s-node =
    { config, pkgs, ... }:
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
      # ate all of io's RAM and the node thrashed until power-cycled (no swap, oomd's
      # pressure limit never tripped). A hard cgroup cap makes the kernel OOM-kill inside
      # user.slice instead; MemoryHigh throttles before that.
      systemd.slices.user.sliceConfig = {
        MemoryHigh = "40%";
        MemoryMax = "50%";
      };

      # A little compressed swap absorbs spikes and gives systemd-oomd the swap signal it
      # needs. Pods stay off swap (kubelet's default NoSwap behaviour; k3s runs kubelet
      # with fail-swap-on=false).
      zramSwap = {
        enable = true;
        memoryPercent = 25;
      };

      # Allow pod-to-pod traffic on the Flannel CNI bridge and VXLAN interface.
      networking.firewall = {
        trustedInterfaces = [
          "cni0"
          "flannel.1"
        ];
        # 6443/tcp: Kubernetes API server
        # 10250/tcp: Kubelet metrics & logs
        # 8472/udp: Flannel VXLAN overlay
        allowedTCPPorts = [
          6443
          10250
        ];
        allowedUDPPorts = [ 8472 ];
      };
    };

  # Single-server or control-plane k3s node (e.g. N100 cluster node).
  flake.modules.nixos.k3s-server =
    { lib, ... }:
    {
      imports = [ self.modules.nixos.k3s-node ];

      services.k3s = {
        enable = true;
        role = "server";
        clusterInit = lib.mkDefault true;
        extraFlags = toString [
          "--write-kubeconfig-mode=0640"
          "--write-kubeconfig-group=wheel"
        ];
      };

      environment.variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
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
