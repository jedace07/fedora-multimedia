<!--
SPDX-FileCopyrightText: 2025 Jed

SPDX-License-Identifier: Apache-2.0
-->

# Fedora Multimedia

Simple script for automating the installation of proprietary repos, codecs and drivers. 

## Description

This script will:
- Enable RPMFusion
- Enable proprietary codecs
- Install Nvidia drivers
- Install corresponding hardware codecs

IMPORTANT: This is very much in an alpha "it worked on a vm" state, so unless you know what it does or wanna contribute, you should be careful while running this. I also haven't tested this on any Silverblue or RHEL system, so I can't guarantee that it'll even work on those.

### Installing and Running

> git clone https://codeberg.org/jedxyz/fedora-multimedia.git  
> cd ~/fedora-multimedia  
> bash fedora-multimedia.sh  

## License

This project is licensed under the Apache 2.0 License - see the LICENSE directory for details
