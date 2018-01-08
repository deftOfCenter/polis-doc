## Preperation

1. Get a VPS from a provider like DigitalOcean, Vultr, Linode, etc.
   - Recommended VPS size at least 1gb RAM
   - **It must be Ubuntu 16.04 (Xenial)**
2. Make sure you have a transaction of exactly 1000 POLIS in your desktop cold wallet.

## Cold Wallet Setup Part 1

1. Open your wallet on your desktop.

   Click Settings -> Options -> Wallet

   Check "Enable coin control features"

   Check "Show Masternodes Tab"

   Press Ok (you will need to restart the wallet)

   ![Alt text](https://github.com/digitalmine/Guide/blob/master/poliswalletsettings.png "Wallet Settings")


2. Go to the "Tools" -> "Debug console"
3. Run the following command: `masternode genkey`
4. You should see a long key that looks like:
```
3HaYBVUCYjEMeeH1Y4sBGLALQZE1Yc1K64xiqgX37tGBDQL8Xg
```
5. This is your `private key`, keep it safe, do not share with anyone.


## VPS Setup

1. Log into your VPS
   - Windows users [follow this guide](https://www.digitalocean.com/community/tutorials/how-to-log-into-your-droplet-with-putty-for-windows-users) to log into your VPS.

2. The quick and dirty way to get it installed. Type the following and it will automatically install everything for you
````
wget https://raw.githubusercontent.com/deftOfCenter/polis-doc/master/masternode-setup/install_masternode.sh && chmod +x install_masternode.sh && ./install_masternode.sh
````
3. But if you want to know what's up, take some time and go through the next section.

4. **Either way the installation continues below in the Cold Wallet Setup Part 2 section below**

## Create a swap file

1. Build the swap and open fstab
````
  sudo fallocate -l 2G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  sudo nano /etc/fstab
````
2. Add at the end of file
````
  /swapfile none swap sw 0 0
````
3. You don't have to reboot the system for the changes to take effect - the following command will do:
````
  mount -o remount /
````
4. Now run
````
  mount
````
5. Check free disk space and free memory (swap also)
````
  df -h
  free -h
````

## Create a separate user for security

2. For better security, create a new user and give them max permission to run the masternode (root == DANGEROUS)
````
adduser polis1 && adduser polis1 sudo
````   
2. Exit and log back in as the user
````
exit
````
2. Disable root login.  Edit sshd_config
````
sudo nano /etc/ssh/sshd_config
````
2. find and change the `PermitRootLogin` parameter form **yes** to **no**
2. Restart sshd:
````
sudo systemctl restart ssh.service
````

## Additional VPS security (optional, but recommended)

1. Add fail2ban for intrusion protection

````
  sudo apt-get -y install fail2ban
  sudo service fail2ban restart
````
2. Add firewall
````
  sudo apt-get -y install ufw
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow ssh
  sudo ufw allow 24126/tcp
  sudo ufw enable
````

### Setup the polis masternode

2. These will update the system, the add all the dependencies that you will need
```
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install software-properties-common
sudo apt-add-repository -y ppa:bitcoin/bitcoin
sudo apt-get -y update
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
    libminiupnpc-dev \
    build-essential \
    libtool \
    autotools-dev \
    automake \
    pkg-config \
    libssl-dev \
    libevent-dev \
    bsdmainutils \
    libzmq3-dev
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install libdb4.8-dev
sudo apt-get -y install libdb4.8++-dev
````
2. Next grab the polis executable form source and unzip it, and add it to your path
````
wget https://github.com/polispay/polis/releases/download/v1.2.0/poliscore-1.2.0-linux.zip
unzip poliscore-1.2.0-linux.zip
rm poliscore-1.2.0-linux.zip
sudo cp poliscore-1.2.0-linux/usr/local/bin/polis{d,-cli} /usr/local/bin
````
3. Set your privatekey and address variables
````
key=YOUR_PRIVATE_KEY_FROM_ABOVE
ip=YOUR_VPS_IP_ADDRESS
````
3.  Build the configuration file polis.conf
````
cd
mkdir -p ~/.poliscore
rpcuser=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
rpcpassword=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
mkdir -p ~/.poliscore
touch ~/.poliscore/polis.conf
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
' | tee ~/.poliscore/polis.conf
````
2. start up polis
```
polisd -daemon
```
3.  install sentinel to keep your masternode in the loop
```
sudo apt-get -y install virtualenv python-pip
git clone https://github.com/polispay/sentinel ~/sentinel
````
4. Create a virtual environment
````
cd ~/sentinel
virtualenv venv
. venv/bin/activate
```
5. install sentinel requirements
```
pip install -r requirements.txt
```
6. finally update crontab
```
crontab -e
```
7. Hit 2. This will bring up an editor. Paste the following to the bottom.  It goes to your user's home directory and runs sentinel
```
* * * * * cd /home/polis1/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1
```
**NOTE:  If you named your user something other than `polis1` then make sure you give the right directory. use `cd ~/; pwd` to find it if you don't know**

8. CTRL X to save it. Y for yes, then ENTER.

3. Use `watch polis-cli getinfo` to check and wait til it's synced
  (look for blocks number and compare with [the polis block explorer](http://block.polispay.org/) )


## Cold Wallet Setup Part 2

1. On your local machine open your `masternode.conf` file.
   Depending on your operating system you will find it in:
   * Windows: `%APPDATA%\polisCore\`
   * Mac OS: `~/Library/Application Support/polisCore/`
   * Unix/Linux: `~/.poliscore/`

   Leave the file open
2. Go to "Tools" -> "Debug console"
3. Run the following command: `masternode outputs`
4. You should see output like the following if you have a transaction with exactly 1000 POLIS:
```
{
    "12345678xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx": "0"
}
```
5. The value on the left is your `txid` and the right is the `vout`
6. Add a line to the bottom of the already opened `masternode.conf` file using the IP of your
VPS (with port 24126), `private key`, `txid` and `vout`:
```
mn1 1.2.3.4:24126 3xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 12345678xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 0
```
7. Save the file, exit your wallet and reopen your wallet.
8. Go to the "Masternodes" tab
9. Click "Start All"
10. You will see "WATCHDOG_EXPIRED". Just wait few minutes

Congratulations, your setup should now be complete!

Tips appreciated:

Original work
digitalmine: PBNTK2AApqLETnSkL4pNq1XaMjJnTySt8j

Updates
deftOfCenter: PRRCfZM91hZphwp2VCeCAv9zL6F27afjHe
segaz2002
tokayseo

Cheers !
