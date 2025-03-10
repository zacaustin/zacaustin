#!/bin/bash

set -e

LOG_FILE="/var/log/initial_setup.log"
sudo touch $LOG_FILE
sudo chown "$USER":"$USER" "$LOG_FILE"
sudo chmod u+w "$LOG_FILE"
echo "===== Initial Setup (Part 2) Started at $(date) =====" | tee -a "$LOG_FILE"


BANNER_FILE="/etc/motd"
echo "=======================================" | sudo tee $BANNER_FILE > /dev/null
echo "⚠️   System setup is in progress...  ⚠️" | sudo tee -a $BANNER_FILE > /dev/null
echo "Follow progress using the following command:" | sudo tee -a $BANNER_FILE > /dev/null
echo "sudo tail -f $LOG_FILE" | sudo tee -a $BANNER_FILE > /dev/null
echo "=======================================" | sudo tee -a $BANNER_FILE > /dev/null
echo "" | sudo tee -a $BANNER_FILE > /dev/null

# Define location of the variables file
VAR_FILE="/etc/initial_setup_vars"
# Check if the variables file exists
if [ ! -f "$VAR_FILE" ]; then
    echo "Error: Variables file not found!" | tee -a "$LOG_FILE"
    exit 1
fi

# Load variables from the file
while IFS="=" read -r key value; do
    if [[ -n "$key" && -n "$value" ]]; then
        export "$key=$value"
    fi
done < <(grep -v "^#" "$VAR_FILE")

echo "Loaded variables:" | tee -a "$LOG_FILE"
echo "NEW_USER=$NEW_USER" | tee -a "$LOG_FILE"
echo "GITHUB_USERNAME=$GITHUB_USERNAME" | tee -a "$LOG_FILE"
echo "SSH_PORT=$SSH_PORT" | tee -a "$LOG_FILE"
echo "INSTALL_DOCKER=$INSTALL_DOCKER" | tee -a "$LOG_FILE"
echo "INSTALL_NODEJS=$INSTALL_NODEJS" | tee -a "$LOG_FILE"
echo "INSTALL_WEBMIN=$INSTALL_WEBMIN" | tee -a "$LOG_FILE"

# Remove the variables file
sudo rm -f "$VAR_FILE"
echo "Variables file deleted." | tee -a "$LOG_FILE"

# Secure SSH Configuration
SSH_CONFIG="/etc/ssh/sshd_config"
echo "Configuring SSH security settings..." | tee -a "$LOG_FILE"

# Alter SSH Configuration
sudo sed -i "/^Port/s/.*/Port $SSH_PORT/" $SSH_CONFIG
sudo sed -i "/^#Port/s/.*/Port $SSH_PORT/" $SSH_CONFIG
sudo sed -i "/^AddressFamily/s/.*/AddressFamily inet/" $SSH_CONFIG
sudo sed -i "/^#AddressFamily/s/.*/AddressFamily inet/" $SSH_CONFIG
sudo sed -i "/^ListenAddress/s/.*/ListenAddress 0.0.0.0/" $SSH_CONFIG
sudo sed -i "/^#ListenAddress/s/.*/ListenAddress 0.0.0.0/" $SSH_CONFIG
sudo sed -i "/^ListenAddress ::/s/.*/#ListenAddress ::/" $SSH_CONFIG
sudo sed -i "/^PermitRootLogin/s/.*/PermitRootLogin no/" $SSH_CONFIG
sudo sed -i "/^#PermitRootLogin/s/.*/PermitRootLogin no/" $SSH_CONFIG
sudo sed -i "/^PasswordAuthentication/s/.*/PasswordAuthentication no/" $SSH_CONFIG
sudo sed -i "/^#PasswordAuthentication/s/.*/PasswordAuthentication no/" $SSH_CONFIG
sudo sed -i '/^#PermitEmptyPasswords/s/^#//' $SSH_CONFIG
sudo sed -i '/^PermitEmptyPasswords/s/.*/PermitEmptyPasswords no/' $SSH_CONFIG
sudo sed -i '/^#ClientAliveInterval/s/^#//' $SSH_CONFIG
sudo sed -i '/^ClientAliveInterval/s/.*/ClientAliveInterval 600/' $SSH_CONFIG
sudo sed -i '/^#ClientAliveCountMax/s/^#//' $SSH_CONFIG
sudo sed -i '/^ClientAliveCountMax/s/.*/ClientAliveCountMax 0/' $SSH_CONFIG

# Restart SSH service to apply changes
echo "Restarting SSH service..." | tee -a "$LOG_FILE"
sudo systemctl restart ssh
echo "SSH security settings applied." | tee -a "$LOG_FILE"

# Configure UFW
echo "Installing and configuring UFW..." | tee -a "$LOG_FILE"
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow proto tcp from 0.0.0.0/0 to any port $SSH_PORT comment "Allow SSH IPv4 only"
sudo ufw limit ssh comment "Rate-limit SSH to prevent brute-force attacks"
echo "y" | sudo ufw enable
echo "UFW configured and enabled." | tee -a "$LOG_FILE"

# Install and configure Fail2Ban for SSH security
echo "Installing and configuring Fail2Ban..." | tee -a "$LOG_FILE"
sudo apt install fail2ban -y
FAIL2BAN_CONFIG="/etc/fail2ban/jail.local"
echo "[sshd]" | sudo tee $FAIL2BAN_CONFIG > /dev/null
echo "enabled = true" | sudo tee -a $FAIL2BAN_CONFIG > /dev/null
echo "port = $SSH_PORT" | sudo tee -a $FAIL2BAN_CONFIG > /dev/null
echo "filter = sshd" | sudo tee -a $FAIL2BAN_CONFIG > /dev/null
echo "logpath = /var/log/auth.log" | sudo tee -a $FAIL2BAN_CONFIG > /dev/null
echo "maxretry = 5" | sudo tee -a $FAIL2BAN_CONFIG > /dev/null
sudo systemctl restart fail2ban
echo "Fail2Ban configured and restarted." | tee -a "$LOG_FILE"

# Enable automatic security updates
echo "Enabling automatic security updates..." | tee -a "$LOG_FILE"
echo 'unattended-upgrades unattended-upgrades/enable_auto_updates boolean true' | sudo debconf-set-selections
sudo apt install -y unattended-upgrades
sudo sed -i 's|//Unattended-Upgrade::Automatic-Reboot "false";|Unattended-Upgrade::Automatic-Reboot "true";|' /etc/apt/apt.conf.d/50unattended-upgrades
sudo systemctl enable --now unattended-upgrades
echo "Automatic security updates enabled." | tee -a "$LOG_FILE"

# Set Up Automatic Reboots for Kernel Updates
sudo apt install -y needrestart
sudo sed -i 's/^#\$nrconf{restart} =.*/\$nrconf{restart} = "a";/' /etc/needrestart/needrestart.conf

# Enable Systemd Journal Persistent Logging
sudo mkdir -p /var/log/journal
sudo systemctl restart systemd-journald

# Set session timeout to 10 minutes (600 seconds)
echo "Setting session timeout to 10 minutes..." | tee -a "$LOG_FILE"

# Apply timeout for all users and ssh sessions
echo "TMOUT=600" | sudo tee -a /etc/profile.d/session_timeout.sh > /dev/null
echo "export TMOUT" | sudo tee -a /etc/profile.d/session_timeout.sh > /dev/null
sudo chmod +x /etc/profile.d/session_timeout.sh
echo "Session timeout successfully set to 10 minutes." | tee -a "$LOG_FILE"

# NodeJS repository setup
echo "Setting up NodeJS repository..." | tee -a "$LOG_FILE"
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
if [ "$INSTALL_NODEJS" == "yes" ]; then
    echo "Installing NodeJS..." | tee -a "$LOG_FILE"
    sudo apt install -y nodejs
fi

# Webmin repository setup
echo "Setting up Webmin repository..." | tee -a "$LOG_FILE"
curl -fsSL https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repo.sh -o /tmp/webmin-setup-repo.sh
echo "y" | sudo bash /tmp/webmin-setup-repo.sh
if [ "$INSTALL_WEBMIN" == "yes" ]; then
    echo "Installing Webmin..." | tee -a "$LOG_FILE"
    sudo apt install webmin -y --install-recommends
    sudo ufw allow proto tcp from 0.0.0.0/0 to any port 10000 comment "Allow Webmin IPv4 only"
fi

# Docker repository setup
echo "Setting up Docker repository..." | tee -a "$LOG_FILE"
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
if [ "$INSTALL_DOCKER" == "yes" ]; then
    echo "Installing Docker..." | tee -a "$LOG_FILE"
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

echo "Software installation completed." | tee -a "$LOG_FILE"

# Remove the @reboot cron job for Part 2 setup
echo "Removing @reboot cron job for Part 2 setup..." | tee -a "$LOG_FILE"
sudo sed -i "/@reboot root sudo -u $NEW_USER bash \/home\/$NEW_USER\/setup_part2.sh/d" /etc/crontab
echo "Cron job removed." | tee -a "$LOG_FILE"

# Clean up APT
echo "Tidying up APT"
sudo apt update
sudo apt full-upgrade -y
sudo apt autoremove --purge -y
sudo apt clean

# Replace banner with a final message
echo "Cleaning up login banner..." | tee -a "$LOG_FILE"
echo "" | sudo tee /etc/motd > /dev/null
echo "✅ Initial setup completed at $(date)." | sudo tee -a "$BANNER_FILE" > /dev/null
echo "View setup log: $LOG_FILE" | sudo tee -a "$BANNER_FILE" > /dev/null
echo "" | sudo tee -a "$BANNER_FILE" > /dev/null
echo "Setup complete. Reboot if necessary." | tee -a "$LOG_FILE"
