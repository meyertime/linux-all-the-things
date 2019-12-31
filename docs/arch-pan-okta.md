# Palo Alto GlobalProtect VPN with Okta authentication

This is probably very specific to my workplace.  However, at least some others have the same setup, because I was able to find resources online that apply to it.

## Installation

1. Install the `openconnect` package.
2. Install the `pan-globalprotect-okta` python script.
    1. There does not appear to be an official package for easy installation, so I'm just going to use git.
    2. Make sure `git` and `python-pip` are installed.  It seems that `python` is already installed from one of the Arch Linux base packages.
    3. Choose a directory to install the script.  A subdirectory named `pan-globalprotect-okta` will be created, so change to the parent directory of your choosing.
        - In order to be accessible to the `nm-openconnect` user, if you plan to integrate with Network Manager later, the location should be accessible to that user, so outside your home directory.  I am using `/usr/local/lib/` currently.
    4. `git clone https://github.com/arthepsy/pan-globalprotect-okta.git`
    5. `pip install requests lxml pyotp` to install dependencies of the script.

## Configure the python script

1. Edit `./pan-globalprotect-okta/gp-okta.conf`.
2. Set `vpn_url` and `okta_url` according to your workplace.
3. Set `username`.
4. Comment out `password` so that it will prompt you for it.
5. Set `totp.okta` and `totp.google` if you wish to do automatic 2-factor authentication.
6. Set `gateway`.  When connecting to the VPN, openconnect may prompt for the gateway to connect to.  Since the script is piping the authentication token into openconnect, it will not be able to receive input from the user.  If you set `gateway`, then the script will also pipe a response to the gateway question.  If you're not sure, leave it blank and continue.  If openconnect has an error along the lines of `fgets (stdin): Resource temporarily unavailable`, look for a prompt with a list of gateways and enter the name of one in the configuration file.
7. Set `openconnect_args` to `--os win --csd-wrapper=hipreport.sh`.  The VPN may not be configured to allow Linux, so `--os win` makes it report that it is Windows.  More on the `--csd-wrapper` option later.
8. By default, `gp-okta.py` will print the command to run openconnect.  If you want it to execute the command instead of simply printing it, set `execute` to `1`.  I found it easier to leave if off for now until I got it working.

## Configure your HIP report

GlobalProtect uses a feature called "Host Integrity Protection" (HIP) to enforce certain policies on the client that is connecting to the VPN.  The idea is that in order to connect to the VPN, your computer has to meet certain requirements such as an encrypted file system, anti-virus software, and up-to-date patches.  I personally feel like this should be a separate concern from actual VPN connectivity.  Having those requirements met does generally increase security, but not for the VPN itself, since the HIP report can be spoofed easily.  It is essentially a very basic "trusted client", [which is fundamentally insecure](https://en.wikipedia.org/wiki/Trusted_client).

Nevertheless, in order for the VPN connectivity to work, a HIP report that satisfies the policies in place will have to be generated and sent to the server after connecting.  Note that some servers will claim to require a HIP report but not actually enforce it, while others may enforce it by blocking access through the VPN without actually preventing the VPN connection or providing any error feedback.  The latter is a bit of a pain, because it won't tell you which policies are not met.

### Get a known good HIP report

The easiest way to get a good HIP report is to take one from a working system.  If you have access to a Windows one, here is how I got it:

1. Open GlobalProtect using the tray icon.
2. Use the gear icon to go to `Settings`.
3. Go to the `Troubleshooting` tab.
4. For `Logging Level` select `Dump`.
5. Click `Start`.
6. Use the tray icon to connect to your VPN.
7. Try to access an internal web page in order to verify that the VPN is working.
8. Disconnect the VPN.
9. Back in settings, click `Stop`.
10. Go to `C:\Program Files\Palo Alto Networks\GlobalProtect\PanGPS.log`.
11. Find the last instance of `<hip-report name="hip-report">` and copy this entire XML tag.  It's pretty long.
12. The log appears to break the output into chunks, so you will have to remove some of the logging junk.  Every so often you will see something like:
    ```
    (T16280) 10/18/19 11:38:58:015 Dump (4847):
    ResponseToClient.txt_output:
    ```
    Remove that junk.  It could be in the middle of a line, so make sure it's valid.
13. You now have a known good HIP report.  However, it will be missing some tags at the beginning and it will have things like dates and IP addresses hard-coded.  But it is working as of now.

### Author your HIP report script

Next, make a copy of the example script included with openconnect located at `/usr/lib/openconnect/hipreport.sh`.  I put mine in the same directory as the `pan-globalprotect-okta` repo for convenience.  If you choose a different location, be sure to edit `gp-okta.conf` accordingly.

Edit the copy of `hipreport.sh` that you made.  The script basically does some calculations and then outputs the XML with a few values substituted.  You will want some combination of this example and script and the known good HIP report you got earlier.

1. You could start by replacing the `<categories>` tag with the one from your known good HIP report.  From there, decide what information to trim out or change.  Be sure to add substitutions for `$IP`, `$IPV6`, `$COMPUTER`, etc. and for dates use `$NOW`, `$DAY`, `$MONTH`, and `$YEAR`.
2. Alternatively, you can just adjust what's there in the script by comparing it to your known good HIP report.
3. Either way, make sure that the tags from the script before `<categories>` are preserved, because for some reason they do not appear in the HIP report printed to the log, but they appear to be necessary.
4. Finally, you may want to use the host ID from the known good HIP report.  The example script uses the value `deadbeef-dead-beef-dead-beefdeadbeef` which may or may not be accepted by the server.  Either way, it looks suspicious.  If you got the known good HIP report from someone else's computer, then you may want to get a HIP report from your computer if possible (even if it doesn't work) to use for unique IDs such as this.

## Set up permissions

Openconnect needs permission to access the network devices.  The easiest way is to just run openconnect as root, but that presents some security concerns.  To do it anyway for testing purposes, for example, just uncomment the line `openconnect_cmd = sudo openconnect` in `gp-okta.conf`.

Options for running it not as root are documented here: https://www.infradead.org/openconnect/nonroot.html

## Test it

1. `./gp-okta.py ./gp-okta.conf` to run the script.
2. If you have not configured it to execute, copy the printed command and run it.

## Integrate with Network Manager

Doing this makes it easy to connect and disconnect with a few simple clicks.  It also solves the problem of having to run it as root.  However, it won't work out-of-the-box because of the extra Okta authentication steps.

1. Install the `networkmanager-openconnect` package.
2. `systemctl restart NetworkManager.service`.
3. Right-click the network tray icon, click `Configure Network Connections`.
4. Use the plus icon to create a new connection.
5. Select `PAN Global Protect (openconnect)` and `Create`.
6. Enter a name and gateway.
    - Note that "gateway" is a bit ambiguous.  In this context it means the DNS host name to connect to.  After connecting to the GlobalProtect VPN server in openconnect, it will ask you for another "gateway" selection which determines which server to establish the VPN connection with after authenticating.
7. The other settings don't really matter.  The only one that is applicable to our VPN setup is the `CSD Wrapper Script`, but in my experience, it does not actually pass this value to openconnect.
8. Click `Save`.
9. Edit the `.nmconnection` file so that the openconnect plugin for NetworkManager thinks it has all the credentials it needs.  If you don't do this, it will display an authentication window when you try to connect, and there is no way to get past this with the Okta authentication in place.
    1. The `.nmconnection` files are located under `/etc/NetworkManager/system-connections/`.  Edit the one for the connection you created.
    2. Set these values under `[vpn]`:
        ```
        cookie-flags=0
        gateway-flags=0
        gwcert-flags=0
        ```
    3. Create a section `[vpn-secrets]` after the `[vpn]` section if it does not already exist.  Set these values under it:
        ```
        cookie=junk
        gateway=my.real.gateway.com
        gwcert=junk
        ```
    4. Save the file.
    5. `systemctl restart NetworkManager.service`
10. Create a wrapper script to replace the `openconnect` binary.
    1. Unfortunately, this is the only way I found to hook into the connection process.  It means that updates to `openconnect` may potentially break things.  A better solution would probably be to enhance the [openconnect plugin for Network Manager](https://github.com/GNOME/NetworkManager-openconnect) to support Okta / SAML authentication.
    2. Note that this will also affect any use of openconnect anywhere anytime.  In my case, this is the only thing I am using openconnect for anyway, so it doesn't matter to me.
    3. Rename `/usr/bin/openconnect` to `openconnect.real`.
    4. Create the wrapper script file `/usr/bin/openconnect.wrapper.sh`.
        - In this repository, [openconnect.wrapper.sh](../src/openconnect.wrapper.sh) is provided.  It takes parameters and standard input from the Network Manager plugin, runs `gp-okta.py`, does some processing, and runs `openconnect.real` with the correct arguments.  It also traps signals and passes them on to openconnect so that it will terminate properly.
        - Make sure it has execute permissions.
        - Edit any variables, such as file paths, as needed.
    5. Create a symbolic link to the wrapper script.
        1. `ln -s /usr/bin/openconnect.wrapper.sh /usr/bin/openconnect`
11. The wrapper script uses `kdialog` to prompt for the password.
    1. Install the `kdialog` package.
    2. `xhost +si:localuser:nm-openconnect` to grant access to the local `nm-openconnect` user to use the X window system.
12. Test it.
    1. Click on the network tray icon.
    2. You should see the VPN connection listed.  Hover over it and click `Connect`.

## Split tunnel

Normally, the VPN will redirect all network traffic over the VPN.  This prevents access to resources on your home network or whatever other network you are connected to.  The solution is split tunneling.

Another reason to do split tunneling is to take full advantage of your local internet speed rather than being limited to the internet speed through the VPN.

There are two parts to this: routing and DNS.

### Split routes

Routes determine where IP packets go.  We want most traffic to stay on your regular network while routing specific subnets through the VPN.

1. Configure the VPN network.
2. Go to the `IPv4` tab.
3. Click the `Routes...` button.
4. Add the subnets you want routed through the VPN.  Here are all private (non-internet) subnets; but you may not want to include all of them depending on your VPN network and home networks:
    ```
    Address      Netmask      Gateway  Metric
    10.0.0.0     255.0.0.0    0.0.0.0  0
    172.16.0.0   255.240.0.0  0.0.0.0  0
    192.168.0.0  255.255.0.0  0.0.0.0  0
    ```
5. Tick `Ignore automatically obtained routes`.
    - The automatic routes may include routing all traffic, or may route too much traffic.
6. Tick `User only for resources on this connection`.
    - If you don't tick this, you may end up with a default route making it possible for other traffic to still end up on the VPN.
7. Click `OK` and `Apply`.
8. You will have to re-edit the `.nmconnection` file as above, since the manual changes will be overwritten.  Restart `NetworkManager.service` afterward.

### Split DNS

This will allow you to lookup host names on all of your networks, not just the VPN.

1. Install `dnsmasq` package.
2. Create the file `/etc/NetworkManager/conf.d/dns.conf` with the content:
    ```
    [main]
    dns=dnsmasq
    ```
3. Restart `NetworkManager.service`.
