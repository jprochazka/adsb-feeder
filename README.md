<img src="http://assets.jacobwall.netdna-cdn.com/adsb-receiver_logo.png" width="468" height="110" />

# The ADS-B Receiver Project :airplane:

This repository contains a set of scripts and files which can be used to setup an ADS-B receiver on a clean installation of a Debian derived operating system. The scripts are executed in order by the main install script depending on the installation options chosen by the user.

**ADS-B Receiver Web Portal Features**

* Saves all flights seen as well as displays a plot for the flight. (advanced)
* Control what is displayed online via a web based administration area.
* A more uniform website site layout that can be easily navigated.
* Web accessible dump1090 and system performance graphs.
* A web accessible live dump1090 map.
* A web accessible live dump978 map.
* A blog which can be used to share your plane tracking experiences with others.
* Informs visitors when specific flights are being tracked by dump1090.
* Easily customize the look of your portal using the template system.


**Web Portal Screenshots**

<img src="http://assets.jacobwall.netdna-cdn.com/adsb-receiver_live_dump1090.png" width="718" height="369" />

<img src="http://assets.jacobwall.netdna-cdn.com/adsb-receiver_performance_graphs.png" width="718" height="640" />

**Please note:** As of February 2016, the scripts do not work when run on an SD card where the current PiAware image was installed. The scripts require a clean installation of a Debian derived operating system.

The ADS-B Receiver Project website is located at https://www.adsbreceiver.net.

### Obtaining And Using This Software

Download the latest ADS-B Receiver Raspbian Jessie Lite image for Raspberry Pi devices.
https://github.com/jprochazka/adsb-receiver/releases/latest

When setting up the portal you will have to choose between a lite or advanced installation. Advanced features adds flight logging and plotting and should only be chosen on devices running a more sturdy data storage solution.

*It is recommended that anyone using a SD card as they storage medium not attempt to use the advanced features.*

#### Manual installations...

    sudo apt-get update
    sudo apt-get install git
    git clone https://github.com/jprochazka/adsb-receiver.git
    cd ~/adsb-receiver
    chmod +x install.sh
    ./install.sh

#### Updating existing installations...

    cd ~/adsb-receiver
    git fetch --all
    git reset --hard origin/master
    ./install.sh

#### Portal setup...

This step pertains to both fresh installations as well as when updating and existing installation. After running the installation scripts you will need to setup the portal by visiting the following web address.

    http://<IP_ADDRESS_OF_YOUR_DEVICE>/install/

Supply the information asked for and submit the form once done to complete the setup.

### What Can Be Installed

At this time the following software can be installed using these scripts.

**Decoders**

* Dump1090 (mutability):  https://github.com/mutability/dump1090
* Dump978:                https://github.com/mutability/dump978

**Site Feeders**

* FlightAware's PiAware:       http://flightaware.com
* Flightradar24 Feeder Client: http://flightradar24.com
* Plane Finder ADS-B Client:   https://planefinder.net
* ADS-B Exchange:              http://adsbexchange.com


### Supported Operating Systems

The scripts and packages have been tested on most Debian Jessie based operating systems.

The scripts are NOT supported on existing PiAware *image based* installations. The PiAware image is still based on Raspbian Wheezey version which is missing some required libraries for dump1090-mutability installation.

### Useful Links

- Website - https://www.adsbreceiver.net/

- Forum - https://www.adsbreceiver.net/forums/

- Wiki - https://github.com/jprochazka/adsb-receiver/wiki

- Changelog - https://github.com/jprochazka/adsb-receiver/blob/master/CHANGELOG.md
