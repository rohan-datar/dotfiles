{
  config,
  pkgs,
  lib,
  ...
}: let
  nixpkgs = import ./. {
    overlays = [];
    config = {
      allowUnfree = true;
    };
  };
in
  nixpkgs.linuxKernel.packages.linux_6_13.nvidiaPackages.mkDriver {
    version = "565.77";
    sha256_64bit = "sha256-CnqnQsRrzzTXZpgkAtF7PbH9s7wbiTRNcM0SPByzFHw=";
    sha256_aarch64 = "sha256-LSAYUnhfnK3rcuPe1dixOwAujSof19kNOfdRHE7bToE=";
    openSha256 = "sha256-Fxo0t61KQDs71YA8u7arY+503wkAc1foaa51vi2Pl5I=";
    settingsSha256 = "sha256-VUetj3LlOSz/LB+DDfMCN34uA4bNTTpjDrb6C6Iwukk=";
    persistencedSha256 = "sha256-wnDjC099D8d9NJSp9D0CbsL+vfHXyJFYYgU3CwcqKww=";
    patchesOpen = [
      (
        nixpkgs.fetchpatch {
          url = "https://gitlab.manjaro.org/packages/extra/linux613-extramodules/nvidia/-/raw/main/kernel-6.13.patch";
          hash = "sha256-C21kymMJT/C2kuUXnOyqwLPzpas4/6CAXTllL24i8ic=";
        }
      )
    ];
  }
