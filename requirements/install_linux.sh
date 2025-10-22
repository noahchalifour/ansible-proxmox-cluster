#!/bin/bash

if command -v apt-get &> /dev/null; then
  install_cmd="apt-get install -y"
elif command -v yum &> /dev/null; then
  install_cmd="yum install -y"
elif command -v dnf &> /dev/null; then
  install_cmd="dnf install -y"
elif command -v pacman &> /dev/null; then
  install_cmd="pacman -S --noconfirm"
else
  echo "Unsupported Linux distribution. Please install sshpass manually."
  exit 1
fi

# Install dependencies
sudo $install_cmd sshpass