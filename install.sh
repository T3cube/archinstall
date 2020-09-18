#! /bin/bash
#built by T3cube with LOTS of help from acrolinux

timedatectl set-ntp true
lsblk -a

echo "enter disk for boot partition"
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
echo "\n are you sure you want to do this? y/n"
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
echo "choose install 1)base install 2)desktop install 3)full install"
read InstallNumber

if [[ $InstallNumber = 1 ]]
then
pacstrap /mnt base base-devel linux linux-firmware nano networkmanager grub efibootmgr bash-completion xorg-server xorg-apps xorg-xinit xterm xf86-video-amdgpu mesa vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau git wget
fi

if [[ $InstallNumber = 2 ]]
then
pacstrap /mnt base base-devel linux linux-firmware nano networkmanager grub efibootmgr bash-completion xorg-server xorg-apps xorg-xinit xterm xf86-video-amdgpu mesa vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings plasma-meta kde-applications-meta git wget
fi

if [[ $InstallNumber = 3 ]]
then
pacstrap /mnt base base-devel linux linux-firmware nano networkmanager grub efibootmgr bash-completion xorg-server xorg-apps xorg-xinit xterm xf86-video-amdgpu mesa vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings plasma-meta kde-applications-meta atom audacity barrier barrier-headless bashtop blender chromium codeblocks darktable desmume discord dolphin-emu firefox firejail fish filelight gimp git jre8-openjdk jre8-openjdk-headless mupen64plus nmap notepadqq obs-studio ppsspp python screenfetch shotcut steam syncthing tor wine whois wireshark-qt wget
fi

echo "generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
ln -sf /usr/share/zoneinfo/America/Toronto /etc/localtime
hwclock --systohc
echo "opening nano, choose locals..."
sleep 5s
nano /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "enter hostname"
read Hostname
echo $Hostname > /etc/hostname
printf "127.0.0.1\tlocalhost\n::1\tlocalhost\n127.0.0.1\t$Hostname.local\t$Hostname" > /etc/hosts #\tn doesnt work, need fix
systemctl enable NetworkManager
systemctl enable lightdm.service
echo "set root password" 
passwd

echo "installing grub"
sleep 2s
grub-install --target=x86_64-efi --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg
mkdir -p /boot/efi/EFI/boot
cp /boot/efi/EFI/arch/grubx64.efi /boot/efi/EFI/boot/grubx64.efi

#install helper
echo "downloading yay aur helper. you will need to run makepkg -si when you restart"
sleep 2s
cd /mnt/home
git clone https://aur.archlinux.org/yay.git

#aur packages to download
#downgrade multimc5 timeshift cemu ephoto tkpacman minecraft shutter

if [[ $FilesystemChoice = "ext4" ]]
then
echo "installing bedrock linux hack"
#download and install BRL
wget https://github.com/bedrocklinux/bedrocklinux-userland/releases/download/0.7.17/bedrock-linux-0.7.17-x86_64.sh
sudo bash ./bedrock-linux-0.7.17-x86_64.sh --hijack
sleep 2s
else
echo "skipping bedrock linux install"
sleep 3s
fi

#download and install blackarch
echo "installing blackarch"
sleep 2s
curl -O https://blackarch.org/strap.sh
chmod +x strap.sh
sudo ./strap.sh

echo "set user environment"
echo "enter username"
read username
useradd -m -g users -G audio,video,network,wheel,storage,rfkill -s /bin/bash $username
echo "enter password for $username"
passwd $username
echo "look for %wheel ALL=(ALL)ALL and uncomment the line"
sleep 10s
EDITOR=nano visudo

umount -R /mnt
echo "done installing, restarting in 5 seconds..."
sleep 5s
#reboot