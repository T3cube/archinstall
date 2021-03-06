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
systemctl enable bluetooth.service
echo "set root password" 
passwd

echo "installing grub"
sleep 2s
grub-install --target=x86_64-efi --efi-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg
mkdir -p /boot/efi/boot
cp /boot/efi/arch/grubx64.efi /boot/efi/boot/grubx64.efi

#install helper
echo "downloading yay aur helper. you will need to run makepkg -si when you restart"
sleep 2s
cd /home
git clone https://aur.archlinux.org/yay.git
chmod -R 777 yay 

#aur packages to download
#p7zip-gui downgrade multimc5 timeshift cemu ephoto tkpacman minecraft-launcher shutter octopi lutris proton wine winff virtualbox-ext-oracle hyper ttf-twemoji ttf-symbolareboot gns3-gui gns3-server dynmips ubridge python-aiohttp-cors-gns3 python-yarl-gns3

echo "do you want to hack and install bedrock linux? y/n"
read FilesystemChoice
if [[ $FilesystemChoice = "y" ]]
then
echo "downloading bedrock linux. install it after restart"
#download and install BRL
wget https://github.com/bedrocklinux/bedrocklinux-userland/releases/download/0.7.17/bedrock-linux-0.7.17-x86_64.sh
sleep 2s
else
echo "skipping bedrock linux download"
sleep 3s
fi

#download and install blackarch
echo "installing blackarch"
sleep 2s
curl -O https://blackarch.org/strap.sh
chmod +x strap.sh
sudo ./strap.sh
cd

echo "set user environment"
echo "enter username"
read username
useradd -m -g users -G audio,video,network,wheel,storage,rfkill -s /bin/bash $username
echo "enter password for $username"
passwd $username
echo "look for %wheel ALL=(ALL)ALL and uncomment the line"
sleep 10s
EDITOR=nano visudo

echo "done installing, restarting in 5 seconds..."
exit
