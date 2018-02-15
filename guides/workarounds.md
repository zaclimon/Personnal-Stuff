# Configuration setup workarounds

Document containing some issues encountered whilst using ArchLinux.

Last update: Febuary 14th 2018.

## NetworkManager with OpenConnect

When using NetworkManager with OpenConnect might generate this error:

```SIOCSIFMTU: Opération non permise```

This is due to the MTU size of the VPN server being unusual. NetworkManager doesn't seem to have enough permissions to fix the said issue. 

Try the following command and restart the computer after:

```setcap cap_net_admin+ep /usr/bin/openconnect```