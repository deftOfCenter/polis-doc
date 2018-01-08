#/bin/bash

version="1.2.0"
user=`whoami`

clear
cd ~
echo "**********************************************************************"
echo "* Ubuntu 16.04 is the recommended opearting system for this install. *"
echo "*                                                                    *"
echo "* This script will install and configure your polis masternode.  *"
echo "**********************************************************************"
echo && echo && echo
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!                                                 !"
echo "! Make sure you double check before hitting enter !"
echo "!                                                 !"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo && echo && echo
sleep 3

# Gather input from user
read -e -p "Masternode Private Key (e.g. 31o6u1Ga4WxFog2b8QP9bQMrfbUtRj2tSk7sZVM9sryvQHamkyM) : " key
if [[ "$key" == "" ]]; then
    echo "WARNING: No private key entered, exiting!!!"
    echo && exit
fi
read -e -p "Server IP Address : " ip
echo && echo "Pressing ENTER will use the default value for the next prompts."
echo && sleep 3
read -e -p "Add swap space? (Recommended) [Y/n] : " add_swap
if [[ ("$add_swap" == "y" || "$add_swap" == "Y" || "$add_swap" == "") ]]; then
    read -e -p "Swap Size [2G] : " swap_size
    if [[ "$swap_size" == "" ]]; then
        swap_size="2G"
    fi
fi
read -e -p "Install Fail2ban? (Recommended) [Y/n] : " install_fail2ban
read -e -p "Install UFW and configure ports? (Recommended) [Y/n] : " UFW

# Add swap if needed
if [[ ("$add_swap" == "y" || "$add_swap" == "Y" || "$add_swap" == "") ]]; then
    if [ ! -f /swapfile ]; then
        echo && echo "Adding swap space..."
        sleep 3
        sudo fallocate -l $swap_size /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
        sudo sysctl vm.swappiness=10
        sudo sysctl vm.vfs_cache_pressure=50
        echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
        echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
    else
        echo && echo "WARNING: Swap file detected, skipping add swap!"
        sleep 3
    fi
fi

# Update system
echo && echo "Upgrading system..."
sleep 3
sudo apt-get -y update
sudo apt-get -y upgrade

# Add Berkely PPA
echo && echo "Installing bitcoin PPA..."
sleep 3
sudo apt-get -y install software-properties-common
sudo apt-add-repository -y ppa:bitcoin/bitcoin
sudo apt-get -y update

# Install required packages
echo && echo "Installing base packages..."
sleep 3
sudo apt-get -y install \
    wget \
    git \
    unzip \
    libevent-dev \
    libboost-dev \
    libboost-chrono-dev \
    libboost-filesystem-dev \
    libboost-program-options-dev \
    libboost-system-dev \
    libboost-test-dev \
    libboost-thread-dev \
    libdb4.8-dev \
    libdb4.8++-dev \
    libminiupnpc-dev \
    build-essential \
    libtool \
    autotools-dev \
    automake \
    pkg-config \
    libssl-dev \
    libevent-dev \
    bsdmainutils \
    libzmq3-dev \
    nano

# Install fail2ban if needed
if [[ ("$install_fail2ban" == "y" || "$install_fail2ban" == "Y" || "$install_fail2ban" == "") ]]; then
    echo && echo "Installing fail2ban..."
    sleep 3
    sudo apt-get -y install fail2ban
    sudo service fail2ban restart
fi

# Install firewall if needed
if [[ ("$UFW" == "y" || "$UFW" == "Y" || "$UFW" == "") ]]; then
    echo && echo "Installing UFW..."
    sleep 3
    sudo apt-get -y install ufw
    echo && echo "Configuring UFW..."
    sleep 3
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 24126/tcp
    echo "y" | sudo ufw enable
    echo && echo "Firewall installed and enabled!"
fi

# Download polis
echo && echo "Downloading ..."
sleep 3
cd
wget https://github.com/polispay/polis/releases/download/v$version/poliscore-$version-linux.zip
unzip poliscore-$version-linux.zip
rm poliscore-$version-linux.zip

# Install polis
echo && echo "Installing poliscore-$version..."
sleep 3
cd
sudo mv poliscore-$version-linux/usr/local/bin/polis{d,-cli} /usr/local/bin

# Create config for poliscore
echo && echo "Configuring poliscore-$version..."
sleep 3
cd
rpcuser=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
rpcpassword=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
mkdir -p .poliscore
touch .poliscore/polis.conf
echo '
rpcuser='$rpcuser'
rpcpassword='$rpcpassword'
rpcallowip=127.0.0.1
listen=1
server=1
logtimestamps=1
maxconnections=256
externalip='$ip'
masternodeprivkey='$key'
masternode=1
connect=35.227.49.86:24126
connect=192.243.103.182:24126
connect=185.153.231.146:24126
connect=91.223.147.100:24126
connect=96.43.143.93:24126
connect=104.236.147.210:24126
connect=159.89.137.114:24126
connect=159.89.139.41:24126
connect=174.138.70.155:24126
connect=174.138.70.16:24126
connect=45.55.247.25:24126
' | tee /home/$user/.poliscore/polis.conf

# Setup systemd service
echo && echo "Starting polis deamon..."
sleep 3
polis -daemon

# Download and install sentinel
echo && echo "Installing Sentinel..."
sleep 3
cd
sudo apt-get -y install virtualenv python-pip
sudo git clone https://github.com/polispay/sentinel
cd sentinel
virtualenv venv
. venv/bin/activate
pip install -r requirements.txt
export EDITOR=nano
(crontab -l -u $user 2>/dev/null; echo '* * * * * cd /home/'$user'/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1') | crontab -u $user -

# Add alias to run polis-cli
echo && echo "Masternode setup complete!"
