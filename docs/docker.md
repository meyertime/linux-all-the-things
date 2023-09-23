# Docker

Using Docker on Arch Linux is pretty straight-forward: install the `docker` package, start `docker.service`, and start using it.  However, I don't like the fact that the Docker daemon runs as root and that any user given access to use Docker effectively has root access.  Granted, my user already has root access through `sudo`, but this would allow launching a container with root access to the host without entering a password.  It also defeats some of the purpose of Docker, which is to isolate certain programs from the host system or other isolated programs.  Therefore, I set out to harden Docker a bit.

## Rootless mode

This seems to be the best way to prevent root access to the host.  The Docker daemon is run as an unprivileged user.  Therefore, no container can ever get root access to the host.

This works a little differently than Docker usually works.  Normally, there is a single system Docker daemon running on the host.  However, with rootless, each user has their own Docker daemon.  This further increases security, because users cannot mess with containers run by other users, but you have to keep this in mind when setting things up.  For a regular workstation, it's fine, but for a server, you may want to set up a special user account to run any containers that you want to start at boot.

### Basic setup

1. Install the `docker-rootless-extras-bin` AUR package.
    - I had trouble installing the `rootlesskit` dependency.  I used `rootlesskit-bin` instead.
2. Create `/etc/subuid` and `/etc/subgid` with the contents: `myusername:100000:65536`.  This reserves user and group IDs 100000-165535 on the host for use as user and group IDs 0-65535 in containers.
    - The first number is the beginning of the range on the host to map, and the second number is the number of IDs to map.
    - I assume you'll need a record for each user that is permitted to use Docker, and I assume they will each need a separate range of IDs.
3. Set the environment variable `DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock`.
4. Enable and start the `docker` socket: `systemctl --user enable --now docker.socket`.
    - Note that this only enables Docker for the current user.  To enable it for other users, run the command as that user, or if you have root access: `sudo systemctl --machine=otheruser@.host --user enable --now docker.socket`

### Docker user

As previously mentioned, it may be helpful in some cases to have a Docker daemon start up automatically at boot.  Here's how to do so with a new user called `docker`:

1. Create a `docker` user.  There is already a `docker` group, so give it the same UID if you want.  For example, if the group ID is `966`, and `966` is not already taken by another user, then `sudo useradd -r -m -u 966 -g docker docker`.
3. Edit `/etc/subuid` and `/etc/subgid` and add the line: `docker:100000:65536`.  Adjust the first number so that the range does not overlap with any other users.
4. Enable "lingering" for the `docker` user: `sudo loginctl enable-linger docker`.  Basically this allows services for the `docker` user to start right after boot and continue with no login session.
5. Enable and start the `docker` service: `sudo systemctl --machine=docker@.host --user enable --now docker.socket`

## Private Docker registry

Run as a Docker container:

Set up home directory (/home/docker/registry) with directories auth, certs, and data.

Install `apache-tools` AUR package in order to get `htpasswd` tool.
`htpasswd -B auth/.htpasswd user`

docker run \
    -d \
    --restart always \
    --name registry \
    -p 127.0.0.1:5001:5000 \
    -e REGISTRY_AUTH=htpasswd \
    -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
    -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/.htpasswd \
    -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/meyer-server.crt \
    -e REGISTRY_HTTP_TLS_KEY=/certs/meyer-server.key \
    -e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/data \
    -v /home/docker/registry/auth:/auth \
    -v /home/docker/registry/certs:/certs \
    -v /home/docker/registry/data:/data \
    registry:2

nginx proxy to fix http issue
/etc/nginx/nginx.conf - inside http section:
    server {
        listen 5000 ssl;
        server_name meyer-server;

        ssl_certificate meyer-server.crt;
        ssl_certificate_key meyer-server.key;

        error_page 497 301 =307 https://$host:5000$request_uri;

        location / {
            proxy_pass https://127.0.0.1:5001/;
        }
    }
nginx uses 497 code when an http request is sent to an https server.  we take advantage of that to send a redirect response in that case to force https.