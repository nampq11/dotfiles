{ inputs }:
[
  # Standard NUR overlay
  inputs.nur.overlays.default

  # provide non-deprecated alias so upstream modules using pkgs.system don't emit warnings.
  (final: prev: {
    system = prev.stdenv.hostPlatform.system;
  })

  # Fix shellspec wrapper script that breaks when called via symlinks
  (final: prev: {
    shellspec = prev.shellspec.overrideAttrs (oldAttrs: {
      postInstall = (oldAttrs.postInstall or "") + ''
        # Replace the wrapper with one that uses an absolute path
        cat > $out/bin/shellspec << EOF
        #!${prev.bash}/bin/sh
        exec "$out/lib/shellspec/shellspec" "\$@"
        EOF
        chmod +x $out/bin/shellspec
      '';
    });
  })
]