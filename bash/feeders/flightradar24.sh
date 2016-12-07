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

## VARIABLES

PROJECTROOTDIRECTORY="$PWD"
BASHDIRECTORY="$PROJECTROOTDIRECTORY/bash"
BUILDDIRECTORY="$PROJECTROOTDIRECTORY/build"
FR24BUILDDIRECTORY="$PROJECTROOTDIRECTORY/build/flightradar24"

## INCLUDE EXTERNAL SCRIPTS

source $BASHDIRECTORY/variables.sh
source $BASHDIRECTORY/functions.sh

## BEGIN SETUP

clear
echo -e "\n\e[91m  $ADSB_PROJECTTITLE"
echo ""
echo -e "\e[92m  Setting up the Flightradar24 feeder client..."
echo -e "\e[93m----------------------------------------------------------------------------------------------------\e[96m"
echo ""
whiptail --backtitle "$ADSB_PROJECTTITLE" --title "Flightradar24 Feeder Client Setup" --yesno "The Flightradar24's feeder client can track flights within 200-400 miles and will automatically share data with Flightradar24. You can track flights directly off your device or via Flightradar24.com.\n\n  http://www.flightradar24.com/share-your-data\n\nContinue setup by installing the Flightradar24 feeder client?" 13 78
CONTINUESETUP=$?
if [ $CONTINUESETUP = 1 ]; then
    # Setup has been halted by the user.
    echo -e "\e[91m  \e[5mINSTALLATION HALTED!\e[25m"
    echo -e "  Setup has been halted at the request of the user."
    echo ""
    echo -e "\e[93m----------------------------------------------------------------------------------------------------"
    echo -e "\e[92m  Flightradar24 feeder client setup halted.\e[39m"
    echo ""
    if [ ${VERBOSE} ] ; then
        read -p "Press enter to continue..." CONTINUE
    fi
    exit 1
fi

## CHECK FOR PREREQUISITE PACKAGES

echo -e "\e[95m  Installing packages needed to build and fulfill dependencies...\e[97m"
echo ""
if [[ `uname -m` == "x86_64" ]]; then
    if [ $(dpkg --print-foreign-architectures $1 2>/dev/null | grep -c "i386") -eq 0 ]; then
        echo -e "\e[94m  Adding the i386 architecture...\e[97m"
        sudo dpkg --add-architecture i386
        echo -e "\e[94m  Downloading latest package lists for enabled repositories and PPAs...\e[97m"
        echo ""
        sudo apt-get update
        echo ""
    fi
    CheckPackage libc6:i386
    CheckPackage libudev1:i386
    CheckPackage zlib1g:i386
    CheckPackage libusb-1.0-0:i386
    CheckPackage libstdc++6:i386
else
    CheckPackage libc6
    CheckPackage libudev1
    CheckPackage zlib1g
    CheckPackage libusb-1.0-0
    CheckPackage libstdc++6
fi
CheckPackage wget

## BEGIN INSTALLATION DEPENDING ON DEVICE ARCHITECTURE

echo ""
echo -e "\e[95m  Begining the installation process...\e[97m"
echo ""
# Create the flightradar24 build directory if it does not exist.
if [ ! -d $FR24BUILDDIRECTORY ]; then
    echo -e "\e[94m  Creating the Flightradar24 feeder client build directory...\e[97m"
    mkdir $FR24BUILDDIRECTORY
fi
echo -e "\e[94m  Entering the Flightradar24 feeder client build directory...\e[97m"
cd $FR24BUILDDIRECTORY
if [[ `uname -m` == "armv7l" ]] || [[ `uname -m` == "armv6l" ]] || [[ `uname -m` == "aarch64" ]]; then

    ## ARM INSTALLATION

    whiptail --backtitle "$ADSB_PROJECTTITLE" --title "Plane Finder ADS-B Client Setup Instructions" --msgbox "This script will now download and execute the official Flightradar24 setup script. Follow the instructions provided and supply the required information when ask for by the script.\n\nOnce finished the ADS-B Receiver Project scripts will continue." 11 78
    echo -e "\e[94m  Detected the device architecture as ARM...\e[97m"
    echo -e "\e[94m  Downloading the executing the Flightradar24 Pi24 installation script...\e[97m"
    echo ""
    sudo bash -c "$(wget -O - http://repo.feed.flightradar24.com/install_fr24_rpi.sh)"
    echo ""
else

    ## I386 INSTALLATION

    echo -e "\e[94m  Detected the device architecture as I386...\e[97m"
    echo -e "\e[94m  Downloading the Flightradar24 feeder client package...\e[97m"
    echo ""
    wget http://feed.flightradar24.com/linux/fr24feed_${FR24CLIENTVERSIONI386}_i386.deb -O $FR24BUILDDIRECTORY/fr24feed_${FR24CLIENTVERSIONI386}_i386.deb
    echo -e "\e[94m  Installing the Flightradar24 feeder client package...\e[97m"
    if [[ `lsb_release -si` == "Debian" ]]; then
        # Force architecture if this is Debian.
        echo -e "\e[94m  NOTE: dpkg executed with added flag --force-architecture.\e[97m"
        echo ""
        sudo dpkg -i --force-architecture $FR24BUILDDIRECTORY/fr24feed_${FR24CLIENTVERSIONI386}_i386.deb
    else
        echo ""
        sudo dpkg -i $FR24BUILDDIRECTORY/fr24feed_${FR24CLIENTVERSIONI386}_i386.deb
    fi
    echo ""
    echo -e "\e[94m  Checking that the fr24feed package was installed properly...\e[97m"
    if [ $(dpkg-query -W -f='${STATUS}' fr24feed 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        # If the fr24feed package could not be installed halt setup.
        echo ""
        echo -e "\e[91m  \e[5mINSTALLATION HALTED!\e[25m"
        echo -e "  UNABLE TO INSTALL A REQUIRED PACKAGE."
        echo -e "  SETUP HAS BEEN TERMINATED!"
        echo ""
        echo -e "\e[93mThe package \"fr24feed\" could not be installed.\e[39m"
        echo ""
        echo -e "\e[93m----------------------------------------------------------------------------------------------------"
        echo -e "\e[92m  Flightradar24 feeder client setup halted.\e[39m"
        echo ""
        if [ ${VERBOSE} ] ; then
            read -p "Press enter to continue..." CONTINUE
        fi
        exit 1
    fi
fi

## FLIGHTRADAR24 FEEDER CLIENT SETUP COMPLETE

# Enter into the project root directory.
echo -e "\e[94m  Entering the ADS-B Receiver Project root directory...\e[97m"
cd $PROJECTROOTDIRECTORY

echo ""
echo -e "\e[93m-------------------------------------------------------------------------------------------------------"
echo -e "\e[92m  Flightradar24 feeder client setup is complete.\e[39m"
echo ""
if [ ${VERBOSE} ] ; then
    read -p "Press enter to continue..." CONTINUE
fi

exit 0
