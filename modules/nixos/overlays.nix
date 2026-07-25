_: {
  flake.modules.nixos.overlays = {
    nixpkgs.overlays = [
      # cython_0's 0.29.37.1 sdist self-reports 0.29.37, tripping the
      # pythonMetadataCheckHook added in nixpkgs #532778. Breaks anything that
      # pulls py-libzfs (e.g. cockpit-zfs). Drop once fixed upstream.
      (_final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (_pyfinal: pyprev: {
            cython_0 = pyprev.cython_0.overridePythonAttrs (_: {
              dontCheckPythonMetadata = true;
            });
          })
        ];
      })
    ];
  };
}
