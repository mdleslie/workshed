#!/bin/bash
# Workshed Post-Install Verification
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${GREEN}--- Identity Check ---${NC}"
ID_VAL=$(id -u)
if [ "$ID_VAL" == "1026" ]; then
    echo -e "UID: $ID_VAL [OK]"
else
    echo -e "UID: $ID_VAL [FAILED - Should be 1026]"
fi

echo -e "\n${GREEN}--- Mount Check ---${NC}"
if mountpoint -q /mnt/Arkive; then
    echo -e "NAS Arkive: Connected [OK]"
else
    echo -e "NAS Arkive: Not Mounted [CHECK FSTAB]"
fi

echo -e "\n${GREEN}--- Snap Check ---${NC}"
for app in upnote lunatask spotify; do
    if command -v $app &> /dev/null; then
        echo -e "$app: Installed [OK]"
    else
        echo -e "$app: Missing [CHECK LOGS]"
    fi
done

echo -e "\n${GREEN}--- Tool Check ---${NC}"
command -v bun &> /dev/null && echo -e "Bun: [OK]" || echo -e "Bun: [MISSING]"
command -v fastfetch &> /dev/null && echo -e "Fastfetch: [OK]" || echo -e "Fastfetch: [MISSING]"