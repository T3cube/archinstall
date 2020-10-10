#! /bin/bash
#built by T3cube with LOTS of help from acrolinux

timedatectl set-ntp true
lsblk -a

echo "enter disk for boot partition '/dev/xxx'"
read BootPartitionLocation
if [[ "$BootPartitionLocation" != "/dev/sd"[a-z] ]];
then
echo "no partition specified"
exit 1
fi

echo "enter disk for swap partition"
read SwapPartitionLocation
if [[ $SwapPartitionLocation != "/dev/sd"[a-z] ]];
then
echo "no partition specified"
exit 2
fi

echo "enter disk for root partition"
read RootPartitionLocation
if [[ $RootPartitionLocation != "/dev/sd"[a-z] ]];
then
echo "no partition specified"
exit 3
fi

echo "enter disk for home partition"
read HomePartitionLocation
if [[ $HomePartitionLocation != "/dev/sd"[a-z] ]];
then
echo "no partition specified"
exit 4
fi

#efi part no. ef00
#swap part no. 8200
#linux file system part no. 3800

#get desired swap size
echo "pick swap partition size"
echo "1: 1G"
echo "2: 2G"
echo "3: 4G"
echo "4: 8G"
echo "5: 16G"
read SwapPartitionSize
case $SwapPartitionSize in #verify user input for swap size
1)
swapsize="+1G"
;;
2)
swapsize="+2G"
;;
3)
swapsize="+4G"
;;
4)
swapsize="+8G"
;;
5)
swapsize="+16G"
;;
*)
echo "invalid entry" #stop if invalid selection of swap
exit 5
;;
esac

echo "enter size for root partition with +<value>BKMGTP"
read RootPartitionSize

echo "enter size for home partition with +<value>BKMGTP or 0 to use remaining space"
read HomePartitionSize

echo "Do you want to use btrfs snapshots and format in a btrfs file system? You will not be able to use bedrock linux."
echo "If you want to use bedrock linux, ext4 will be used as a file system instead."
echo "ext4/btrfs"
read FilesystemChoice

echo "here are the settings you chose"
echo "disk for boot:" $BootPartitionLocation
echo "disk for swap:" $SwapPartitionLocation
echo "disk for root:" $RootPartitionLocation
echo "disk for Home:" $HomePartitionLocation
echo "swap partition size:" $swapsize
echo "root partition size:" $RootPartitionSize
echo "home partition size:" $HomePartitionSize
echo "file system:" $FilesystemChoice
lsblk -a
printf "\n are you sure you want to do this? y/n"
read ConfirmPartitionSettings
if [[ $ConfirmPartitionSettings = "y" ]]
then
#set partitons
sudo sgdisk -n 0:0:+1G -t 0:ef00 -c 0:efi $BootPartitionLocation
sudo sgdisk -n 0:0:$swapsize -t 0:8200 -c 0:swap $SwapPartitionLocation
sudo sgdisk -n 0:0:$RootPartitionSize -t 0:3800 -c 0:root $RootPartitionLocation
sudo sgdisk -n 0:0:$HomePartitionSize -t 0:3800 -c 0:home $HomePartitionLocation
else
echo "aborted, disks were not altered"
exit 6
fi
lsblk -a

#select, format partitions and mount
echo "input boot partition"
read BootPart
echo "input swap partition"
read SwapPart
echo "input root partition"
read RootPart
echo "input home partition"
read HomePart
mkfs.fat -F32 $BootPart
mkswap $SwapPart
swapon $SwapPart


if [[ $FilesystemChoice = "btrfs" ]]
then
mkfs.btrfs -L "Arch Root" $RootPart
mkfs.btrfs -L "Arch Home" $HomePart
mount $RootPart /mnt
btrfs subvolume create /mnt/@
umount $RootPart
mount $HomePart /mnt
btrfs subvolume create /mnt/@home
umount $HomePart
mount -o compress=lzo,subvol=@,noatime $RootPart /mnt
mkdir -p /mnt/home
mount -o compress=lzo,subvol=@home,noatime $HomePart /mnt/home
elif [[ $FilesystemChoice = "ext4" ]]
then
mkfs.ext4 -L "Arch Root" $RootPart
mkfs.ext4 -L "Arch Home" $HomePart
mount $RootPart /mnt
mkdir -p /mnt/home
mount $HomePart /mnt/home
else
echo "Invalid entry. Exiting..."
exit 7
fi

mkdir -p /mnt/boot/efi
mount $BootPart /mnt/boot/efi

echo "choose mirrors in 5 seconds"
sleep 5s
nano /etc/pacman.d/mirrorlist
echo "uncomment multilib for other libraries"
sleep 5s
nano /etc/pacman.conf

#choost install type
printf "choose install: 1)base install\n2)desktop install\n3)full install\n"
read InstallNumber

if [[ $InstallNumber = 1 ]]
then
pacstrap /mnt base base-devel linux linux-lts linux-headers linux-lts-headers linux-firmware nano xterm networkmanager grub os-prober efibootmgr bash-completion xorg-server xorg-apps xorg-xinit xterm xf86-video-amdgpu mesa vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau git wget fuse bluez bluez-utils tree
fi

if [[ $InstallNumber = 2 ]]
then
pacstrap /mnt base base-devel linux linux-lts linux-headers linux-lts-headers linux-firmware nano xterm networkmanager grub os-prober efibootmgr bash-completion xorg-server xorg-apps xorg-xinit xterm xf86-video-amdgpu mesa vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings plasma-meta konsole dolphin git wget fuse bluez bluez-utils tree
fi

if [[ $InstallNumber = 3 ]]
then
pacstrap /mnt base base-devel linux linux-lts linux-headers linux-lts-headers linux-firmware nano xterm networkmanager grub os-prober efibootmgr bash-completion xorg-server xorg-apps xorg-xinit xterm xf86-video-amdgpu mesa vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings plasma-meta dolphin atom alsa-utils alsa-plugins alsa-oss alsa-firmware sof-firmware alsa-ucm-conf alsa-lib audacity barrier barrier-headless bashtop blender bleachbit bluez bluez-utils chromium codeblocks darktable desmume discord dolphin-emu firefox firejail fish filelight filezilla fuse gimp git gpicview-gtk3 gdk-pixbuf2 jre8-openjdk jre8-openjdk-headless kwallet-pam lutris lightdm-gtk-greeter lightdm-webkit2-greeter mupen64plus nmap notepadqq obs-studio ppsspp python python-py3nvml python-psutil qbittorrent qalculate-gtk acpi_call-lts screenfetch shotcut steam syncthing tor tree wine whois vlc virtualbox virtualbox-host-dkms virtualbox-guest-iso wireshark-qt wget noto-fonts-emoji ttf-joypixels
fi

echo "generating fstab"
sleep 2s
genfstab -U /mnt >> /mnt/etc/fstab

echo "downloadint part 2 to /mnt/"
sleep 1s
curl -O https://raw.githubusercontent.com/T3cube/archinstall/master/install_part_2.sh
mv install_part_2.sh /mnt/
chmod +x /mnt/install_part_2.sh
arch-chroot /mnt
umount -R /mnt
sleep 5s
reboot
