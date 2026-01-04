#!/bin/bash

set -e  # Exit on any error

REPO="B-urb/dotfiles"  # Replace with actual repo
BRANCH="main"
TARGET_DIR="$HOME/.dotfiles"

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: '$1' is not installed. Please install it and rerun the script."
        exit 1
    fi
}

# Ensure required tools are installed
check_command curl

# Function to get dotfiles

get_dotfiles() {
    # Clone the repository directly to the target directory
    git clone --single-branch --branch "$BRANCH" --recursive "git@github.com:$REPO.git" "$TARGET_DIR"

    # Optionally, you can run git pull if you want to update it later
    # cd "$TARGET_DIR" && git pull origin "$BRANCH"
}

# Function to install dependencies
install_deps() {
    echo "Installing dependencies..."


    # Detect OS and install
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt &> /dev/null; then
            "$TARGET_DIR/ubuntu/install_software.sh"
        elif command -v pacman &> /dev/null; then
            "$TARGET_DIR/arch/install_software.sh"
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y bitwarden-cli
        elif command -v zypper &> /dev/null; then
            sudo zypper install -y bitwarden-cli
        else
            echo "Unsupported Linux distribution. Please install dependencies manually."
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew bundle --file="$TARGET_DIR/macos/Brewfile"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        "$TARGET_DIR/windows/install_deps.sh"
    else
        echo "Unsupported operating system."
        exit 1
    fi

    # Ensure required scripts exist before execution
    if [[ -f "$TARGET_DIR/install_cargo.sh" ]]; then
        "$TARGET_DIR/install_cargo.sh"
    fi

    if [[ -f "$TARGET_DIR/install" ]]; then
        "$TARGET_DIR/install"
    fi

    if [[ -f "$TARGET_DIR/install_extensions.sh" ]]; then
        "$TARGET_DIR/install_extensions.sh"
    fi
}

# Function to install Bitwarden CLI
install_bw_cli() {
    if command -v bw &> /dev/null; then
        echo "Bitwarden CLI is already installed."
        return
    fi

    echo "Bitwarden CLI not found. Attempting to install..."

    # Detect OS and install
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	sudo snap install bw
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install bitwarden-cli
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        winget install --id Bitwarden.CLI -e
    else
        echo "Unsupported operating system. Please install Bitwarden CLI manually."
        exit 1
    fi
}

install_snap() {
    echo "Checking if Snap is installed..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if ! command -v snap &> /dev/null; then
            echo "Snap not found. Installing Snap..."

            # Install snapd if not already installed
            sudo apt update
            sudo apt install -y snapd

            # Install the snapd snap to ensure we get the latest version
            sudo snap install snapd

            # Install Snap Store (optional, if you want to use the Snap GUI)
            sudo snap install snap-store

            echo "Snap installed successfully!"
        else
            echo "Snap is already installed."
        fi
    else
        echo "Skipping Snap installation on non-Linux systems."
    fi
}

install_git() {
    echo "Checking if git is installed..."

    if ! command -v git &> /dev/null; then
        echo "Git not found. Attempting to install..."

        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if command -v apt &> /dev/null; then
                sudo apt update && sudo apt install -y git
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y git
            elif command -v pacman &> /dev/null; then
                sudo pacman -Sy --noconfirm git
            elif command -v zypper &> /dev/null; then
                sudo zypper install -y git
            else
                echo "Unsupported Linux distribution. Please install Git manually."
                exit 1
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install git
        elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
            winget install --id Git.Git -e
        else
            echo "Unsupported operating system. Please install Git manually."
            exit 1
        fi
    else
        echo "Git is already installed."
    fi
}

# Ensure BW_SESSION is set
setup_bw_session() {
    if [ -z "$BW_SESSION" ]; then
        echo "BW_SESSION is not set. Logging in..."

        # Prompt for Bitwarden server URL
        echo -n "Enter your Bitwarden server URL (press Enter for official bitwarden.com): " </dev/tty
        read -r BW_SERVER </dev/tty

        # Use official server if empty
        if [ -z "$BW_SERVER" ]; then
            BW_SERVER="https://vault.bitwarden.com"
        fi

        echo "Configuring Bitwarden server: $BW_SERVER"
        bw config server "$BW_SERVER" </dev/null

        # Redirect stdin from terminal for interactive login
        BW_SESSION=$(bw login --raw </dev/tty)
        export BW_SESSION
    fi
}

# Fetch and setup SSH key from Bitwarden
setup_ssh_key() {
    echo "Fetching SSH key from Bitwarden..."

    SSH_KEYS_FOLDER_ID=$(bw list folders --session "$BW_SESSION" 2>/dev/null | \
        jq -r '.[] | select(.name=="dotfiles/ssh-keys") | .id')
    if [ -z "$SSH_KEYS_FOLDER_ID" ] || [ "$SSH_KEYS_FOLDER_ID" = "null" ]; then
        echo "Error: Bitwarden folder 'dotfiles/ssh-keys' not found."
        exit 1
    fi

    SSH_ITEMS_JSON=$(bw list items --folderid "$SSH_KEYS_FOLDER_ID" --session "$BW_SESSION" 2>/dev/null)
    if [ -z "$SSH_ITEMS_JSON" ]; then
        echo "Error: No SSH key items found in Bitwarden."
        exit 1
    fi

    SSH_ITEM_ID=""
    for item_name in "ssh:id_ed25519" "ssh:id_rsa"; do
        SSH_ITEM_ID=$(echo "$SSH_ITEMS_JSON" | jq -r --arg name "$item_name" '.[] | select(.name==$name) | .id' | head -n 1)
        if [ -n "$SSH_ITEM_ID" ] && [ "$SSH_ITEM_ID" != "null" ]; then
            break
        fi
    done

    if [ -z "$SSH_ITEM_ID" ] || [ "$SSH_ITEM_ID" = "null" ]; then
        SSH_ITEM_ID=$(echo "$SSH_ITEMS_JSON" | jq -r '.[] | select(.type==5) | .id' | head -n 1)
    fi

    if [ -z "$SSH_ITEM_ID" ] || [ "$SSH_ITEM_ID" = "null" ]; then
        echo "Error: No SSH key items found in Bitwarden."
        exit 1
    fi

    SSH_ITEM_JSON=$(bw get item "$SSH_ITEM_ID" --session "$BW_SESSION")
    SSH_ITEM_NAME=$(echo "$SSH_ITEM_JSON" | jq -r '.name')
    SSH_KEY_NAME="${SSH_ITEM_NAME#ssh:}"
    SSH_PRIVATE_KEY=$(echo "$SSH_ITEM_JSON" | jq -r '.sshKey.privateKey')
    SSH_PUBLIC_KEY=$(echo "$SSH_ITEM_JSON" | jq -r '.sshKey.publicKey')

    if [ -z "$SSH_PRIVATE_KEY" ] || [ "$SSH_PRIVATE_KEY" = "null" ]; then
        echo "Error: SSH private key not found in Bitwarden item."
        exit 1
    fi

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    SSH_KEY_FILE="$HOME/.ssh/$SSH_KEY_NAME"
    echo "$SSH_PRIVATE_KEY" > "$SSH_KEY_FILE"
    chmod 600 "$SSH_KEY_FILE"

    if [ -n "$SSH_PUBLIC_KEY" ] && [ "$SSH_PUBLIC_KEY" != "null" ]; then
        echo "$SSH_PUBLIC_KEY" > "$SSH_KEY_FILE.pub"
        chmod 644 "$SSH_KEY_FILE.pub"
    fi

    eval "$(ssh-agent -s)"
    ssh-add -D
    ssh-add "$SSH_KEY_FILE"
}

# Execute functions in correct order
install_git
install_snap
install_bw_cli
export PATH=$PATH:/snap/bin
setup_bw_session
setup_ssh_key
get_dotfiles

# Populate secrets from Bitwarden before installing deps
echo "Populating secrets from Bitwarden..."
"$TARGET_DIR/scripts/populate-secrets.sh"

install_deps
