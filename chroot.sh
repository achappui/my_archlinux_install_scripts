#!/usr/bin/env bash
set -euo pipefail

# ==================================================
# Arch Linux Automated Installer
# --------------------------------------------------
#
# Stage 1: startup.sh
#   - disk partition
#   - pacstrap
#
# Stage 2: chroot.sh
#   - system configuration
#   - packages install
#
# Stage 3: user.sh
#   - user environment
#   - AUR packages
#
# Supported machines:
#   - home_papa
#   - home_maman
#   - home_papa_imac
#
# Author: <me>
# ==================================================

source /root/env.sh
source /root/profile.sh

#Setup basic things
ln -sf /usr/share/zoneinfo/${MY_CLOCK_REGION} /etc/localtime
hwclock --systohc
sed -i "/^#${MY_LOCALE}/s/^#//" /etc/locale.gen
locale-gen
echo "LANG=${MY_LANG}" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
echo ${MY_HOSTNAME} > /etc/hostname
echo "root:${MY_ROOT_PASSWORD}" | chpasswd

#Setup packages and user
sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf

PACMAN_PKGS=(
$(grep -vE '^\s*#|^\s*$' /packages/base.list)
$(grep -vE '^\s*#|^\s*$' /packages/desktops/sway.list)
$(grep -vE '^\s*#|^\s*$' /packages/drivers/${CPU_DRIVERS}.list)
)

if ! echo ${GPU_DRIVERS} | grep -q ".aur"; then
    PACMAN_PKGS+=($(grep -vE '^\s*#|^\s*$' /packages/drivers/${GPU_DRIVERS}.list))
fi

if grep -q ${PROFILE} "papa"; then
    PACMAN_PKGS+=($(grep -vE '^\s*#|^\s*$' /packages/drivers/printer.list))
fi

pacman -Syu --noconfirm --needed "${PACMAN_PKGS[@]}"

useradd -m -G wheel -s /bin/bash ${MY_USER}
echo "${MY_USER}:${MY_USER_PASSWORD}" | chpasswd
sed -i "/^# *%wheel ALL=(ALL:ALL) ALL/s/^# *//" /etc/sudoers
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

sudo -u ${MY_USER} git clone https://aur.archlinux.org/yay.git /home/${MY_USER}/yay
sudo -u ${MY_USER} makepkg -s --noconfirm --needed --dir /home/${MY_USER}/yay
pacman -U --noconfirm --needed /home/${MY_USER}/yay/yay-*.pkg.tar.zst
rm -rf /home/${MY_USER}/yay

AUR_PKGS=(
$(grep -vE '^\s*#|^\s*$' /packages/desktops/sway.aur.list)
)

if echo ${GPU_DRIVERS} | grep -q ".aur"; then
    AUR_PKGS+=($(grep -vE '^\s*#|^\s*$' /packages/drivers/${GPU_DRIVERS}.list))
fi

if grep -q ${PROFILE} "papa"; then
    AUR_PKGS+=($(grep -vE '^\s*#|^\s*$' /packages/drivers/brother-MFC_L8690CDW.aur.list))
fi

sudo -u ${MY_USER} yay -S --noconfirm --needed "${AUR_PKGS[@]}"

sed -i '/%wheel ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers

#Setup cache policies
systemctl enable paccache.timer
paccache -rk1
journalctl --vacuum-size=100M

#Setup network wired and wifi
systemctl enable systemd-networkd systemd-resolved

mkdir -p /etc/systemd/network

MY_WIRED_INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n1)
cat <<EOF > /etc/systemd/network/20-wired.network
[Match]
Name=${MY_WIRED_INTERFACE}

[Network]
DHCP=yes
EOF

if [ -n "${MY_IS_WIFI_SETUP}" ]; then
MY_WIFI_INTERFACE=$(iw dev | awk '$1=="Interface"{print $2}')
mkdir -p /etc/iwd
cat <<'EOF' >> /etc/iwd/main.conf
[General]
EnableNetworkConfiguration=true

[Network]
NameResolvingService=systemd
EOF
mkdir -p /var/lib/iwd
cat <<EOF > /var/lib/iwd/${MY_WIFI_NAME}.psk
[Security]
Passphrase=${MY_WIFI_PASSWORD}
EOF
chmod 600 /var/lib/iwd/${MY_WIFI_NAME}.psk
chown root:root /var/lib/iwd/${MY_WIFI_NAME}.psk
cat <<EOF > /etc/systemd/network/25-wireless.network
[Match]
Name=${MY_WIFI_INTERFACE}

[Network]
DHCP=yes
EOF
if [ -n "${MY_IS_WIFI_ACTIVATED}" ]; then
    systemctl enable iwd
fi

fi

#Setup docker
systemctl enable docker
usermod -aG docker ${MY_USER}
mkdir -p /home/${MY_USER}/.docker-data
mkdir -p /etc/docker/
cat <<EOF >> /etc/docker/daemon.json
{
  "data-root": "/home/${MY_USER}/.docker-data"
}
EOF

#Fix sound parasite
mkdir -p /etc/modprobe.d
echo "options snd_hda_intel power_save=0 power_save_controller=N " > /etc/modprobe.d/audio_disable_autosuspend.conf
#Fix shutdownissue
sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=10s/' /etc/systemd/system.conf

#Setup start after login
echo "/home/${MY_USER}/user.sh" >> /home/${MY_USER}/.bash_profile
echo "export GTK_THEME=Adwaita:dark" >> /home/${MY_USER}/.bash_profile
echo 'if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then' >> /home/${MY_USER}/.bash_profile
if echo ${GPU_DRIVERS} | grep -q "nvidia"; then
    echo 'exec sway --unsupported-gpu' >> /home/${MY_USER}/.bash_profile
else
    echo 'exec sway' >> /home/${MY_USER}/.bash_profile
fi
echo 'fi' >> /home/${MY_USER}/.bash_profile

#Adapt Sway config
for item in "${SWAY_MONITORS[@]}"; do
    echo "$item" >> /home/${MY_USER}/.config/sway/config
done

# Set ownership of user home and configs
chown -R ${MY_USER}:${MY_USER} /home/${MY_USER}

# Set Firewall rules
systemctl enable nftables

cat <<EOF > /etc/nftables.conf
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;

        iif lo accept
        ct state established,related accept

        icmp type echo-request accept
        icmpv6 type echo-request accept
        #Impression + scanne brother
        udp dport 5353 accept
        udp dport 631 accept
        tcp dport 631 accept
        udp dport 54921-54925 accept
    }
    chain forward {
        type filter hook forward priority 0; policy drop;
    }
    chain output {
        type filter hook output priority 0; policy accept;
    }
}
EOF

# Set usb automount with udev and systemd
echo "${MY_USER} ALL=(ALL) NOPASSWD: /usr/bin/umount /media/*" >> /etc/sudoers
echo "${MY_USER} ALL=(ALL) NOPASSWD: /usr/bin/umount /media/*/" >> /etc/sudoers
cat <<EOF > /etc/udev/rules.d/99-usb-mount.rules
ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="partition", ENV{ID_TYPE}=="disk", TAG+="systemd", ENV{SYSTEMD_WANTS}="usb-mount@%k.service"
EOF
udevadm control --reload-rules
udevadm trigger

cat <<EOF > /etc/systemd/system/usb-mount@.service
[Unit]
Description=Automount USB %I
After=dev-%i.device
BindsTo=dev-%i.device

[Service]
Type=oneshot
ExecStart=/usr/local/bin/usb-mount /dev/%I add
ExecStop=/usr/local/bin/usb-mount /dev/%I remove
RemainAfterExit=yes
EOF

# Set up brother printer
if grep -q ${PROFILE} "papa"; then
    systemctl enable cups
    systemctl enable avahi-daemon

    sed -i 's/mymachines /mymachines mdns_minimal [NOTFOUND=return] /' /etc/nsswitch.conf

    PRINTER_URL="dnssd://Brother%20MFC-L8690CDW%20series._ipp._tcp.local/?uuid=e3248000-80ce-11db-8000-3c2af4f5323b"
    lpadmin -p Brother_MFC_L8690CDW \
            -E \
            -v "${PRINTER_URL}" \
            -P /usr/share/cups/model/Brother/brother_mfcl8690cdw_printer_en.ppd
    cupsenable Brother_MFC_L8690CDW
    cupsaccept Brother_MFC_L8690CDW
    lpoptions -d Brother_MFC_L8690CDW
    brsaneconfig4 -a name="Brother_Scanner" model="MFC-L8690CDW" nodename="BRN3C2AF4F5323B.local"
fi

# Install bootloader and generate config
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

#Fix imac auto reboot and power up
if [ "${PROFILE_NAME}" = "home_papa_imac" ]; then
    echo "ARPT" | tee "/proc/acpi/wakeup"
    echo "GIGE" | tee "/proc/acpi/wakeup"
    #echo "XHC1" | tee "/proc/acpi/wakeup"
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&acpi_osi=Darwin reboot=pci /' /etc/default/grub
fi

grub-mkconfig -o /boot/grub/grub.cfg

mkinitcpio -P
