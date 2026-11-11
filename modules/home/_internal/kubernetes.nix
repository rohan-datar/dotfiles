{
  # SSO access to the homelab k3s cluster from the owner's workstations.
  # The kubeconfig holds no secrets: kubelogin opens Authelia in a browser and caches
  # short-lived tokens under ~/.kube/cache. The client-certificate context in
  # ~/.kube/config stays as the break-glass login, so it is listed first and remains
  # the default until `kubectl config use-context homelab-sso`.
  flake.modules.homeManager.kubernetes =
    { pkgs, ... }:
    let
      kubeconfig = {
        apiVersion = "v1";
        kind = "Config";
        clusters = [
          {
            name = "homelab-sso";
            cluster = {
              server = "https://10.10.1.14:6443";
              # Public CA certificate (kube-root-ca.crt), not a secret.
              certificate-authority = "${./kubernetes/homelab-ca.crt}";
            };
          }
        ];
        users = [
          {
            name = "homelab-sso";
            user.exec = {
              apiVersion = "client.authentication.k8s.io/v1";
              command = "${pkgs.kubelogin-oidc}/bin/kubectl-oidc_login";
              args = [
                "get-token"
                "--oidc-issuer-url=https://auth.datars.org"
                "--oidc-client-id=kubernetes"
                "--oidc-pkce-method=S256"
                "--oidc-extra-scope=profile"
                "--oidc-extra-scope=email"
                "--oidc-extra-scope=groups"
                "--oidc-extra-scope=offline_access"
              ];
              interactiveMode = "IfAvailable";
            };
          }
        ];
        contexts = [
          {
            name = "homelab-sso";
            context = {
              cluster = "homelab-sso";
              user = "homelab-sso";
            };
          }
        ];
      };
    in
    {
      home.packages = [ pkgs.kubelogin-oidc ];
      # JSON is valid YAML, which kubectl reads.
      home.file.".kube/homelab-sso.yaml".text = builtins.toJSON kubeconfig;
      home.sessionVariables.KUBECONFIG = "$HOME/.kube/config:$HOME/.kube/homelab-sso.yaml";
    };
}
