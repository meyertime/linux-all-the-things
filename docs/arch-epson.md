# Epson printers on Arch Linux

## Install CUPS

CUPS is an open-source printing system developed by Apple, but it works for other Unix-like operating systems, including Linux.

1. Install `cups` package.
2. `systemctl enable org.cups.cupsd.socket`
3. `systemctl start org.cups.cupsd.socket`

Supposedly, enabling the socket this way will cause the CUPS service not to start until it is called for by an application.  While this is desirable, it does not seem to work for me.  At least trying the web interface http://localhost:631/ does not trigger the service to start.  In that case:

1. `systemctl start org.cups.cupsd.service` to start the service.
2. If you desire to make the change permanent:
    1. `systemctl disable org.cups.cupsd.socket` if you previously enabled it.
    2. `systemctl enable org.cups.cupsd.service`

### Enable printers in system settings

If you're using KDE, install the `print-manager` package.  A `Printers` section will appear in system settings.

## Set up Epson printers

1. Install Epson driver AUR packages.
    - `epson-inkjet-printer-escpr` is needed by older Epson printers, such as the ET-3600.
    - `epson-inkjet-printer-escpr2` is needed by newer Epson printers, such as the ET-3700.
2. `systemctl restart org.cups.cupsd.service`
3. Use http://localhost:631/ web interface to add the printer.
    - With the Epson drivers installed, it should detect it, and the specific printer should be listed when asked to select the model.
    - Sometimes the specific model may not be listed, or specifying a different model may actually work better.  For example:
        - The ET-3600 is not listed, but using ET-4550 seems to work well.
        - The ET-3700 is listed, but for some reason duplex printing does not work; jobs get stuck on "Rendering completed" status.  I have found ET-4760 to work best.
