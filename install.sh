#!/bin/bash
HOME="/home/pi"

function stage1 {
  # SSH Public key
  cd $HOME
  mkdir .ssh
  chmod 700 .ssh
  cd .ssh
  echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAy9gcmm77A0sMith3eRgCx/8p7U40K63ZVGdpWxadhN0bUpNtmE9Ja/xVcbVrHBwDrLQRNMM2IwX5MsSt/bn//vXWAKpGu53SKzgXbC1miFuRvv7/J4qjOeydlxOD/eomHdBCC2dsY7mBmlWoQ3LeQL19Om8qehL2yZNUETq6xpcyZcLivPVcYRgqJbBSDWyoKzhuNKi2gEwFj4P80wE76aJ5mSZBAp5bYZn0u8/5VkEv2FG2s/4bnP3Kykmqhb+RtFAac1pJBo45QUEIgUQJUJ7p2NoOrwrUnV1NDiPc8UlU+mji9Ng97jA3QiXBNJEoe7T8IDx/6rdfIb1LrvMx yaniv@ubuntu" > authorized_keys
  chmod 600 authorized_keys

  # fix locale
  sudo bash -c "sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen"
  sudo locale-gen en_US.UTF-8
  sudo update-locale

  # basic installations
  sudo apt update && sudo apt upgrade -y
  sudo apt install -y vim libqt5multimedia5-plugins libqt5serialport5 libqt5sql5-sqlite libfftw3-* gpsd gpsd-clients python-gps chrony qt5-default libasound2-dev
  sudo apt --fix-broken install -y

  echo -n "Set static IP on the machine? [y/N]: "
  read answer

  if [ $answer == "y" ] || [ $answer == "yes" ]; then
    # Set static IP
    echo -n "Enter desired static IP address: "
    read ip
    sudo tee -a << EOT >> /etc/dhcpcd.conf
interface wlan0

static ip_address=$ip/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1
EOT
  fi

  # Aliases
  echo "alias ll='ls -l'" >> $HOME/.bashrc
  echo "alias vi='vim'" >> $HOME/.bashrc
  source $HOME/.bashrc

  # .bashrc for root user
  sudo rm /root/.bashrc && sudo ln -s $HOME/.bashrc /root/.bashrc

  # Set hostname
  echo -n "Enter desired hostname: "
  read hostname
  sudo hostname $hostname
  sudo bash -c "echo $hostname > /etc/hostname"
  sudo bash -c "sed -i 's/127.0.1.1.*/127.0.1.1       $hostname/g' /etc/hosts"
  sudo bash -c "sed -i 's/^hostname/$hostname/' /etc/dhcpcd.conf"
  sudo hostnamectl set-hostname "$hostname"
  sudo systemctl restart avahi-daemon

  # Upload RPi basic configuration
  scp config.txt radio:/boot/config.txt

  # setup gpsd
  sudo bash -c "sed -i 's/DEVICES=.*/DEVICES=\"\/dev\/ttyACM0\"/g' /etc/default/gpsd"
  sudo bash -c "sed -i 's/GPSD_OPTIONS=.*/GPSD_OPTIONS=\"-n\"/g' /etc/default/gpsd"
  echo "export GPSD_UNITS=metric" >> $HOME/.bashrc

  # setting marker for finished step
  touch $HOME/.1

  echo "It is time to reboot the machine - run me again and I will start from where I stopped"
  echo "rebooting in 10 seconds..."

  sleep 10
  sudo reboot now
}

function stage2 {
  # creating some shortcuts in $HOME
  echo "cgps -s" > $HOME/gps_table && chmod +x $HOME/gps_table
  echo "gpsmon -n" > $HOME/gpsmon && chmod +x $HOME/gpsmon

  # setup chrony sources
  sudo bash -c "sed -i 's/pool.*/# pool 2.debian.pool.ntp.org iburst/' /etc/chrony/chrony.conf"
  sudo bash -c "echo '' >> /etc/chrony/chrony.conf"
  sudo bash -c "echo 'refclock SHM 0 offset 0.5 delay 0.2 refid NMEA' >> /etc/chrony/chrony.conf"

  rm $HOME/.1
  touch $HOME/.2

  echo "It is time to reboot again the machine - run me again and I will start from where I stopped"
  echo "rebooting in 10 seconds..."

  sleep 10
  sudo reboot now
}

function stage3 {
  sudo apt --fix-broken install

  # Set crontab to sync clock every minute
  sudo bash -c "echo '* * * * * root /bin/sh chronyc makestep' >> /etc/cron.d/per_minute"
  
  # Direwofl
  cd $HOME
  git clone https://www.github.com/wb2osz/direwolf
  cd direwolf
  make
  sudo make install
  make install-conf

  # WSJT-X
  WSJTX_VER="2.1.0"
  TEMP_DEB="$(mktemp)" &&
  wget --no-check-certificate -O "$TEMP_DEB" "https://physics.princeton.edu/pulsar/K1JT/wsjtx_${WSJTX_VER}_armhf.deb" &&
  sudo dpkg -i "$TEMP_DEB"
  rm -f "$TEMP_DEB"

  # Install RaspAP
  wget -q https://git.io/voEUQ -O /tmp/raspap && bash /tmp/raspap

  echo "Insatllation finished!"
  rm $HOME/.2
  touch $HOME/.3
}

### Main ###

if [ -f "$HOME/.1" ]; then
  stage2
elif [ -f "$HOME/.2" ]; then
  stage3
elif [ -f "$HOME/.3" ]; then
  echo "no need to run me again"
  exit 0
elif [ ! -f "/home/.ssh/authorized_keys" ]
  stage1
fi

exit 0