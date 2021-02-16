{ configs, pkgs, ... }:

{
  # install packages specific to X
  environment.systemPackages = with pkgs; [
    # gui utils
    maim
    # cli utils
    xclip xorg.xkill xdotool
  ];

  # keyboard configuration
  # configures with Colemak mods that you specify
  # NOTE: it will cause a lot of local builds
  nixpkgs.config.packageOverrides = super: rec {
    # patch xorg with individual packages
    xorg = super.xorg // rec {
      # XKB files' package. the other patches build upon this
      xkeyboardconfig_colemak_mods = super.xorg.xkeyboardconfig.overrideAttrs (old: rec {
        # download DreymaR's Bag of Keyboard Trix
        kbdTricks = pkgs.fetchFromGitHub {
          owner = "DreymaR";
          repo = "BigBagKbdTrixXKB";
          rev = "f2dd703c5b66aa9fe5d64b982b7fb5cd45a424de";
          sha256 = "165n68ry3fyag4p6w03hzsbzpws8x3hqqb5prkvbmx5ds21c5l5c";
        };

        # specify your desired mods
        mods = "4caw ro ks";

        # actual installation of the mods
        postFixup = ''
          bash ${kbdTricks}/install-dreymar-xmod.sh -nsoc $out/etc/X11 ${mods}
        '';
      });
      # now configure the other packages to use the XKB files from the overriden
      # derivation instead of the official one
      setxkbmap = super.xorg.setxkbmap.overrideAttrs (old: {
        postInstall =
          ''
            mkdir -p $out/share
            ln -sfn ${xkeyboardconfig_colemak_mods}/etc/X11 $out/share/X11
          '';
      });
      xkbcomp = super.xorg.xkbcomp.overrideAttrs (old: {
        configureFlags = "--with-xkb-config-root=${xkeyboardconfig_colemak_mods}/share/X11/xkb";
      });
      xorgserver = super.xorg.xorgserver.overrideAttrs (old: {
        configureFlags = old.configureFlags ++ [
          "--with-xkb-bin-directory=${xkbcomp}/bin"
          "--with-xkb-path=${xkeyboardconfig_colemak_mods}/share/X11/xkb"
        ];
      });
    }; # xorg
    # in order for our patches to work, this also needs to be reconfigured
    xkbvalidate = super.xkbvalidate.override {
      libxkbcommon = super.libxkbcommon.override {
        xkeyboard_config = xorg.xkeyboardconfig_colemak_mods;
      };
    };
  }; # packageOverrides

  # configure X
  services.xserver = {
    enable = true;

    # wanted to add DreymaR's patched xkb files the official way, but it doesn't
    # really work. help is welcome
    #extraLayouts = {
    #  colemak = {
    #    description = "DreymaR's Colemak mods";
    #    languages = [ "eng" ];
    #    symbolsFile = /etc/nixos/xkb/symbols/colemak;
    #    typesFile = /etc/nixos/xkb/types/level5;
    #    geometryFile = /etc/nixos/xkb/geometry/pc;
    #    keycodesFile = /etc/nixos/xkb/keycodes/evdev;
    #  };
    #  ro = {
    #    description = "Romanian modded with Colemak";
    #    languages = [ "rum" ];
    #    symbolsFile = /etc/nixos/xkb/symbols/ro;
    #  };
    #};

    # keyboard config
    layout = "ro";
    xkbModel = "pc105aw-sl";
    xkbOptions = "misc:cmk_curl_dh";
    xkbVariant = "cmk_ed_ks";

    videoDrivers = [ "nvidia" ];

    # display manager setup
    displayManager = {
      defaultSession = "none+bspwm";
      lightdm = {
        background = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;
        greeters.gtk = {
          cursorTheme.name = "Capitaine Cursors";
          cursorTheme.package = pkgs.capitaine-cursors;
          theme.name = "Orchis-red-dark-compact";
          #theme.package = pkgs.orchis;
        };
      };
    };

    windowManager.bspwm.enable = true;

    # disable mouse acceleration
    libinput = {
      enable = true;
      mouse.accelProfile = "flat";
      mouse.accelSpeed = "0";
    };
  };
}
