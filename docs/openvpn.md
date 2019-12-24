# OpenVPN

## Options

### TAP vs TUN?

TAP works at a lower level (data link, layer 2, Ethernet).  It is bridging and acts like a switch.  TAP behaves like a real network adapter.  It can transport any network protocol.  However, there is more overhead since Ethernet headers on all packets are transported over the VPN.

TUN works at a higher level (network, layer 3, IPv4/IPv6).  It is routing and acts like a router.  It transports only traffic destined for the VPN network.  Broadcast traffic is usually not transported.

On the server side, it seems like TAP is better, because clients can use the same address pool as other clients on the network.

On the client side, it seems like TUN is better, because there is less overhead.  Also, only TUN mode is supported on Android.

### Encryption cipher?

Of the ones available, at least in the drop-down in Tomato, AES seems to be the only one reasonably secure.  Here are my notes about each of them.

#### AES

Established in 2001 by NIST during a selection process.  Supercedes DES.  AES has known performance benefits including hardware acceleration.

#### BF

"Blowfish" designed in 1993 as a successor to DES.  Uses a 64-bit block size, smaller than AES' 128-bit block size.  AES is considered superior.  It is succeeded by Twofish which uses 128-bit block size and was considered in the AES selection process, but did not win.  Twofish was slightly slower than the cipher chosen for AES, and now that AES is hardware accelerated, it is much slower on CPUs that support AES.

#### CAST5

Also known as CAST-128, it has a 64-bit block size and was the predecessor of CAST6, also known as CAST-256, which was considered in the AES selection process but did not win.

#### DES

Developed in 1975, it is an obsolete cipher with a small key length of 56 bits.  It can be broken by brute force and is thus insecure.

#### DESX

Around 1984, it was designed as an improvement of DES, but it is still insecure.

#### IDEA

First described in 1991, it is known to be insecure now.

#### RC2

1987, has known vulnerabilities.

#### RC5

1994, uses a 64-bit block size.  64-bit keys have been brute-forced, with a 72-bit key in progress.  Good implementations of higher key sizes may be secure still.

## Installation

1. Install `openvpn`.

## Certificates

For security reasons, the private key of the certificate authority should never be on a machine that could be compromised, as it can be used to generate authorized client certificates.  The server's private key is also sensitive.  My strategy is to use a USB thumb drive to store the certificate data which can be stored away offline when not needed.

Let's encrypt the USB thumb drive with a password as well.  This will make it 2-factor authentication, since you will need to know the password and have physical access to the thumb drive.  We will use `dm-crypt`, which is built-in to the Linux kernel, and uses a standard `LUKS` format, along with the `cryptsetup` tool for interfacing with `dm-crypt`.  This setup is accessible on Windows using `LibreCrypt`, which is no longer maintained, unfortunately, but I don't plan on using Windows much anyway.

Let's also use FAT32 in order for Windows compatibility.  All the files will be small, so the older file system does not matter.

1. Install `dosfstools` for FAT32 support, if not already installed.
2. `cryptsetup` seems to be included in Arch already, but if it's not available, install it.
3. Connect the USB drive and use `dmesg` to find out the name of the device.  (For example, `sda`)
4. Use `umount` to unmount any partitions that may be mounted.
5. Use `fdisk` to set up partitions on the drive.  Personally, I used DOS partition table, and a smaller partition (100MB is _plenty_ for the certificates) in case I want to create other secure partitions for other purposes later.
6. `sudo cryptsetup luksFormat /dev/sda1`, for example, to encrypt the new partition, assuming that the device is `sda` and it's the first partition.
7. `sudo cryptsetup luksOpen /dev/sda1 luks1` to open the partition.  You will need to provide the passphrase.  This maps it to `/dev/mapper/luks1`.
8. `sudo mkfs.fat -F 32 /dev/mapper/luks1 -n LABEL` to format the encrypted partition in FAT32, choosing a `LABEL`.
9. `sudo cryptsetup luksClose luks1` to close the partition.
10. If you wish to set a label on the encrypted partition which can be seen before mounting it, `sudo cryptsetup config /dev/sda1 --label LABEL`.
10. Test it by disconnecting and reconnecting the USB thumb drive.

### Set up certificate authority

1. Install `easy-rsa`.
2. Choose a directory that resides on the USB thumb drive to use for `easy-rsa`.  Set `EASYRSA` environment variable to this path; for example, `export EASYRSA=/run/media/my_user_name/LABEL`.
3. `cp -r /etc/easy-rsa/* $EASYRSA` to copy initial configuration.
4. Edit `$EASYRSA/vars`.
    - At the time of this writing, `openvpn` does not use a new enough version of `openssl` to support elliptic curve cryptography that uses curves which the NSA did not have a hand in creating.  There is fear in the community that the NSA may have influenced curves to provide them a backdoor, since there is evidence that the NSA has done this in the past.  Therefore, for now, I am using RSA.
    - In order to future-proof it, I am purposely choosing really large key lengths that are probably overkill.  These keys are only used during the authentication process, however, which happens rarely.  It should not slow down actual traffic once connected.
    - First, set the organizational fields:
        ```
        set_var EASYRSA_DN              "org"
        set_var EASYRSA_REQ_COUNTRY     "US"
        set_var EASYRSA_REQ_PROVINCE    "State"
        set_var EASYRSA_REQ_CITY        "City"
        set_var EASYRSA_REQ_ORG         "domain.com"
        set_var EASYRSA_REQ_EMAIL       "user@domain.com"
        set_var EASYRSA_REQ_OU          "unit"
        ```
    - At the time of this writing, a key size of 2048 is considered the minimum.  4096 is considered overkill.  So 8192 is super-overkill, and 16384 is mega-overkill.  I would go with 16384 just for kicks, but I had trouble getting that working in Tomato, so 8192 it is.
        ```
        set_var EASYRSA_KEY_SIZE        8192
        ```
    - I like to set the expire times `EASYRSA_CA_EXPIRE` and `EASYRSA_CERT_EXPIRE` shorter than their defaults.  Personally, I'd rather create a new CA and generate all new certificates every so often as which algorithms and such that are considered secure change over time.
    - Select a secure digest.  `md5` and `sha1` are no longer considered secure.  `sha256`, `sha224`, `sha384`, and `sha512` are all SHA-2 algorithms, and they are considered secure at the time of this writing.  Let's be paranoid and choose the largest key:
        ```
        set_var EASYRSA_DIGEST          sha512
        ```
5. `easyrsa init-pki` to set up a new PKI.  This will also clear any existing PKI stored in the `$EASYRSA` directory.
6. `dd if=/dev/urandom of=$EASYRSA/pki/.rnd bs=256 count=1`
    - For some reason, I get an error that this `.rnd` file does not exist.  Apparently it is supposed to contain 256 bytes of random data.  This command will generate it.i
7. `easyrsa build-ca` builds the new CA including generating the certificate.  This will take a little bit of time if you selected a key size of 16384.  Choose a secure passphrase.  Multiple layers of security are a good thing.

### Diffie-Hellman (DH) parameters file

I'm not an expert about this, but what I do know is that DH parameters involve generating some really big prime numbers.  The larger the key size used, it takes exponentially longer to generate.  It is recommended to use the same key size as the RSA key, but it is possible to use a different size.  Another option is to use the `-dsaparam` flag.  This generates primes without checking if they are so-called "strong" primes, meaning that `2x-1` is also a prime.  There is some question online as to whether or not it is really necessary to use "strong" primes, but OpenSSL recommends rotating DH parameters on a regular basis if `-dsaparam` is used.

In any case, if you use the mega-overkill key size of 16384, it will take a _really_ long time to generate DH parameters.  My best time was about 4 days and 4 hours on an Intel i7 mobile processor.  There are a few options:

- Run it for days and get proper 16384 DH parameters.  After all, how often are you going to do this?  Once every 5-10 years?  Also, since OpenSSL uses only a single thread to generate DH parameters, disable HyperThreading in order to get full use of one of your CPU cores.
- Run multiple instances in parallel, up to the number of CPU cores that you have.  There is an element of chance involved in how long it will take, so if you run more than one instance in parallel, your chances are higher of one finishing sooner.  For example, when I did this, the longest one took 7 days and 17 hours and the shortest 4 days and 4 hours.  You can potentially save a few days of processing this way if you are happy with the first one that finishes and abort the others at that point.
- Use the `-dsaparam` flag, which only took about 7 minutes.  OpenSSL recommends rotating them regularly in this case, so an option would be to write a script to regenerate them automatically every day or week, etc.
- Use a smaller key size, such as 8192, which takes about 7.5 hours.  This could also be rotated on a schedule.  4096 is still considered plenty secure at the time of this writing too.
- You can combine `-dsaparam` with a smaller key size and regular automatic rotation.  If you are performing the regeneration on the OpenVPN server, which may be a small embedded device that does not have as much processing power, you would need a smaller key size and potentially `-dsaparam` to get it to generate within a reasonable amount of time.  As long as it is rotated regularly, however, it will still be plenty secure.  I would recommend using `-dsaparam` in such a case and experimenting to find the largest key size that can be generated within a reasonable time.

Here's the actual command:

```
openssl dhparam -out dh.pem 16384
```

You can also add `-5` to use a somewhat different algorithm (`-2` is the default).  I don't really understand the difference, but according to my research, they are just equivalent but different approaches that probably take the same amount of time.

As mentioned above, `-dsaparam` is another optional parameter.  It saves time by not requiring "strong" primes.

### Hash-based Message Authentication Code (HMAC) key

This is an extra layer of security that prevents the TLS handshake from even happening unless the HMAC key is correct.  It can also protect against port scanning.  OpenVPN will simply drop packets and not respond if the HMAC check fails.

```
openvpn --genkey --secret /run/media/my_user_name/LABEL/ta.key
```

### Generate certificates

Generate a certificate request:

```
easyrsa gen-req serverorclientname nopass
```

Sign it:

- For server certificates:
    ```
    easyrsa sign-req server servername
    ```
- For client certificates:
    ```
    easyrsa sign-req client clientname
    ```

You will want to generate a server certificate for each server instance you intend to use, and a client certificate for each client.

## Configure OpenVPN server

In this case, I am using Tomato firmware which provides a web UI for configuring OpenVPN.  I will simply list the settings to set.

- Under `Basic`:
    - Start with WAN: Checked
    - Interface Type: TAP
        - I may experiment with TUN later because it performs better, but for now, I don't quite want to break Windows file sharing, so I will stick with TAP.
        - It remains to be seen if a server configured with TAP can accept TUN clients, in which case, I would also need to check if TUN would be better on the server side too.
    - Bridge TAP with: LAN (br0)
    - Protocol: TCP
        - UDP may perform better, but TCP pierces through firewalls more easily.
    - Port: 443
        - This is the best port to use if you can.  It is the same port as HTTPS, and practically all firewalls allow it to any target.  OpenVPN traffic also uses the same encryption technology as HTTPS, so the traffic would be difficult to distinguish from actual HTTPS.
    - Firewall: Automatic
        - Not sure about this setting.
    - Authorization Mode: TLS
        - TLS is more secure than a static key.
    - Extra HMAC authorization (tls-auth): Incoming (0)
    - Client address pool: DHCP
        - This makes VPN clients get their IP the same way as any other computer on the network.
- Under `Advanced`:
    - Poll Interval: 0
        - If activated, a service will poll OpenVPN to make sure it's still running and restart it if it's not.  However, I have had it disabled for many moons, and never had a problem.
    - Direct clients to redirect Internet traffic: unchecked
    - Respond to DNS: unchecked
    - Encryption cipher: AES-256-CBC
        - AES is the only algorithm available in the drop-down that is still considered secure.  256 is the largest strength.  The block mode does not seem to matter between the three available ones.
    - Compression: Disabled
        - Compression can potentially make the ecryption easier to break.
    - TLS Renegotiation Time: -1
        - According to the OpenVPN docs, the default is 6 hours, which seems reasonable.
        - This will cause the encryption key to change periodically.  This is good for security.
    - Manage Client-Specific Options: unchecked
    - Allow User/Pass Auth: unchecked
    - Custom Configuration: leave blank
- Under `Keys`:
    - Static Key: contents of `ta.key`
    - Certificate Authority: contents of `ca.crt`
    - Server Certificate: contents of `server.crt`, or whatever you named the server
        - For some reason, the certificate files contain extra data at the beginning.  You only need to put the part that is like this:
            ```
            -----BEGIN CERTIFICATE-----
            ...
            -----END CERTIFICATE-----
            ```
    - Server Key: contents of `server.key`, or whatever you named the server
    - Diffie Hellman parameters: contents of `dh.pem`

If you have trouble saving these settings, I believe it is because the HTTP POST request with really large keys exceeded the maximum request body size, which I'm guessing is 32KB.  I tried to find a work-around to no avail.  A single server with 8192-bit keys works, however.

## Configure OpenVPN client

1. Copy the following files to `/etc/openvpn/client/`:
    - `ca.crt`
    - `client.crt` or whatever you named it
    - `client.key` or whatever you named it
    - `ta.key`
2. Copy example configuration from `/usr/share/openvpn/examples/client.conf` to `/etc/openvpn/client/my-vpn.conf`, or whatever you choose to name it.
3. Edit the contents to match the server settings.
4. Add `auth-nocache` at the end to prevent a warning.
5. Test it with `sudo openvpn /etc/openvpn/client/my-vpn.conf`.

### NetworkManager

At this time, the connection does not work when configured in NetworkManager.  I have yet to find a workaround.
