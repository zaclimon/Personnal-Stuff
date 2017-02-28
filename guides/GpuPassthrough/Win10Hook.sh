#!/bin/bash
#
# Script to adjust the system for the started VM
# Needs to be used with a libvirt qemu hook
# Tested on libvirt 2.4.0 running on Arch Linux
#
# Note on Proxy Arp:
#
# The ARP requests coming from GUEST_IP_ADDRESS will use the MAC address
# from WLAN_INTERFACE. This way, since the device is within the same network,
# ARP requests are technically from WLAN_INTERFACE but will be transferred
# accorgingdly to the right host using the IP address.
#

VM_NAME="Win10"
CURRENT_MACHINE="$1"
LIBVIRT_COMMAND="$2"
VM_IP_ADDRESS="192.168.5.100"
WLAN_INTERFACE="wlp6s0"
PROXY_ARP_STATUS=$(arp -e | grep "Isaac-VM.localdomain" | grep -c "$WIFI_INTERFACE")

if [ "$CURRENT_MACHINE" = "$VM_NAME" ] ; then
    if [ "$LIBVIRT_COMMAND" = "started" ] ; then

        # Enable Proxy arp if not already
        if [ $PROXY_ARP_STATUS -eq 0 ] ; then
            arp -i "$WLAN_INTERFACE" -Ds "$VM_IP_ADDRESS" "$WLAN_INTERFACE" pub
        fi

        # Start Synergy, change the default display to the secondary one and put some oomph
        synergys
        xrandr --output VGA-1 --auto --output HDMI-1 --off
        amixer set Master 75%
    elif [ "$LIBVIRT_COMMAND" = "stopped" ] ; then

        # Stop Synergy, restore display status and set the volume to a reasonable value
        pkill synergy
        xrandr --output HDMI-1 --auto --output VGA-1 --off
        amixer set Master 25%
    fi
fi