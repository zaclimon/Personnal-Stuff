# How to configure PCI passthrough for VFIO on ArchLinux

To be used with the [following guide](https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF).

This VM configuration has 4 vCPU's, 8GB of RAM and was running Windows 10 on running QEMU.

## VFIO configuration

1. Force graphics output to the integrated graphics device in the UEFI.

2. Append "intel_iommu=on" in the kernel command line (cmdline)
   Note: Since we're using systemd-boot, we'll need to append it to /boot/loader/entries/arch.conf

3. Find the GPU in the IOMMU groups using the iommu.sh [script](https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF#Ensuring_that_the_groups_are_valid)

4. Check the vendor-device ID pairs for the GPU and the GPU sound device. Add other devices if necessary.

5. Add the pairs to /etc/modprobe.d/vfio.conf (In this case an Nvidia GTX 1060)
   options vfio-pci ids=10de:1c03,10de:10f1

6. Add the required modules to /etc/mkinitcpio.conf

   ```conf
   MODULES="... vfio vfio_iommu_type1 vfio_pci vfio_virqfd ..."
   ```

7. Recreate the initramfs (mkinitcpio -p linux)

8. Check that the PCI devices are bound by the vfio-pci drivers

## VM initial configuration

9. Install qemu, libvirt, ovmf and virt-manager according to the wiki.

10. Add the OVMF UEFI configuration for Libvirt (`/etc/libvirt/qemu.conf`)

```conf
    nvram = [
  "/usr/share/ovmf/x64/OVMF_CODE.fd:/usr/share/ovmf/x64/OVMF_VARS.fd"
    ]
```

11. Create a new VM based on the required needs.
    * 4 vCPU's
    * 8 GB of RAM
    * One drive containing Windows 10
    * One drive containing [VirtIO drivers](https://fedoraproject.org/wiki/Windows_Virtio_Drivers) for Windows
    * Usage of UEFI instead of BIOS
    * Q35 chipset

**Note**: For better performance, use another parition/storage device for the VM disk(s)

**Note 2**: If NAT can't start at first, install `dnsmasq` and `firewalld` before continuing

12. After creating the VM, add the GPU's PCI devices (GPU + HDMI audio), the USB controller and the Intel chipset onboard audio controller.

13. Install the machine initially (Without any drivers except for VirtIO)

14. Turn off the VM if turned on and adjust the following to the VM's config in order bypass Nvidia'a check when installing the GPU drivers.

```
    <hyperv>
      <vendor_id state='on' value='123456789ab'/>
    </hyperv>
    <kvm>
      <hidden state='on'/>
    </kvm>
```

15. The following configuration was also used as far as CPU pinning was used. Modify to your liking:

```
  <cputune>
    <vcpupin vcpu='0' cpuset='2'/>
    <vcpupin vcpu='1' cpuset='6'/>
    <vcpupin vcpu='2' cpuset='3'/>
    <vcpupin vcpu='3' cpuset='7'/>
</cputune>
...
<cpu mode='custom' match='exact'>
    ...
    <topology sockets='1' cores='2' threads='2'/>
    ...
</cpu>
```

16. Turn on the VM and you should be able to install the GPU drivers.

17. Remove the the default audio interface on the VM

18. Install xorg-xrandr (for display switching on the go)

## Wi-Fi bridged configuration for the virtual machine (Go to 21 if the connection is wired)

19. Install net-tools (Required in order to have the "arp" command)

20. Create a [virtual network](http://unix.stackexchange.com/questions/159191/setup-kvm-on-a-wireless-interface-on-a-laptop-machine) required for wireless bridging (by proxy arp)

**Note**: The address of the subnet in order to avoid conflicts at the beginning was 192.168.5.96/29.

21. Create a new VirtIO NIC pointing to the virtual address. The DHCP of that address will assign it a new address but at first it was 192.168.10.100.

## Wired (Ethernet) bridged configuration for the virtual machine

22. Go to NetworkManager and make it forget the connection

23. Create a new bridge by linking the required Ethernet device on the host. (You might need to use nm-connection-editor if you can't create a bridge from NetworkManager's own interface)

24. In virt-manager, replace the specified interface and point it to the newly created bridge interface name. (For example bridge0 for the "bridge0" bridge)

25. Install Synergy (Version 1.8) on both the host and the guest.

26. Change the VM's name to "Isaac-VM" (For Synergy)

27. Add exceptions to firewall on both the host and the guest for Synergy.

28. Copy `synergy.conf` to `/etc/synergy.conf`

29. Clone the "Personnal-Stuff" repo from [Github](<(https://github.com/zaclimon/Personnal-Stuff)>) to ~/.PersonnalStuff

30. Copy the "qemu" script to /etc/libvirt/hooks (Create the directory if necessary)

31. Restart libvirtd

**Note**: Create an XAuthority file if it doesn't exist

32. Search a Windows related SVG (For the desktop launcher icon. Preferably a post Windows 8 one)

## Launcher creation on Gnome

33. Install gnome-panel in order to create desktop shortcuts

34. Execute the following command. Adjust for the desktop path on the device:
    gnome-desktop-item-edit --create-new ~/Bureau

35. Adjust the launcher based on the following:
    Type: Terminal application
    Name: Win10
    Command: sudo virsh start Win10 (Adjust to the VM name)
    Icon: The icon searched previously

## Launcher creation on Cinnamon

36. Right click and create a new launcher based on the instructions from step 35.
