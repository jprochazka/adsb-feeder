#!/bin/bash

#####################################################################################
#                                  ADS-B RECEIVER                                   #
#####################################################################################
#                                                                                   #
# This script is not meant to be executed directly.                                 #
# Instead execute install.sh to begin the installation process.                     #
#                                                                                   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                                   #
# Copyright (c) 2015-2016 Joseph A. Prochazka                                       #
#                                                                                   #
# Permission is hereby granted, free of charge, to any person obtaining a copy      #
# of this software and associated documentation files (the "Software"), to deal     #
# in the Software without restriction, including without limitation the rights      #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell         #
# copies of the Software, and to permit persons to whom the Software is             #
# furnished to do so, subject to the following conditions:                          #
#                                                                                   #
# The above copyright notice and this permission notice shall be included in all    #
# copies or substantial portions of the Software.                                   #
#                                                                                   #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR        #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,          #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE       #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER            #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,     #
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE     #
# SOFTWARE.                                                                         #
#                                                                                   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

### VARIABLES

RECEIVER_ROOT_DIRECTORY="${PWD}"
RECEIVER_BASH_DIRECTORY="${RECEIVER_ROOT_DIRECTORY}/bash"
RECEIVER_BUILD_DIRECTORY="${RECEIVER_ROOT_DIRECTORY}/build"

# Component specific variables.
COMPONENT_NAME="Dump1090-mutability"
COMPONENT_PACKAGE_NAME="dump1090-mutability"
COMPONENT_WEBSITE="https://github.com/mutability/dump1090"
COMPONENT_GITHUB_URL="https://github.com/mutability/dump1090.git"
COMPONENT_BUILD_DIRECTORY="${RECEIVER_BUILD_DIRECTORY}/dump1090-mutability"
DUMP1090_CONFIGURATION_FILE="/etc/default/dump1090-mutability"

# Component service script variables.
COMPONENT_SERVICE_NAME="dump1090-mutability"

### INCLUDE EXTERNAL SCRIPTS

source ${RECEIVER_BASH_DIRECTORY}/variables.sh
source ${RECEIVER_BASH_DIRECTORY}/functions.sh

## SET INSTALLATION VARIABLES

# Source the automated install configuration file if this is an automated installation.
if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "true" ]] && [[ -s "${RECEIVER_CONFIGURATION_FILE}" ]] ; then
    source ${RECEIVER_CONFIGURATION_FILE}
else
    RECEIVER_LATITUDE=`GetConfig "LAT" "${DUMP1090_CONFIGURATION_FILE}"`
    RECEIVER_LONGITUDE=`GetConfig "LON" "${DUMP1090_CONFIGURATION_FILE}"`
    DUMP1090_BING_MAPS_KEY=`GetConfig "BingMapsAPIKey" "/usr/share/dump1090-mutability/html/config.js"`
    DUMP1090_MAPZEN_KEY=`GetConfig "MapzenAPIKey" "/usr/share/dump1090-mutability/html/config.js"`
fi

### BEGIN SETUP

if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "false" ]] ; then
    clear
    echo -e "\n\e[91m   ${RECEIVER_PROJECT_TITLE}"
fi
echo -e ""
echo -e "\e[92m  Setting up ${COMPONENT_NAME}..."
echo -e ""
echo -e "\e[93m  ------------------------------------------------------------------------------\e[96m"
echo -e ""

# Check for existing component install.

# Confirm component installation.
if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "false" ]] ; then
    # Interactive install.
    CONTINUE_SETUP=$(whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" --title "${COMPONENT_NAME} Setup" --yesno "Dump1090 is a Mode-S decoder specifically designed for RTL-SDR devices.\n\n${COMPONENT_NAME} is a fork of MalcolmRobb's version of Dump1090 that adds new functionality and is designed to be built as a Debian/Raspbian package.\n\n  ${COMPONENT_WEBSITE} \n\nContinue setup by installing ${COMPONENT_NAME}?" 15 78 3>&1 1>&2 2>&3)
    if [[ ${CONTINUE_SETUP} -eq 1 ]] ; then
        # Setup has been halted by the user.
        echo -e "\e[91m  \e[5mINSTALLATION HALTED!\e[25m"
        echo -e "  Setup has been halted at the request of the user."
        echo -e ""
        echo -e "\e[93m  ------------------------------------------------------------------------------"
        echo -e "\e[92m  ${COMPONENT_NAME} setup halted.\e[39m"
        echo -e ""
        read -p "Press enter to continue..." CONTINUE
        exit 1
    fi
else
    # Warn that automated installation is not supported.
    echo -e "\e[92m  Automated installation of this script is not yet supported...\e[39m"
    echo -e ""
    exit 1
fi

### CHECK FOR PREREQUISITE PACKAGES

echo -e "\e[95m  Installing packages needed to fulfill dependencies for ${COMPONENT_NAME}...\e[97m"
echo -e ""
# Required by install script.
CheckPackage git
CheckPackage curl
CheckPackage build-essential
CheckPackage debhelper
CheckPackage cron
# Required for USB SDR devices.
CheckPackage librtlsdr-dev
CheckPackage libusb-1.0-0-dev
CheckPackage rtl-sdr
# Required by component.
CheckPackage pkg-config
CheckPackage lighttpd
CheckPackage fakeroot

## DOWNLOAD OR UPDATE THE DUMP1090-MUTABILITY SOURCE

echo -e ""
echo -e "\e[95m  Preparing the ${COMPONENT_NAME} Git repository...\e[97m"
echo -e ""
if [[ -d "${COMPONENT_BUILD_DIRECTORY}/dump1090" ]] && [[ -d "${COMPONENT_BUILD_DIRECTORY}/dump1090/.git" ]] ; then
    # A directory with a git repository containing the source code already exists.
    echo -e "\e[94m  Entering the ${COMPONENT_NAME} git repository directory...\e[97m"
    cd ${COMPONENT_BUILD_DIRECTORY}/dump1090 2>&1
    echo -e "\e[94m  Updating the local ${COMPONENT_NAME} git repository...\e[97m"
    echo -e ""
    git pull 2>&1
else
    # A directory containing the source code does not exist in the build directory.
    echo -e "\e[94m  Entering ${RECEIVER_PROJECT_TITLE} build directory...\e[97m"
    mkdir -vp ${COMPONENT_BUILD_DIRECTORY}
    cd ${COMPONENT_BUILD_DIRECTORY} 2>&1
    echo -e "\e[94m  Cloning the ${COMPONENT_NAME} git repository locally...\e[97m"
    echo -e ""
    git clone ${COMPONENT_GITHUB_URL} 2>&1
fi

## BUILD AND INSTALL THE DUMP1090-MUTABILITY PACKAGE

# Build the deb binary package.
echo -e ""
echo -e "\e[95m  Building and installing the ${COMPONENT_NAME} package...\e[97m"
echo -e ""
if [[ ! "${PWD}" = "${COMPONENT_BUILD_DIRECTORY}/dump1090" ]] ; then
    echo -e "\e[94m  Entering the ${COMPONENT_NAME} git repository directory...\e[97m"
    cd ${COMPONENT_BUILD_DIRECTORY}/dump1090 2>&1
fi
echo -e "\e[94m  Building the ${COMPONENT_NAME} package...\e[97m"
echo -e ""
dpkg-buildpackage -b 2>&1

# Prempt the dpkg question asking if the user would like dump1090 to start automatically.
if [[ ! "`sudo debconf-get-selections 2>/dev/null | grep "dump1090-mutability/auto-start" | awk '{print $4}'`" = "true" ]] ; then
    echo -e ""
    echo -e "\e[94m  Configuring ${COMPONENT_NAME} to start automatically....\e[97m]"
    ACTION=$(echo 'dump1090-mutability dump1090-mutability/auto-start boolean true' | sudo debconf-set-selections -v 2>&1)
    echo -e ""
fi

# Install the deb binary package.
echo -e ""
echo -e "\e[94m  Entering ${RECEIVER_PROJECT_TITLE} build directory...\e[97m"
cd ${COMPONENT_BUILD_DIRECTORY} 2>&1
echo -e "\e[94m  Installing the ${COMPONENT_NAME} package...\e[97m"
echo -e ""
sudo dpkg -i ${COMPONENT_PACKAGE_NAME}_1.15~dev_*.deb 2>&1

# Check that the package was installed.
echo -e ""
echo -e "\e[94m  Checking that the ${COMPONENT_NAME} package was installed properly...\e[97m"
if [[ $(dpkg-query -W -f='${STATUS}' ${COMPONENT_PACKAGE_NAME} 2>/dev/null | grep -c "ok installed") -eq 0 ]] ; then
    # If the component package could not be installed halt setup.
    echo -e ""
    echo -e "\e[91m  \e[5mINSTALLATION HALTED!\e[25m"
    echo -e "  UNABLE TO INSTALL A REQUIRED PACKAGE."
    echo -e "  SETUP HAS BEEN TERMINATED!"
    echo -e ""
    echo -e "\e[93mThe package \"${COMPONENT_PACKAGE_NAME}\" could not be installed.\e[39m"
    echo -e ""
    echo -e "\e[93m  ------------------------------------------------------------------------------"
    echo -e "\e[92m  ${COMPONENT_NAME} setup halted.\e[39m"
    echo -e ""
    if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "false" ]] ; then
        read -p "Press enter to continue..." CONTINUE
    fi
    exit 1
fi

## DUMP1090-MUTABILITY POST INSTALLATION CONFIGURATION

# Confirm the receiver's latitude and longitude if it is not already set in the component configuration file.
echo -e ""
echo -e "\e[95m  Begining post installation configuration...\e[97m"
echo -e ""

# Ask for the receivers latitude and longitude.
if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "false" ]] ; then
    # Explain to the user that the receiver's latitude and longitude is required.
    RECEIVER_LATLON_DIALOG=$(whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" --title "Receiver Latitude and Longitude" --msgbox "Your receivers latitude and longitude are required for distance calculations, you will now be asked to supply these values for your receiver.\n\nIf you do not have this information you can obtain it using the web based \"Geocode by Address\" utility hosted on another of the lead developers websites:\n\n  https://www.swiftbyte.com/toolbox/geocode" 15 78 3>&1 1>&2 2>&3)

    # Ask the user for the receiver's latitude.
    RECEIVER_LATITUDE_TITLE="Receiver Latitude"
    while [[ -z "${RECEIVER_LATITUDE}" ]] || [[ `echo -n "${RECEIVER_LATITUDE}" | sed -e 's/[0-9]//g' -e 's/\.//g' -e 's/-//g' | wc -c` -gt 0 ]] ; do
        RECEIVER_LATITUDE=`GetConfig "LAT" "${DUMP1090_CONFIGURATION_FILE}"`
        RECEIVER_LATITUDE=$(whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" --title "${RECEIVER_LATITUDE_TITLE}" --nocancel --inputbox "\nEnter your receiver's latitude.\n(Example: XX.XXXXXXX)" 9 78 -- "${RECEIVER_LATITUDE}" 3>&1 1>&2 2>&3)
        RECEIVER_LATITUDE_TITLE="Receiver Latitude (REQUIRED)"
    done

    # Ask the user for the receiver's longitude.
    RECEIVER_LONGITUDE_TITLE="Receiver Longitude"
    while [[ -z "${RECEIVER_LONGITUDE}" ]] || [[ `echo -n "${RECEIVER_LONGITUDE}" | sed -e 's/[0-9]//g' -e 's/\.//g' -e 's/-//g' | wc -c` -gt 0 ]] ; do
        RECEIVER_LONGITUDE=`GetConfig "LON" "${DUMP1090_CONFIGURATION_FILE}"`
        RECEIVER_LONGITUDE=$(whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" --title "${RECEIVER_LONGITUDE_TITLE}" --nocancel --inputbox "\nEnter your receeiver's longitude.\n(Example: XX.XXXXXXX)" 9 78 -- "${RECEIVER_LONGITUDE}" 3>&1 1>&2 2>&3)
        RECEIVER_LONGITUDE_TITLE="Receiver Longitude (REQUIRED)"
    done
fi

# Save the receiver's latitude and longitude values to dump1090 configuration file.
RECEIVER_LATITUDE_CONFIGURED=`GetConfig "LON" "${DUMP1090_CONFIGURATION_FILE}"`
if [[ ! "${RECEIVER_LATITUDE}" = "${RECEIVER_LATITUDE_CONFIGURED}" ]] ; then
    echo -e "\e[94m  Setting the receiver's latitude to ${RECEIVER_LATITUDE}...\e[97m"
    ChangeConfig "LAT" "${RECEIVER_LATITUDE}" "${DUMP1090_CONFIGURATION_FILE}"
fi
RECEIVER_LONGITUDE_CONFIGURED=`GetConfig "LON" "${DUMP1090_CONFIGURATION_FILE}"`
if [[ ! "${RECEIVER_LONGITUDE}" = "${RECEIVER_LONGITUDE_CONFIGURED}" ]] ; then
    echo -e "\e[94m  Setting the receiver's longitude to ${RECEIVER_LONGITUDE}...\e[97m"
    ChangeConfig "LON" "${RECEIVER_LONGITUDE}" "${DUMP1090_CONFIGURATION_FILE}"
fi

# Ask for a Bing Maps API key.
if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "false" ]] ; then
    DUMP1090_BING_MAPS_KEY=$(whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" --title "Bing Maps API Key" --nocancel --inputbox "\nProvide a Bing Maps API key here to enable the Bing imagery layer within the ${COMPONENT_NAME} map, you can obtain a free key at the following website:\n\n  https://www.bingmapsportal.com/\n\nProviding a Bing Maps API key is not required to continue." 15 78 -- "${DUMP1090_BING_MAPS_KEY}" 3>&1 1>&2 2>&3)
fi
if [[ -n "${DUMP1090_BING_MAPS_KEY}" ]] ; then
    echo -e "\e[94m  Setting the Bing Maps API Key to ${DUMP1090_BING_MAPS_KEY}...\e[97m"
    ChangeConfig "BingMapsAPIKey" "${DUMP1090_BING_MAPS_KEY}" "/usr/share/dump1090-mutability/html/config.js"
fi

# Ask for a Mapzen API key.
if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "false" ]] ; then
    DUMP1090_MAPZEN_KEY=$(whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" --title "Mapzen API Key" --nocancel --inputbox "\nProvide a Mapzen API key here to enable the Mapzen vector tile layer within the ${COMPONENT_NAME} map, you can obtain a free key at the following website:\n\n  https://mapzen.com/developers/\n\nProviding a Mapzen API key is not required to continue." 15 78 -- "${DUMP1090_MAPZEN_KEY}" 3>&1 1>&2 2>&3)
fi
if [[ -n "${DUMP1090_MAPZEN_KEY}" ]] ; then
    echo -e "\e[94m  Setting the Mapzen API Key to ${DUMP1090_MAPZEN_KEY}...\e[97m"
    ChangeConfig "MapzenAPIKey" "${DUMP1090_MAPZEN_KEY}" "/usr/share/dump1090-mutability/html/config.js"
fi

# Ask if the component should bind on all IP addresses.
if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "false" ]] ; then
    whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" --title "Bind ${COMPONENT_NAME} To All IP Addresses" --yesno "By default ${COMPONENT_NAME} is bound only to the local loopback IP address(s) for security reasons. However some people wish to make ${COMPONENT_NAME}'s data accessable externally by other devices. To allow this ${COMPONENT_NAME} can be configured to listen on all IP addresses bound to this device. It is recommended that unless you plan to access this device from an external source that ${COMPONENT_NAME} remain bound only to the local loopback IP address(s).\n\nWould you like ${COMPONENT_NAME} to listen on all IP addesses?" 15 78
    case $? in
        0)
            DUMP1090_BIND_TO_ALL_IPS="true"
            ;;
        1)
            DUMP1090_BIND_TO_ALL_IPS="false"
            ;;
    esac
fi
if [[ ! "${DUMP1090_BIND_TO_ALL_IPS}" = "false" ]] ; then
    echo -e "\e[94m  Binding ${COMPONENT_NAME} to all available IP addresses...\e[97m"
    CommentConfig "NET_BIND_ADDRESS" "${DUMP1090_CONFIGURATION_FILE}"
else
    echo -e "\e[94m  Binding ${COMPONENT_NAME} to the localhost IP addresses...\e[97m"
    UncommentConfig "NET_BIND_ADDRESS" "${DUMP1090_CONFIGURATION_FILE}"
    ChangeConfig "NET_BIND_ADDRESS" "127.0.0.1" "${DUMP1090_CONFIGURATION_FILE}"
fi

# In future ask the user if they would like to specify the maximum range manually, if not set to 360 nmi / ~667 km to match dump1090-fa.
if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "false" ]] ; then
    DUMP1090_MAX_RANGE_DIALOG=$(whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" --title "${COMPONENT_NAME} Maximum Range" --msgbox "The ${COMPONENT_NAME} default maximum range value of 300 nmi (~550km) has been reported to be below what is possible under the right conditions, so this value will be increased to 360 nmi (~660 km) to match the value used by the dump1090-fa fork." 10 78 3>&1 1>&2 2>&3)
fi
if [[ -z "${DUMP1090_MAX_RANGE}" ]] ; then
    DUMP1090_MAX_RANGE="360"
fi
if [[ `grep "MAX_RANGE" ${DUMP1090_CONFIGURATION_FILE} | awk -F \" '{print $2}'` = "${DUMP1090_MAX_RANGE}" ]] ; then
    ChangeConfig "MAX_RANGE" "${DUMP1090_MAX_RANGE}" "${DUMP1090_CONFIGURATION_FILE}"
fi

# Ask if measurements should be displayed using imperial or metric.
if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "false" ]] ; then
    whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" --title "Unit of Measurement" --yes-button "Imperial" --no-button "Metric" --yesno "\nPlease select the unit of measurement to be used by ${COMPONENT_NAME}." 8 78
    case $? in
        0)
            DUMP1090_UNIT_OF_MEASUREMENT="imperial"
            ;;
        1)
            DUMP1090_UNIT_OF_MEASUREMENT="metric"
            ;;
    esac
fi
if [[ "${DUMP1090_UNIT_OF_MEASUREMENT}" = "metric" ]] ; then
    echo -e "\e[94m  Setting ${COMPONENT_NAME} unit of measurement to Metric...\e[97m"
    ChangeConfig "Metric" "true;" "/usr/share/dump1090-mutability/html/config.js"
else
    echo -e "\e[94m  Setting ${COMPONENT_NAME} unit of measurement to Imperial...\e[97m"
    ChangeConfig "Metric" "false;" "/usr/share/dump1090-mutability/html/config.js"
fi

# Download Heywhatsthat.com maximum range rings.
if [[ ! -f "/usr/share/dump1090-mutability/html/upintheair.json" ]] ; then
    if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "false" ]] ; then
        if (whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" --title "Heywhaststhat.com Maximum Range Rings" --yesno "Maximum range rings can be added to ${COMPONENT_NAME} using data obtained from Heywhatsthat.com. In order to add these rings to your ${COMPONENT_NAME} map you will first need to visit http://www.heywhatsthat.com and generate a new panorama centered on the location of your receiver. Once your panorama has been generated a link to the panorama will be displayed in the top left hand portion of the page. You will need the view id which is the series of letters and/or numbers after \"?view=\" in this URL.\n\nWould you like to add heywatsthat.com maximum range rings to your map?" 16 78) ; then
            # Set the DUMP1090_HEYWHATSTHAT_INSTALL variable to true.
            DUMP1090_HEYWHATSTHAT_INSTALL="true"
            # Ask the user for the Heywhatsthat.com panorama ID.
            DUMP1090_HEYWHATSTHAT_ID_TITLE="Heywhatsthat.com Panorama ID"
            while [[ -z "${DUMP1090_HEYWHATSTHAT_ID}" ]] ; do
                DUMP1090_HEYWHATSTHAT_ID=$(whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" --title "${DUMP1090_HEYWHATSTHAT_ID_TITLE}" --nocancel --inputbox "\nEnter your Heywhatsthat.com panorama ID." 8 78 3>&1 1>&2 2>&3)
                DUMP1090_HEYWHATSTHAT_ID_TITLE="Heywhatsthat.com Panorama ID (REQUIRED)"
            done
            # Ask the user what altitude in meters to set the first range ring.
            DUMP1090_HEYWHATSTHAT_RING_ONE_TITLE="Heywhatsthat.com First Ring Altitude"
            while [[ -z "${DUMP1090_HEYWHATSTHAT_RING_ONE}" ]] ; do
                DUMP1090_HEYWHATSTHAT_RING_ONE=$(whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" --title "${DUMP1090_HEYWHATSTHAT_RING_ONE_TITLE}" --nocancel --inputbox "\nEnter the first ring's altitude in meters.\n(default 3048 meters or 10000 feet)" 8 78 "3048" 3>&1 1>&2 2>&3)
                DUMP1090_HEYWHATSTHAT_RING_ONE_TITLE="Heywhatsthat.com First Ring Altitude (REQUIRED)"
            done
            # Ask the user what altitude in meters to set the second range ring.
            DUMP1090_HEYWHATSTHAT_RING_TWO_TITLE="Heywhatsthat.com Second Ring Altitude"
            while [[ -z "${DUMP1090_HEYWHATSTHAT_RING_TWO}" ]] ; do
                DUMP1090_HEYWHATSTHAT_RING_TWO=$(whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" --title "${DUMP1090_HEYWHATSTHAT_RING_TWO_TITLE}" --nocancel --inputbox "\nEnter the second ring's altitude in meters.\n(default 12192 meters or 40000 feet)" 8 78 "12192" 3>&1 1>&2 2>&3)
                DUMP1090_HEYWHATSTHAT_RING_TWO_TITLE="Heywhatsthat.com Second Ring Altitude (REQUIRED)"
            done
        fi
    fi
    # If the Heywhatsthat.com maximum range rings are to be added download them now.
    if [[ "${DUMP1090_HEYWHATSTHAT_INSTALL}" = "true" ]] ; then
        echo -e "\e[94m  Downloading JSON data pertaining to the supplied panorama ID...\e[97m"
        echo -e ""
        sudo wget -O /usr/share/dump1090-mutability/html/upintheair.json "http://www.heywhatsthat.com/api/upintheair.json?id=${DUMP1090_HEYWHATSTHAT_ID}&refraction=0.25&alts=${DUMP1090_HEYWHATSTHAT_RING_ONE},${DUMP1090_HEYWHATSTHAT_RING_TWO}"
    fi
fi

# (re)start the component service.
if [[ "`sudo systemctl status ${COMPONENT_SERVICE_NAME} 2>&1 | egrep -c "Active: active (running)"`" -gt 0 ]] ; then
    echo -e "\e[94m  Restarting the ${COMPONENT_NAME} service..."
    ACTION=$(sudo systemctl restart ${COMPONENT_SERVICE_NAME} 2>&1)
else
    echo -e "\e[94m  Starting the ${COMPONENT_NAME} service..."
    ACTION=$(sudo systemctl start ${COMPONENT_SERVICE_NAME} 2>&1)
fi

### SETUP COMPLETE

# Return to the project root directory.
echo -e "\e[94m  Returning to ${RECEIVER_PROJECT_TITLE} root directory...\e[97m"
cd ${RECEIVER_ROOT_DIRECTORY} 2>&1

echo -e ""
echo -e "\e[93m  ------------------------------------------------------------------------------"
echo -e "\e[92m  ${COMPONENT_NAME} setup is complete.\e[39m"
echo -e ""
if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "false" ]] ; then
    read -p "Press enter to continue..." CONTINUE
fi

exit 0
