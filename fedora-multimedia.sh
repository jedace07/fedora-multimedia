#!/bin/bash

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
  sudo dnf install rpmfusion-nonfree-release-tainted -y
  sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
elif [ "$DISTRO" == "Fedora Silverblue" ]; then
  sudo rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
elif [ "$DISTRO" == "RHEL/CentOS" ]; then
  sudo dnf install --nogpgcheck https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E %rhel).noarch.rpm
  sudo dnf install --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm
  # for RHEL8 , RHEL9 and to RHEL10
  sudo subscription-manager repos --enable "codeready-builder-for-rhel-$(rpm -E %{rhel})-$(uname -m)-rpms"
fi

# Update metadata for graphical app stores
if [ "$DISTRO" == "Fedora" ]; then
  sudo dnf install rpmfusion-\*-appstream-data -y
fi
# Function to get NVIDIA GPU generation
get_nvidia_gpu_generation() {
  GPU_ID=$(lspci -nn | grep -i "VGA" | grep -i "NVIDIA" | head -n 1 | awk '{print $3}' | sed 's/\[//;s/\]//')

  # Turing and newer (RTX 20-series, GTX 16-series, RTX 30-series, RTX 40-series)
  if echo "$GPU_ID" | grep -E '10DE:1F|10DE:21|10DE:22|10DE:23|10DE:24|10DE:25|10DE:26|10DE:27|10DE:28|10DE:29'; then
    echo "Turing_Ampere_Ada"
  # Maxwell and Pascal (GTX 900-series, GTX 10-series)
  elif echo "$GPU_ID" | grep -E '10DE:13|10DE:14|10DE:1B|10DE:1C|10DE:1D|10DE:1E'; then
    echo "Maxwell_Pascal"
  # Kepler (GTX 600-series, GTX 700-series)
  elif echo "$GPU_ID" | grep -E '10DE:0F|10DE:11|10DE:12'; then
    echo "Kepler"
  else
    echo "Unknown"
  fi
}

# Install full/proprietary media codecs
if [ "$DISTRO" == "Fedora" ]; then
  sudo dnf swap ffmpeg-free ffmpeg --allowerasing -y
  sudo dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
fi

# Check and install GPU hardware codecs and NVIDIA drivers
if lspci | grep -i "VGA" | grep -i "NVIDIA"; then
  echo "NVIDIA GPU detected. Installing NVIDIA hardware codecs and drivers..."

  GPU_GENERATION=$(get_nvidia_gpu_generation)

  if [ "$DISTRO" == "Fedora" ]; then

    case "$GPU_GENERATION" in
      "Turing_Ampere_Ada")
        echo "Installing NVIDIA open kernel driver for Turing/Ampere/Ada generation..."
        sudo dnf install akmod-nvidia-open -y
        ;;
      "Maxwell_Pascal")
        echo "Installing latest proprietary NVIDIA driver for Maxwell/Pascal generation..."
        sudo dnf install akmod-nvidia -y
        ;;
      "Kepler")
        echo "Installing NVIDIA legacy 470 driver for Kepler generation..."
        sudo dnf install xorg-x11-drv-nvidia-470xx akmod-nvidia-470xx -y
        ;;
      *)
        echo "Could not determine NVIDIA GPU generation. No driver will be installed."
        ;;
    esac
  fi
fi

# Check and install GPU hardware codecs
if lspci | grep -i "VGA" | grep -i "NVIDIA"; then
  echo "NVIDIA GPU detected. Installing NVIDIA hardware codecs..."
  if [ "$DISTRO" == "Fedora" ]; then
    sudo dnf install libva-nvidia-driver.{i686,x86_64} -y
  fi
elif lspci | grep -i "VGA" | grep -i "AMD"; then
  echo "AMD GPU detected. Installing AMD hardware codecs..."
  if [ "$DISTRO" == "Fedora" ]; then
    sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
    sudo dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y
    sudo dnf swap mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686 -y
    sudo dnf swap mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686 -y
   fi
elif lspci | grep -i "VGA" | grep -i "Intel"; then
  echo "Intel GPU detected. Installing Intel hardware codecs..."
  if [ "$DISTRO" == "Fedora" ]; then
    INTEL_GPU_ID=$(lspci -nn | grep -i "VGA" | grep -i "Intel" | head -n 1 | awk '{print $3}' | sed 's/\[//;s/\]//')

    # Detect Intel GPU generation based on PCI ID ranges
    # Newer generations (Broadwell, Skylake, Kaby Lake, Coffee Lake, Ice Lake, Tiger Lake, Alder Lake, etc.)
    # typically use intel-media-driver.
    # Older generations (Ivy Bridge, Haswell) typically use libva-intel-driver.
    if echo "$INTEL_GPU_ID" | grep -E '8086:0A|8086:16|8086:19|8086:22|8086:3E|8086:3D|8086:59|8086:8A|8086:8C|8086:8D|8086:9A|8086:45|8086:46'; then
      echo "Newer Intel GPU detected (e.g., Broadwell or newer). Installing intel-media-driver."
      sudo dnf install intel-media-driver -y
    # Older generations (e.g., Sandy Bridge, Ivy Bridge, Haswell)
    elif echo "$INTEL_GPU_ID" | grep -E '8086:01|8086:04|8086:08|8086:0C|8086:0D|8086:0E|8086:1E'; then
      echo "Older Intel GPU detected (e.g., Ivy Bridge/Haswell or older). Installing libva-intel-driver."
      sudo dnf install libva-intel-driver -y
    fi
  fi
else
  echo "No supported GPU detected. Hardware codecs will not be installed."
fi

echo "Script completed successfully!"
