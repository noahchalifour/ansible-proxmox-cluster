#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then
  ./requirements/install_darwin.sh
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  ./requirements/install_linux.sh
else
  echo "Unsupported OS. Please install sshpass manually."
  exit 1
fi