# This configuration file can be safely imported in your system configuration.
{ config, pkgs, lib, ... }:

{
  nixpkgs.overlays = [
    (import ./overlay.nix)
  ];

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_pinebookpro_lts;

  # This list of modules is not entirely minified, but represents
  # a set of modules that is required for the display to work in stage-1.
  # Further minification can be done, but requires trial-and-error mainly.
  boot.initrd.availableKernelModules = lib.mkForce [
    # https://github.com/NixOS/nixpkgs/blob/e544ee88fa4590df75e221e645a03fe157a99e5b/nixos/modules/profiles/all-hardware.nix#L58-L111
    # Most of the following falls into two categories:
    #  - early KMS / early display
    #  - early storage (e.g. USB) support
    "ahci"

    "ata_piix"

    "sata_inic162x" "sata_nv" "sata_promise" "sata_qstor"
    "sata_sil" "sata_sil24" "sata_sis" "sata_svw" "sata_sx4"
    "sata_uli" "sata_via" "sata_vsc"

    "pata_ali" "pata_amd" "pata_artop" "pata_atiixp" "pata_efar"
    "pata_hpt366" "pata_hpt37x" "pata_hpt3x2n" "pata_hpt3x3"
    "pata_it8213" "pata_it821x" "pata_jmicron" "pata_marvell"
    "pata_mpiix" "pata_netcell" "pata_ns87410" "pata_oldpiix"
    "pata_pdc2027x"
    "pata_serverworks" "pata_sil680" "pata_sis"
    "pata_sl82c105" "pata_triflex" "pata_via"

    # SCSI support (incomplete).
    # "3w-9xxx" "3w-xxxx" "aic79xx" "aic7xxx" "arcmsr"

    # USB support, especially for booting from USB CD-ROM
    # drives.
    "uas"

    # SD cards.
    "sdhci_pci"

    # Allows using framebuffer configured by the initial boot firmware
    "simplefb"

    # Rockchip
    "dw-hdmi"
    "dw-mipi-dsi"
    "rockchipdrm"
    "rockchip-rga"
    "phy-rockchip-pcie"
    "pcie-rockchip-host"

    # Misc. uncategorized hardware

    # Used for some platform's integrated displays
    "panel-simple"
    "pwm-bl"

    # Power supply drivers, some platforms need them for USB
    "axp20x-ac-power"
    # "axp20x-battery"
    # "pinctrl-axp209"
    # "mp8859"

    # USB drivers
    # "xhci-pci-renesas"

    # Misc "weak" dependencies
    "analogix-dp"
    # "analogix-anx6345" # For DP or eDP (e.g. integrated display)
  ];
  boot.initrd.kernelModules = [
    # Rockchip modules
    "rockchip_rga"
    "rockchip_saradc"
    "rockchip_thermal"
    "rockchipdrm"

    # GPU/Display modules
    "analogix_dp"
    "cec"
    "drm"
    "drm_kms_helper"
    "dw_hdmi"
    "dw_mipi_dsi"
    "gpu_sched"
    "panel_simple"
    "panfrost"
    "pwm_bl"

    # USB / Type-C related modules
    "fusb302"
    "tcpm"
    "typec"

    # Misc. modules
    "cw2015_battery"
    "gpio_charger"
    "rtc_rk808"
  ];

  boot.kernelParams = [
    # Works around an issue with efifb, U-Boot and RK3399
    "efifb=off"
  ];

  services.udev.extraHwdb = lib.concatStrings [
    # https://gitlab.manjaro.org/manjaro-arm/packages/community/pinebookpro-post-install/blob/master/10-usb-kbd.hwdb
    ''
      evdev:input:b0003v258Ap001E*
        KEYBOARD_KEY_700a5=brightnessdown
        KEYBOARD_KEY_700a6=brightnessup
        KEYBOARD_KEY_70066=sleep 
    ''

    # https://github.com/elementary/os/blob/05a5a931806d4ed8bc90396e9e91b5ac6155d4d4/build-pinebookpro.sh#L253-L257
    # Disable the "keyboard mouse" in libinput. This is reported by the keyboard firmware
    # and is probably a placeholder for a TrackPoint style mouse that doesn't exist
    ''
      evdev:input:b0003v258Ap001Ee0110-e0,1,2,4,k110,111,112,r0,1,am4,lsfw
        ID_INPUT=0
        ID_INPUT_MOUSE=0
    ''
  ];
  
  # https://github.com/elementary/os/blob/05a5a931806d4ed8bc90396e9e91b5ac6155d4d4/build-pinebookpro.sh#L253-L257
  # Mark the keyboard as internal, so that "disable when typing" works for the touchpad
  environment.etc."libinput/local-overrides.quirks".text = ''
    [Pinebook Pro Keyboard]
    MatchUdevType=keyboard
    MatchBus=usb
    MatchVendor=0x258A
    MatchProduct=0x001E
    AttrKeyboardIntegration=internal
  '';

  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [
    pkgs.pinebookpro-ap6256-firmware
  ];
  
  systemd.tmpfiles.rules = [
    # Tweak the minimum frequencies of the GPU and CPU governors to get a bit more performance
    # https://github.com/elementary/os/blob/05a5a931806d4ed8bc90396e9e91b5ac6155d4d4/build-pinebookpro.sh#L288-L294
    "w- /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq - - - - 1200000"
    "w- /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq - - - - 1008000"
    "w- /sys/class/devfreq/ff9a0000.gpu/min_freq - - - - 600000000"
  ];

  # The default powersave makes the wireless connection unusable.
  networking.networkmanager.wifi.powersave = lib.mkDefault false;
}
