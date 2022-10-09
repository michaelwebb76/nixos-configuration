# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
in
{
  imports =
    [ <nixos-hardware/dell/xps/15-9500/nvidia>
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  boot = {
    kernelModules = [ "uvcvideo" "usbvideo" ];
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      # Use the systemd-boot EFI boot loader.
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    awscli # AWS CLI
    git
    nvidia-offload
    vim
  ];

  nixpkgs.config.allowUnfree = true;

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
#    keyMap = "us";
    useXkbConfig = true; # use xkbOptions in tty.
  };

  fonts = {
    fontDir = { enable = true; };
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      d2coding
      dejavu_fonts
      source-code-pro
      source-sans-pro
      source-serif-pro
      anonymousPro
      corefonts
      fira-code
      fira-mono
      hack-font
      hasklig
      inconsolata
      symbola
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "Fira Mono" ];
        sansSerif = [ "Fira Code" ];
        serif     = [ "Fira Code" ];
      };
    };
  };


  services = {
    gnome.gnome-keyring.enable = true;

    postgresql = {
      enable = true;
      package = pkgs.postgresql_11;
      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
	      host all all 0.0.0.0/0 md5
        host all all ::1/128 trust
      '';
      initialScript = pkgs.writeText "backend-initScript" ''
        CREATE ROLE postgres WITH LOGIN PASSWORD 'postgres' CREATEDB;
        CREATE DATABASE postgres;
        GRANT ALL PRIVILEGES ON DATABASE postgres TO postgres;
      '';
    };

    redis = {
      enable = true;
    };
    memcached = {
      enable = true;
    };

    fprintd.enable = true;

    openssh.enable = true;

    # Enable CUPS to print documents.
    printing.enable = true;
    printing.drivers = [ pkgs.gutenprint ];

    # Enable the X11 windowing system.
    xserver = {
      enable = true;

      desktopManager = {
        gnome.enable = true;
      };

      displayManager = {
        gdm.enable = true;
        gdm.wayland = true;
      };
    };
  };

  # Enable sound.
  sound.enable = true;
  hardware = {
    bluetooth = {
      enable = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      prime = {
        offload.enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
    opengl = {
      driSupport32Bit = true;
      enable = true;
      extraPackages = [
        pkgs.libGL
      ];
      setLdLibraryPath = true;
    };
    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
      support32Bit = true;
    };
  };
  powerManagement.enable = true;

  security.pki.certificateFiles = ["/home/mike/.ssh/nifi-cert.pem"];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.mike = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      _1password
      _1password-gui
      albert
      audacity
      caffeine-ng
      dbeaver
      fira-code
      fira-mono
      firefox
      gnome3.cheese
      gnome3.gnome-power-manager
      gnome3.gnome-shell-extensions
      gnome3.gnome-tweaks
      gnome3.libgnome-keyring
      gnomeExtensions.emoji-selector
      gnomeExtensions.timezones-extension
      google-chrome
      networkmanagerapplet
      nix-direnv
      nss.tools
      pinentry
      slack
      spotify
      vscode
      watchman
    ];
  };

  nix.autoOptimiseStore = true;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs = {
    mtr.enable = true;
    zsh.enable = true;
    sway.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
