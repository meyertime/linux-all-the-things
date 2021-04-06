# Firewall

As always, do at your own risk.  This documentation is provided in good faith, but with no warranty.  (See [LICENSE](../LICENSE).)

Another disclaimer: I have since switched to using `nftables` instead of `iptables`, but I am committing this documentation anyway for historical reasons.

## Overview

Although Linux in general is secure, it doesn't hurt to have multiple layers of security.  A firewall can help prevent unwanted access if all else fails.  As a professional software engineer, we do this for our servers in the cloud as a matter of course, for example, even though they will only be running the software that we install.

Arch Linux follows the principle of simplicity, and so it does not come with any firewall by default unless you set one up.  Well, that's not exactly true.  The Linux kernel comes with firewall capability built-in called "netfilter".  It is usually configured using `iptables` which is probably already installed.  However, no filtering rules are enabled by default.

This document will cover setting up a simple firewall and some of the typical rules you might need.  It will cover the following use cases: typical user workstation, developer workstation, and home server.

## Disable IPv6

First things first, let's disable IPv6.  Why?  This is what we call reducing attack surface.  By disabling IPv6, we don't have to worry about filtering it, or anything about it for that matter.  Yes, IPv6 is technically superior to IPv4, and hopefully some day we will have transitioned over to it completely.  However, at the time of this writing, the vast majority of networks are still on IPv4, and chances are great that your internet access is over IPv4, so unless you have set up a LAN using IPv6, you have no need of it at this point.

1. Add the Linux kernel parameter `ipv6.disable=1`.
    1. Edit `/etc/default/grub`.
    1. Find the line that sets `GRUB_CMDLINE_LINUX_DEFAULT`.
    1. Add `ipv6.disable=1` within the quotes.  Make sure a space separates it from other kernel parameters.
    1. Regenerate the GRUB configuration with `sudo grub-mkconfig -o /boot/grub/grub.cfg`.
1. Reboot.

## iptables

I'm going to use `iptables`, because it's the most common, and it's been around for a long time.  There is a newer option called `nftables`.

You can play around with `iptables` configuration, and your changes won't be made permanent until you save them.  So if you totally screw up, try restoring the configuration from disk or rebooting.  Make sure your changes work before saving them.  Keep these commands handy:

- Restore: `iptables-restore /etc/iptables/iptables.rules`
- Save: `iptables-save -f /etc/iptables/iptables.rules`

### Chains

In `iptables`, packets are filtered using "chains".  A chain is basically a list of rules that are evaluated in sequential order.  The first rule to match determines what is done with the packet.  In order to optimize performance, you want the chain to be relatively short, and you want more frequently-matched rules to be higher in the list.

However, matching packets can be sent to another chain.  This way, part of the evaluation can be done in one chain, and then the next chain doesn't have to worry about it.  This can further optimize performance.  For example, the `INPUT` chain could send TCP packets to a separate `TCP` chain.  This way, rules in the `TCP` chain won't have to re-evaluate whether it's TCP every time.  Also, non-TCP packets won't have to go through all the TCP rules.

To create a chain, type `iptables -N MY_CHAIN`.

Finally, each built-in chain has a "policy" which determines what to do if no rules match.  By default, the policy for each chain is `ACCEPT`.  User-defined chains do not have a policy; instead, if no rules match, evaluation continues on the original chain.

The following chains are built-in:

- `INPUT` - Packets that are directed to this computer go through this chain.
- `OUTPUT` - Packets that originate from this computer go through this chain.
- `FORWARD` - Packets that do not originate from this computer and are not directed to this computer go through this chain.  Such packets would be forwarded like a network router unless they are filtered out.

Let's make the following user-defined chains for our purposes:

- `INPUT_TCP` - For filtering incoming TCP connections.
- `INPUT_UDP` - For filtering incoming UDP packets.
- `OUTPUT_TCP` - For filtering outgoing TCP connections.
- `OUTPUT_UDP` - For filtering outgoing UDP connections.

### Targets

A target specifies what to do with a packet.  The following are the ones we care about:

- `ACCEPT` - This allows the packet.  More specifically, it takes no action and simply stops processing any further rules, allowing the packet to continue through the network stack.
- `DROP` - This drops the packet.  More specifically, it blocks the packet from any further processing, as if it never happened.
- `REJECT` - This actively rejects the packet.  There are different ways of doing this, but basically it responds so that the other party knows that the connection is closed or the destination is unreachable.

If a rule sends the packet to another chain, it is called a "jump" instead of a target.

## The FORWARD chain

Unless you intend to use the computer as a network router, you want to disable packet forwarding.  Doing so is simple:

1. `iptables -P FORWARD DROP` to change the policy of the `FORWARD` chain to `DROP`.

I actually do plan on using my home server as a router in the future, so I will revisit that later.

## The INPUT chain

First of all, if you are connecting to the computer in question remotely, such as through SSH, you need to be careful not to block your own remote access in the process.  While it's best to do these steps from the computer itself, it is possible to do this without blocking yourself in the process.  Basically, don't change the policy or add any rules that `DROP` or `REJECT` until you have added a rule to `ACCEPT` your remote access.

With that out of the way, make sure you have created the `INPUT_TCP` and `INPUT_UDP` chains above.

```bash
# If you are not logged in remotely, change the policy of the `INPUT` chain to drop:
iptables -P INPUT DROP

# Allow already established connections:
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# If you are logged in remotely, then at this point, in theory, your
# already-established remote connection will not be blocked.  However, if you
# tried to establish a new connection, it would be.

# Allow all loopback traffic:
iptables -A INPUT -i lo -j ACCEPT

# Drop packets with an invalid connection state:
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Allow ICMP echo requests (also known as ping)
iptables -A INPUT -p icmp --icmp-type 8 -m conntrack --ctstate NEW -j ACCEPT

# Send new connections to the appropriate user-defined chain:
iptables -A INPUT -p udp -m conntrack --ctstate NEW -j INPUT_UDP
iptables -A INPUT -p tcp --syn -m conntrack --ctstate NEW -j INPUT_TCP

# If you are logged in remotely, add a rule to allow your remote connection.
# For example, to allow SSH:
iptables -A INPUT_TCP -p tcp --dport 22 -j ACCEPT

# If you are logged in remotely, you can now go back and change the `INPUT` chain policy.

# Reject any TCP or UDP packets that do not match any other rules:
iptables -A INPUT -p udp -j REJECT --reject-with icmp-port-unreachable
iptables -A INPUT -p tcp -j REJECT --reject-with tcp-reset

# Reject all other traffic:
iptables -A INPUT -j REJECT --reject-with icmp-proto-unreachable
```

You can now add specific rules to `INPUT_TCP` and `INPUT_UDP` in order to accept traffic.

## The OUTPUT chain

TODO:

- DHCP
- DNS TCP/UDP 53
- HTTP TCP 80 (local only)
- NTP UDP 123
- HTTPS TCP 443
- ICMP?