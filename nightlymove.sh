#!/bin/bash

#Copy files
sudo cp -r /home/david/Downloads/*.* /mnt/Arkive/old_Software_Cold_Archive/Drop/
sudo cp -r /home/david/dwhelper/*.* /mnt/Arkive/old_Software_Cold_Archive/Drop/
sudo cp -r /home/david/MEGAsync Downloads/*.* /mnt/Arkive/old_Software_Cold_Archive/Drop/

#clean Downloads folder
sudo rm -rf /home/david/Downloads/*.*
sudo rm -rf /home/david/dwhelper/*.*
sudo rm -rf /home/david/'MEGAsync Downloads'/*.*
