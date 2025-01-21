#!/bin/bash

# Exit on any error
set -e

echo "Starting installation process..."

# Function to check if a command was successful
check_status() {
    if [ $? -eq 0 ]; then
        echo "✓ $1 completed successfully"
    else
        echo "✗ Error during $1"
        exit 1
    fi
}

# Function to ensure directory exists
ensure_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
    fi
}

# Install oh my bash
echo "Installing Oh-My-Bash..."
cd ~/
# Download the install script but don't execute it directly
curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh -o install-oh-my-bash.sh
# Modify the script to run non-interactively
sed -i 's:${RUNZSH:-yes}:no:g' install-oh-my-bash.sh
# Run the modified script
bash install-oh-my-bash.sh
# Clean up
rm install-oh-my-bash.sh
check_status "Installing Oh-My-Bash"

# Update and install basic packages
echo "Updating system and installing basic packages..."
sudo apt update -y && sudo apt upgrade -y
sudo apt install git curl wget python-is-python3 build-essential xclip -y
check_status "Basic package installation"

# Install GitHub CLI
echo "Installing GitHub CLI..."
type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)
sudo mkdir -p -m 755 /etc/apt/keyrings
out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg
cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh -y
check_status "GitHub CLI installation"

# Install Powerline Fonts
echo "Installing Powerline Fonts..."
git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -rf fonts
check_status "Powerline Fonts installation"

# Install Alacritty dependencies
echo "Installing Alacritty dependencies..."
sudo apt install cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3 -y
check_status "Alacritty dependencies installation"

# Install Rust
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
check_status "Rust installation"

# Install Alacritty
echo "Installing Alacritty..."
cargo install alacritty
sudo cp $HOME/.cargo/bin/alacritty /usr/bin/
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/alacritty 50
check_status "Alacritty installation"

# Create desktop entry for Alacritty
echo "Creating Alacritty desktop entry..."
cat > ~/.local/share/applications/alacritty.desktop << 'EOL'
[Desktop Entry]
Type=Application
TryExec=alacritty
Exec=alacritty
Icon=Alacritty
Terminal=false
Categories=System;TerminalEmulator;

Name=Alacritty
GenericName=Terminal
Comment=A GPU-accelerated terminal emulator
StartupWMClass=Alacritty
Actions=New;

[Desktop Action New]
Name=New Terminal
Exec=alacritty
EOL

# Make the desktop entry executable
chmod +x ~/.local/share/applications/alacritty.desktop
check_status "Alacritty desktop entry creation"

# Configure Alacritty
echo "Configuring Alacritty..."
ensure_dir ~/.config/alacritty
cat > ~/.config/alacritty/alacritty.toml << 'EOL'
[window]
opacity = 0.9
padding.x = 10
padding.y = 10
decorations = "Full"
decorations_theme_variant = "Light" # "Dark"

[font]
normal.family = "Source Code Pro for Powerline"
bold.family = "Source Code Pro for Powerline"
italic.family = "Source Code Pro for Powerline"
bold_italic.family = "Source Code Pro for Powerline"
size = 15.0
EOL
check_status "Alacritty configuration"

# Update desktop database
update-desktop-database ~/.local/share/applications
check_status "Desktop database update"

# Download and install Alacritty icon
echo "Installing Alacritty icon..."
ensure_dir ~/.local/share/icons/
wget -O ~/.local/share/icons/Alacritty.svg https://raw.githubusercontent.com/alacritty/alacritty/master/extra/logo/alacritty-term.svg
check_status "Alacritty icon installation"

# Install latest Neovim
echo "Installing latest Neovim..."
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update
sudo apt install neovim -y
check_status "Neovim installation"

# Configure vim alias
echo "Configuring vim alias..."
if ! grep -q "alias vim=nvim" ~/.bashrc; then
    echo "alias vim=nvim" >> ~/.bashrc
fi
check_status "vim alias configuration"

# Install latest tmux
echo "Installing latest tmux..."
sudo apt install tmux -y
check_status "tmux installation"

# Configure tmux
echo "Configuring tmux..."
cd ~
git clone --single-branch https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
cp .tmux/.tmux.conf.local .
check_status "tmux configuration"

# Install pip3
echo "Installing pip3..."
sudo apt install python3-pip -y
check_status "pip3 installation"

# Install Docker
echo "Installing Docker..."
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
check_status "Docker prerequisites installation"

echo "Adding Docker repository..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
check_status "Docker repository configuration"

echo "Installing Docker CE..."
sudo apt update
sudo apt install -y docker-ce
check_status "Docker CE installation"

echo "Adding user to docker group..."
sudo usermod -aG docker ${USER}
check_status "Docker user configuration"

# Install VSCode
echo "Installing Visual Studio Code..."

# Download and import the Microsoft GPG key
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/packages.microsoft.gpg
rm -f packages.microsoft.gpg

# Add the VS Code repository
echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
    sudo tee /etc/apt/sources.list.d/vscode.list

# Update package cache and install VS Code
sudo apt update
sudo apt install -y code

check_status "VS Code installation"

# Install ROS2 Humble
echo "Installing ROS2 Humble..."
ensure_dir ~/Downloads
cd ~/Downloads
git clone https://github.com/Tiryoh/ros2_setup_scripts_ubuntu.git
cd ros2_setup_scripts_ubuntu
chmod +x ros2-humble-desktop-main.sh
./ros2-humble-desktop-main.sh
check_status "ROS2 Humble installation"

# Install Turtlebot3 dependencies
echo "Installing Turtlebot3 and dependencies..."
sudo apt install -y ros-humble-cartographer
sudo apt install -y ros-humble-cartographer-ros
sudo apt install -y ros-humble-navigation2
sudo apt install -y ros-humble-nav2-bringup
sudo apt install -y ros-humble-turtlebot3*
check_status "Turtlebot3 installation"

# Add ROS2 and development environment to bashrc
echo "Configuring ROS2 environment..."
echo '' >> ~/.bashrc
echo '# ROS2 and development environment' >> ~/.bashrc
echo 'source /opt/ros/humble/setup.bash' >> ~/.bashrc
echo 'source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash' >> ~/.bashrc
echo 'source /usr/share/colcon_cd/function/colcon_cd.sh' >> ~/.bashrc
echo 'export _colcon_cd_root=/opt/ros/humble/' >> ~/.bashrc
echo 'export TURTLEBOT3_MODEL=burger' >> ~/.bashrc
echo 'export GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:/opt/ros/humble/share/turtlebot3_gazebo/models' >> ~/.bashrc
echo 'source $HOME/.cargo/env' >> ~/.bashrc
echo '' >> ~/.bashrc
echo '# Aliases' >> ~/.bashrc
echo 'alias vim=nvim' >> ~/.bashrc
check_status "ROS2 environment configuration"

# Install Python development tools
echo "Installing Python development tools..."
pip install --user pylint yapf isort neovim
check_status "Python development tools installation"

echo "Installation completed successfully!"
echo ""
echo "Important post-installation steps:"
echo "1. Please restart your terminal for all changes to take effect"
echo "2. To set Alacritty as your default terminal, run: sudo update-alternatives --config x-terminal-emulator"
echo "3. You may need to log out and back in for all font changes to take effect"
