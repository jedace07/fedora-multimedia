# Fedora Multimedia

Simple script for automating the installation of proprietary repos, codecs and drivers. 

## Description

This script will:
- Enable RPMFusion
- Enable proprietary codecs
- Install Nvidia drivers
- Install corresponding hardware codecs

IMPORTANT: This is very much in an alpha "it worked on a vm" state, so unless you know what it does or wanna contribute, you should be careful while running this.
I haven't tested this on any Silverblue or RHEL system, so I can't guarantee that it'll work on those, feel free to raise an issue or commit a patch if you happen to fix it.

### Installing and Running

> git clone https://codeberg.org/jedxyz/fedora-multimedia.git  
> cd ~/fedora-multimedia  
> bash fedora-multimedia.sh  

## License

This project is licensed under the Apache 2.0 License - see the LICENSE file for details
