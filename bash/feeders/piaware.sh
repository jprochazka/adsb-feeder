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

### VAARIABLES

PROJECTROOTDIRECTORY="$PWD"
BASHDIRECTORY="$PROJECTROOTDIRECTORY/bash"
BUILDDIRECTORY="$PROJECTROOTDIRECTORY/build"
PIAWAREBUILDDIRECTORY="$PROJECTROOTDIRECTORY/build/piaware_builder"

DECODER_NAME="PiAware"
DECODER_WEBSITE="https://github.com/flightaware/piaware"

### INCLUDE EXTERNAL SCRIPTS

source $BASHDIRECTORY/variables.sh
source $BASHDIRECTORY/functions.sh

### BEGIN SETUP

clear
echo -e ""
echo -e "\e[91m  $RECEIVER_PROJECT_TITLE"
echo -e ""
echo -e "\e[92m  Setting up FlightAware's ${DECODER_NAME}..."
echo -e "\e[93m----------------------------------------------------------------------------------------------------\e[96m"
echo -e ""
whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "${DECODER_NAME} Setup" --yesno "${DECODER_NAME} is a package used to forward data read from an ADS-B receiver to FlightAware. It does this using a program, piaware, while aided by other support programs.\n\n  ${DECODER_WEBSITE}  \n\nContinue setup by installing FlightAware's ${DECODER_NAME}?" 13 78
CONTINUESETUP=$?
if [[ $CONTINUESETUP = 1 ]] ; then
    # Setup has been halted by the user.
    echo -e "\e[91m  \e[5mINSTALLATION HALTED!\e[25m"
    echo -e "  Setup has been halted at the request of the user."
    echo -e ""
    echo -e "\e[93m----------------------------------------------------------------------------------------------------"
    echo -e "\e[92m  ${DECODER_NAME} setup halted.\e[39m"
    echo -e ""
    if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "false" ]] ; then
        read -p "Press enter to continue..." CONTINUE
    fi
    exit 1
fi

### CHECK FOR PREREQUISITE PACKAGES

echo -e "\e[95m  Installing packages needed to build and fulfill dependencies for ${DECODER_NAME} ...\e[97m"
echo -e ""
CheckPackage git
CheckPackage build-essential
CheckPackage debhelper
CheckPackage tcl8.6-dev
CheckPackage autoconf
CheckPackage python3-dev
CheckPackage python3-venv
CheckPackage virtualenv
CheckPackage dh-systemd
CheckPackage zlib1g-dev
CheckPackage tclx8.4
CheckPackage tcllib
CheckPackage tcl-tls
CheckPackage itcl3

### DOWNLOAD OR UPDATE THE PIAWARE_BUILDER SOURCE

echo -e ""
echo -e "\e[95m  Preparing the piaware_builder Git repository...\e[97m"
echo -e ""
if [ -d $PIAWAREBUILDDIRECTORY ] && [ -d $PIAWAREBUILDDIRECTORY/.git ]; then
    # A directory with a git repository containing the source code already exists.
    echo -e "\e[94m  Entering the piaware_builder git repository directory...\e[97m"
    cd $PIAWAREBUILDDIRECTORY
    echo -e "\e[94m  Updating the local piaware_builder git repository...\e[97m"
    echo -e ""
    git pull
else
    # A directory containing the source code does not exist in the build directory.
    echo -e "\e[94m  Entering the ADS-B Receiver Project build directory...\e[97m"
    cd $BUILDDIRECTORY
    echo -e "\e[94m  Cloning the piaware_builder git repository locally...\e[97m"
    echo -e ""
    git clone https://github.com/flightaware/piaware_builder.git
fi

### BUILD AND INSTALL THE PIAWARE PACKAGE

echo -e ""
echo -e "\e[95m  Building and installing the ${DECODER_NAME} package...\e[97m"
echo -e ""
if [ ! $PWD = $PIAWAREBUILDDIRECTORY ]; then
    echo -e "\e[94m  Entering the piaware_builder git repository directory...\e[97m"
    cd $PIAWAREBUILDDIRECTORY
fi
echo -e "\e[94m  Executing the ${DECODER_NAME} build script...\e[97m"
echo -e ""
./sensible-build.sh jessie
echo -e ""
echo -e "\e[94m  Entering the ${DECODER_NAME} build directory...\e[97m"
cd $PIAWAREBUILDDIRECTORY/package-jessie
echo -e "\e[94m  Building the ${DECODER_NAME} package...\e[97m"
echo -e ""
dpkg-buildpackage -b
echo -e ""
echo -e "\e[94m  Installing the ${DECODER_NAME} package...\e[97m"
echo -e ""
sudo dpkg -i $PIAWAREBUILDDIRECTORY/piaware_*.deb

# Check that the PiAware package was installed successfully.
echo -e ""
echo -e "\e[94m  Checking that the piaware package was installed properly...\e[97m"
if [ $(dpkg-query -W -f='${STATUS}' piaware 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    # If the piaware package could not be installed halt setup.
    echo -e ""
    echo -e "\e[91m  \e[5mINSTALLATION HALTED!\e[25m"
    echo -e "  UNABLE TO INSTALL A REQUIRED PACKAGE."
    echo -e "  SETUP HAS BEEN TERMINATED!"
    echo -e ""
    echo -e "\e[93mThe package \"${DECODER_NAME}\" could not be installed.\e[39m"
    echo -e ""
    echo -e "\e[93m----------------------------------------------------------------------------------------------------"
    echo -e "\e[92m  ${DECODER_NAME} setup halted.\e[39m"
    echo -e ""
    if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "false" ]] ; then
        read -p "Press enter to continue..." CONTINUE
    fi
    exit 1
fi

### ARCHIVE SETUP PACKAGES

# Move the .deb package into another directory simply to keep it for historical reasons.
if [ ! -d $PIAWAREBUILDDIRECTORY/packages ]; then
    echo -e "\e[94m  Making the ${DECODER_NAME} package archive directory...\e[97m"
    mkdir $PIAWAREBUILDDIRECTORY/packages
fi
echo -e "\e[94m  Moving the ${DECODER_NAME} package into the package archive directory...\e[97m"
mv $PIAWAREBUILDDIRECTORY/piaware_*.deb $PIAWAREBUILDDIRECTORY/packages/
echo -e "\e[94m  Moving the ${DECODER_NAME} package changes file into the package archive directory...\e[97m"
mv $PIAWAREBUILDDIRECTORY/piaware_*.changes $PIAWAREBUILDDIRECTORY/packages/

### CONFIGURE FLIGHTAWARE

whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "Claim Your PiAware Device" --msgbox "Please supply your FlightAware login in order to claim this device. After supplying your login PiAware will ask you to enter your password for verification. If you decide not to supply a login and password at this time you should still be able to claim your feeder by visting this page:\n\n  http://flightaware.com/adsb/piaware/claim" 11 78
# Ask for the users FlightAware login.
FLIGHTAWARELOGIN=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "Your FlightAware Login" --nocancel --inputbox "\nEnter your FlightAware login.\nLeave this blank to manually claim your PiAware device." 9 78 3>&1 1>&2 2>&3)
if [ ! $FLIGHTAWARELOGIN = "" ]; then
    # If the user supplied their FlightAware login continue with the device claiming process.
    FLIGHTAWAREPASSWORD1_TITLE="Your FlightAware Password"
    while [[ -z $FLIGHTAWAREPASSWORD1 ]]; do
        FLIGHTAWAREPASSWORD1=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$FLIGHTAWAREPASSWORD1_TITLE" --nocancel --passwordbox "\nEnter your FlightAware password." 8 78 3>&1 1>&2 2>&3)
    done
    FLIGHTAWAREPASSWORD2_TITLE="Confirm Your FlightAware Password"
    while [[ -z $FLIGHTAWAREPASSWORD2 ]]; do
        FLIGHTAWAREPASSWORD2=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$FLIGHTAWAREPASSWORD2_TITLE" --nocancel --passwordbox "\nConfirm your FlightAware password." 8 78 3>&1 1>&2 2>&3)
    done
    while [ ! $FLIGHTAWAREPASSWORD1 = $FLIGHTAWAREPASSWORD2 ]; do
        FLIGHTAWAREPASSWORD1=""
        FLIGHTAWAREPASSWORD2=""
        # Display an error message if the passwords did not match.
        whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "Claim Your PiAware Device" --msgbox "Passwords did not match.\nPlease enter your password again." 9 78
        FLIGHTAWAREPASSWORD1_TITLE="Your FlightAware Password (REQUIRED)"
        while [[ -z $FLIGHTAWAREPASSWORD1 ]]; do
            FLIGHTAWAREPASSWORD1=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$FLIGHTAWAREPASSWORD1_TITLE" --nocancel --passwordbox "\nEnter your FlightAware password." 8 78 3>&1 1>&2 2>&3)
        done
        FLIGHTAWAREPASSWORD2_TITLE="Confirm Your FlightAware Password (REQUIRED)"
        while [[ -z $FLIGHTAWAREPASSWORD2 ]]; do
            FLIGHTAWAREPASSWORD2=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$FLIGHTAWAREPASSWORD2_TITLE" --nocancel --passwordbox "\nConfirm your FlightAware password." 8 78 3>&1 1>&2 2>&3)
        done
    done

    # Set the supplied user name and password in the configuration.
    echo -e "\e[94m  Setting the flightaware-user setting using piaware-config...\e[97m"
    echo -e ""
    sudo piaware-config flightaware-user $FLIGHTAWARELOGIN
    echo -e ""
    echo -e "\e[94m  Setting the flightaware-password setting using piaware-config...\e[97m"
    echo -e ""
    sudo piaware-config flightaware-password $FLIGHTAWAREPASSWORD1
    echo -e ""
    echo -e "\e[94m  Restarting PiAware to ensure changes take effect...\e[97m"
    echo -e ""
    sudo /etc/init.d/piaware restart
    echo -e ""
else
    # Display a message to the user stating they need to manually claim their device.
    whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "Claim Your PiAware Device" --msgbox "Since you did not supply a login you will need to claim this PiAware device manually by visiting this page:\n\n  http://flightaware.com/adsb/piaware/claim" 10 78
fi

### SETUP COMPLETE

# Enter into the project root directory.
echo -e "\e[94m  Entering the $RECEIVER_PROJECT_TITLE root directory...\e[97m"
cd $PROJECTROOTDIRECTORY

echo -e ""
echo -e "\e[93m-------------------------------------------------------------------------------------------------------"
echo -e "\e[92m  ${DECODER_NAME} setup is complete.\e[39m"
echo -e ""
if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "false" ]] ; then
    read -p "Press enter to continue..." CONTINUE
fi

exit 0
