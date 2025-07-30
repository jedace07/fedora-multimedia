#!/bin/bash

# SPDX-FileCopyrightText: 2025 Jed
#
# SPDX-License-Identifier: Apache-2.0

# Check if the Linux distribution is Fedora, Fedora Silverblue, RHEL, or CentOS
if [ -f /etc/fedora-release ]; then
  DISTRO="Fedora"
elif [ -f /etc/silverblue-release ]; then
  DISTRO="Fedora Silverblue"
elif [ -f /etc/redhat-release ]; then
  DISTRO="RHEL/CentOS"
else
  echo "This script is only compatible with Fedora, Fedora Silverblue, RHEL, or CentOS. Exiting..."
  exit 1
fi

echo "Running on $DISTRO"

# Enable RPMFusion repositories
if [ "$DISTRO" == "Fedora" ]; then
  sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
elif [ "$DISTRO" == "Fedora Silverblue" ]; then
  sudo ostree remote add --no-gpg-verify rpmfusion-free https://download1.rpmfusion.org/free/fedora/repo
  sudo ostree remote add --no-gpg-verify rpmfusion-nonfree https://download1.rpmfusion.org/nonfree/fedora/repo
elif [ "$DISTRO" == "RHEL/CentOS" ]; then
  sudo subscription-manager repos --enable=rpmfusion-free --enable=rpmfusion-nonfree
fi

# Update metadata for graphical app stores
if [ "$DISTRO" == "Fedora" ]; then
  sudo dnf install rpmfusion-\*-appstream-data -y
elif [ "$DISTRO" == "Fedora Silverblue" ]; then
  sudo ostree pull --repo=/ostree/repo rpmfusion-free
  sudo ostree pull --repo=/ostree/repo rpmfusion-nonfree
elif [ "$DISTRO" == "RHEL/CentOS" ]; then
  sudo yum update -y
fi

# Install full/proprietary media codecs
if [ "$DISTRO" == "Fedora" ]; then
  sudo dnf swap ffmpeg-free ffmpeg --allowerasing -y
elif [ "$DISTRO" == "Fedora Silverblue" ]; then
  sudo rpm-ostree install gstreamer1-plugins-ugly gstreamer1-plugins-bad-free gstreamer1-plugins-bad-nonfree gstreamer1-libav
elif [ "$DISTRO" == "RHEL/CentOS" ]; then
  sudo yum install -y gstreamer1-plugins-ugly gstreamer1-plugins-bad-free gstreamer1-plugins-bad-nonfree gstreamer1-libav
fi

# Check and install GPU hardware codecs
if lspci | grep -i "VGA" | grep -i "NVIDIA"; then
  echo "NVIDIA GPU detected. Installing NVIDIA hardware codecs..."
  if [ "$DISTRO" == "Fedora" ]; then
    sudo dnf install -y nvidia-driver-libs-cuda
  elif [ "$DISTRO" == "Fedora Silverblue" ]; then
    sudo rpm-ostree install nvidia-driver-libs-cuda
  elif [ "$DISTRO" == "RHEL/CentOS" ]; then
    sudo yum install -y nvidia-driver-libs-cuda
  fi
elif lspci | grep -i "VGA" | grep -i "AMD"; then
  echo "AMD GPU detected. Installing AMD hardware codecs..."
  if [ "$DISTRO" == "Fedora" ]; then
    sudo dnf install -y libva-mesa-driver
  elif [ "$DISTRO" == "Fedora Silverblue" ]; then
    sudo rpm-ostree install libva-mesa-driver
  elif [ "$DISTRO" == "RHEL/CentOS" ]; then
    sudo yum install -y libva-mesa-driver
  fi
else
  echo "No supported GPU detected. Hardware codecs will not be installed."
fi

echo "Script completed successfully!"
