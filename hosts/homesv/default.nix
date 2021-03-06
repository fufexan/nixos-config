# home server configuration
{ config, pkgs, inputs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };
  
  # network
  networking = {
    hostName = "homesv";
    interfaces.enp3s0.useDHCP = true;
    interfaces.wlp2s0.useDHCP = true;
    wireless.iwd.enable = true;
  };
  networking.firewall.enable = false;

  users.users = {
    user.isNormalUser = true;
    server = {
      isSystemUser = true;
      group = "server";
      extraGroups = [ "render" ];
    };
  };
}
