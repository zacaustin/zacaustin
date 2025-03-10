#!/bin/bash

set -e

# Get OS details
OS_NAME=$(lsb_release -is 2>/dev/null || awk -F= '/^NAME/{print $2}' /etc/os-release)
OS_VERSION=$(lsb_release -rs 2>/dev/null || awk -F= '/^VERSION_ID/{print $2}' /etc/os-release)
OS_CODENAME=$(lsb_release -cs 2>/dev/null || awk -F= '/^VERSION_CODENAME/{print $2}' /etc/os-release)

# Define the latest supported versions
LATEST_UBUNTU_VERSION="24.04"  # Update this when a new LTS is tested
LATEST_RPI_VERSION="12"        # Current Debian-based Raspberry Pi OS (Update as needed)

if dpkg --compare-versions "$OS_VERSION" gt "$LATEST_UBUNTU_VERSION"; then
    echo "❌ This script does not support Ubuntu $OS_VERSION. Only versions up to $LATEST_UBUNTU_VERSION are allowed."
    exit 1
fi

if [[ "$OS_NAME" == "Raspbian" || "$OS_NAME" == "Debian" ]]; then
    if dpkg --compare-versions "$OS_VERSION" gt "$LATEST_RPI_VERSION"; then
        echo "❌ This script does not support Raspberry Pi OS (Debian) $OS_VERSION. Only versions up to $LATEST_RPI_VERSION are allowed."
        exit 1
    fi
fi

echo "OS version is supported. Continuing..."

# Function to prompt user until valid input is received
prompt_until_valid() {
    local prompt_message="$1"
    local var_name="$2"
    local validation_pattern="$3"

    while true; do
        read -p "$prompt_message: " input
        if [[ "$input" =~ $validation_pattern ]]; then
            eval "$var_name='$input'"
            break
        else
            echo "❌ Invalid input. Please try again."
        fi
    done
}

echo "Updating APT Lists"
sudo apt update

echo "Uprading installed packages"
sudo apt full-upgrade -y

echo "Removing unused packages"
sudo apt autoremove --purge -y

echo "Cleaning up APT"
sudo apt clean

# Prompt for a new non-root username
prompt_until_valid "Enter a new non-root username" NEW_USER "^[a-zA-Z0-9_-]+$"

# Create the user and add to sudo group
sudo adduser --gecos "" $NEW_USER
sudo usermod -aG sudo $NEW_USER
echo "User $NEW_USER created and added to sudo group."

# Ensure SSH directory exists for the user
SSH_DIR="/home/$NEW_USER/.ssh"
sudo -u $NEW_USER mkdir -p $SSH_DIR
sudo chmod 700 $SSH_DIR

# Fetch public SSH keys from GitHub and install them
prompt_until_valid "Enter your GitHub username" GITHUB_USERNAME "^[a-zA-Z0-9-]+$"
echo "Fetching SSH keys for $NEW_USER from GitHub ($GITHUB_USERNAME)..."
KEYS=$(curl -s "https://github.com/$GITHUB_USERNAME.keys")
if [[ -z "$KEYS" ]]; then
    echo "❌ No SSH keys found for GitHub user: $GITHUB_USERNAME. Skipping."
else
    echo "$KEYS" | sudo tee "$SSH_DIR/authorized_keys" > /dev/null
    sudo chmod 600 "$SSH_DIR/authorized_keys"
    sudo chown -R $NEW_USER:$NEW_USER $SSH_DIR
    echo "SSH keys installed for $NEW_USER."
fi

# Prompt for SSH Port
read -p "Enter the SSH port you want to use (default 22): " SSH_PORT
SSH_PORT=${SSH_PORT:-22}
if (( SSH_PORT < 1 || SSH_PORT > 65535 )); then
    echo "❌ Invalid port. Must be between 1-65535."
    exit 1
fi

# Prompt for additional installations
prompt_until_valid "Install Webmin? (yes/no)" INSTALL_WEBMIN "^(yes|no)$"
prompt_until_valid "Install Docker? (yes/no)" INSTALL_DOCKER "^(yes|no)$"
prompt_until_valid "Install NodeJS? (yes/no)" INSTALL_NODEJS "^(yes|no)$"

# Setup Variables Store
VAR_FILE="/etc/initial_setup_vars"
echo "Saving variables to $VAR_FILE"
echo "NEW_USER=$NEW_USER" | sudo tee $VAR_FILE > /dev/null
echo "GITHUB_USERNAME=$GITHUB_USERNAME" | sudo tee -a $VAR_FILE > /dev/null
echo "SSH_PORT=$SSH_PORT" | sudo tee -a $VAR_FILE > /dev/null
echo "INSTALL_WEBMIN=$INSTALL_WEBMIN" | sudo tee -a $VAR_FILE > /dev/null
echo "INSTALL_DOCKER=$INSTALL_DOCKER" | sudo tee -a $VAR_FILE > /dev/null
echo "INSTALL_NODEJS=$INSTALL_NODEJS" | sudo tee -a $VAR_FILE > /dev/null

# Download Part 2 of the script
PART2_SCRIPT="/root/setup_part2.sh"
PART2_URL="https://raw.githubusercontent.com/zacaustin/zacaustin/main/scripts/setup_part2.sh"
echo "Downloading part 2 script from $PART2_URL..."
if ! sudo curl -o $PART2_SCRIPT $PART2_URL; then
    echo "❌ Failed to download Part 2 script. Exiting."
    exit 1
fi
sudo chmod +x $PART2_SCRIPT

# Set up the part 2 script
echo "Setting up part 2 to run on next boot..."
if ! sudo crontab -u root -l 2>/dev/null | grep -q "$PART2_SCRIPT"; then
    (sudo crontab -u root -l 2>/dev/null; echo "@reboot /bin/bash $PART2_SCRIPT >> /var/log/setup.log 2>&1") | sudo crontab -u root -
    echo "Cron job added successfully."
else
    echo "Cron job already exists. Skipping."
fi

# Reboot the system
echo "Rebooting the system in 3 seconds..."
sleep 3
sudo reboot
