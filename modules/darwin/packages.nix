{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    libwebp # WebP image format library
    m-cli # A macOS cli tool to manage macOS - a true swis army knife
  ];
}
