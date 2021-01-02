{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.firejail;

  wrappedBins = pkgs.runCommand "firejail-wrapped-binaries"
    { preferLocalBuild = true;
      allowSubstitutes = false;
    }
    ''
      mkdir -p $out/bin
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (command: value:
      let
        opts = if builtins.isAttrs value
        then value
        else { executable = value; profile = null; extraArgs = []; };
        args = lib.escapeShellArgs (
          (optional (opts.profile != null) "--profile=${toString opts.profile}")
          ++ opts.extraArgs
          );
      in
      ''
        cat <<_EOF >$out/bin/${command}
        #! ${pkgs.runtimeShell} -e
        exec /run/wrappers/bin/firejail ${args} -- ${toString opts.executable} "\$@"
        _EOF
        chmod 0755 $out/bin/${command}
      '') cfg.wrappedBinaries)}
    '';

  wrappedPkgs = map (pkg:
    pkgs.symlinkJoin {
      name = "firejail-" + pkg.name;
      paths = [ pkg ];
      postBuild = ''
        [[ -d "$out/share/applications" ]] && grep -q -R Exec=/ "$out/share/applications" && \
          >&2 echo "WARNING: ${pkg.name} desktop file is not firejailed."
        for bin in $(find "$out/bin" -type l); do
          oldbin="$(readlink "$bin")"
          rm "$bin"
          cat <<_EOF >"$bin"
        #! ${pkgs.runtimeShell} -e
        exec /run/wrappers/bin/firejail "$oldbin" "\$@"
        _EOF
          chmod 0755 "$bin"
        done
      '';
    }
  ) cfg.wrappedPackages;

in {
  options.programs.firejail = {
    enable = mkEnableOption "firejail";

    wrappedBinaries = mkOption {
      type = types.attrsOf (types.either types.path (types.submodule {
        options = {
          executable = mkOption {
            type = types.path;
            description = "Executable to run sandboxed";
            example = literalExample "''${lib.getBin pkgs.firefox}/bin/firefox";
          };
          profile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Profile to use";
            example = literalExample "''${pkgs.firejail}/etc/firejail/firefox.profile";
          };
          extraArgs = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Extra arguments to pass to firejail";
            example = [ "--private=~/.firejail_home" ];
          };
        };
      }));
      default = {};
      example = literalExample ''
        {
          firefox = {
            executable = "''${lib.getBin pkgs.firefox}/bin/firefox";
            profile = "''${pkgs.firejail}/etc/firejail/firefox.profile";
          };
          mpv = {
            executable = "''${lib.getBin pkgs.mpv}/bin/mpv";
            profile = "''${pkgs.firejail}/etc/firejail/mpv.profile";
          };
        }
      '';
      description = ''
        Wrap the binaries in firejail and place them in the global path.
        </para>
        <para>
        You will get file collisions if you put the actual application binary in
        the global environment and applications started via .desktop files are
        not wrapped if they specify the absolute path to the binary.
      '';
    };

    wrappedPackages = mkOption {
      type = with types; listOf package;
      default = [ ];
      example = literalExample ''
        [ pkgs.mpv ]
      '';
      description = ''
        Put a package into <option>systemPackages</option>,
        but wrap its binaries with firejail.
        Compared to <option>wrappedBinaries</option>,
        this e.g. has the advantage of providing desktop entries and icons.
        However, you should be careful about using these packages'
        libraries as they will not be wrapped. Note also that applications may
        not be firejailed if invoked via a desktop file that specifies an
        absolute path to the unwrapped binary.
      '';
    };
  };

  config = mkIf cfg.enable {
    security.wrappers.firejail.source = "${lib.getBin pkgs.firejail}/bin/firejail";

    environment.systemPackages = [ pkgs.firejail ] ++ [ wrappedBins ] ++ wrappedPkgs;
  };

  meta.maintainers = with maintainers; [ peterhoeg ];
}
