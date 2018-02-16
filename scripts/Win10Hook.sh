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
# Libvirt qemu commands different statuses for hooks are: prepare, start, started, stopped, release
#

VM_NAME="Win10"
CURRENT_MACHINE="$1"
LIBVIRT_COMMAND="$2"
VM_IP_ADDRESS="192.168.5.100"
WLAN_INTERFACE="wlp6s0"
PROXY_ARP_STATUS=$(arp -e | grep "Isaac-VM.localdomain" | grep -c "$WLAN_INTERFACE")
IS_WLAN_PRESENT=$(ip addr | grep -c "$WLAN_INTERFACE")
CPU_CORES=$(cat /proc/cpuinfo | grep -c "processor")

# Variables for PCI-E devices
USB_CONTROLLER_PCI_ID="0000:02:00.0"
ONBOARD_AUDIO_DEVICE_ID="8086 8ca0"
ONBOARD_AUDIO_PCI_ID="0000:00:1b.0"
USB_CONTROLLER_DRIVER_XHCI=$(lspci -s $USB_CONTROLLER_PCI_ID -v | grep "Kernel driver" | grep -c "xhci_hcd")
USB_CONTROLLER_DRIVER_VFIO_PCI=$(lspci -s $USB_CONTROLLER_PCI_ID -v | grep "Kernel driver" | grep -c "vfio-pci")
ONBOARD_AUDIO_DRIVER_SND_HDA_INTEL=$(lspci -s $ONBOARD_AUDIO_PCI_ID -v | grep "Kernel driver" | grep -c "snd_hda_intel")
ONBOARD_AUDIO_DRIVER_VFIO_PCI=$(lspci -s $ONBOARD_AUDIO_PCI_ID -v | grep "Kernel driver" | grep -c "vfio-pci")

# Export stuff required for swapping screens when root
export DISPLAY=:0
export XAUTHORITY=/home/isaac/.Xauthority

if [ "$CURRENT_MACHINE" = "$VM_NAME" ] ; then
    if [ "$LIBVIRT_COMMAND" = "started" ] ; then

        # Enable Proxy arp
        if [[ $IS_WLAN_PRESENT -eq 1 && $PROXY_ARP_STATUS -eq 0 ]] ; then
            arp -i "$WLAN_INTERFACE" -Ds "$VM_IP_ADDRESS" "$WLAN_INTERFACE" pub
        fi

        # Unbind the controller from the XHCI driver and bind it to the vfio-pci one.
        if [ $USB_CONTROLLER_DRIVER_XHCI -eq 1 ] ; then
            echo "$USB_CONTROLLER_PCI_ID > /sys/bus/pci/drivers/xhci_hcd/unbind"
            echo "$USB_CONTROLLER_PCI_ID > /sys/bus/pci/drivers/vfio-pci/bind"
        fi

        # Do the same for the onboard audio controller. We need to register it's id first
        # since it won't get recognized by vfio-pci. Note that we don't need to do this on
        # the USB controller because it is in the same IOMMU group as the GPU's.
        if [ $ONBOARD_AUDIO_DRIVER_SND_HDA_INTEL -eq 1 ] ; then
            echo "$ONBOARD_AUDIO_PCI_ID" > /sys/bus/pci/drivers/snd_hda_intel/unbind
            echo "$ONBOARD_AUDIO_PCI_ID" > /sys/bus/pci/drivers/vfio-pci/bind

            if [ $? -eq 1 ] ; then
                echo "$ONBOARD_AUDIO_DEVICE_ID" > /sys/bus/pci/drivers/vfio-pci/new_id
                echo "$ONBOARD_AUDIO_PCI_ID" > /sys/bus/pci/drivers/vfio-pci/bind
            fi

        fi

        # Change the CPU governors to performance
        for ((i = 0; i < $CPU_CORES; i++)) ; do
            echo "performance" > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor
        done

        # Start the Synergy server and change the default display to the secondary one.
        synergys
        xrandr --output VGA-1 --auto --output HDMI-1 --off
    elif [ "$LIBVIRT_COMMAND" = "stopped" ] ; then

        # Unbind the controller from the vfio-pci driver and bind it to the XHCI one.
        if [ $USB_CONTROLLER_DRIVER_VFIO_PCI -eq 1 ] ; then
            echo "$USB_CONTROLLER_PCI_ID > /sys/bus/pci/drivers/vfio-pci/unbind"
            echo "$USB_CONTROLLER_PCI_ID > /sys/bus/pci/drivers/xhci_hcd/bind"
        fi

        # Do the same for the onboard audio
        if [ $ONBOARD_AUDIO_DRIVER_VFIO_PCI -eq 1 ] ; then
            echo "$ONBOARD_AUDIO_PCI_ID" > /sys/bus/pci/drivers/vfio-pci/unbind
            echo "$ONBOARD_AUDIO_PCI_ID" > /sys/bus/pci/drivers/snd_hda_intel/bind
        fi

        # Change the CPU governors to powersave
        for ((i = 0; i < $CPU_CORES; i++)) ; do
            echo "powersave" > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor
        done

        # Stop Synergy and restore display status
        pkill synergy
        xrandr --output HDMI-1 --auto --output VGA-1 --off
    fi
fi
