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
# Copyright (c) 2016-2017, Joseph A. Prochazka & Romeo Golf                         #
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
COMPONENT_NAME="MLAT Client"
COMPONENT_GITHUB_URL="https://github.com/mutability/mlat-client.git"
COMPONENT_BUILD_DIRECTORY="${RECEIVER_BUILD_DIRECTORY}/mlat-client"

# Component service script variables.

### INCLUDE EXTERNAL SCRIPTS

source ${RECEIVER_BASH_DIRECTORY}/variables.sh
source ${RECEIVER_BASH_DIRECTORY}/functions.sh

# Source the automated install configuration file if this is an automated installation.
if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "true" ]] ; then
    source ${RECEIVER_CONFIGURATION_FILE}
fi

### BEGIN SETUP

if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "false" ]] ; then
    clear
    echo -e "\n\e[91m   ${RECEIVER_PROJECT_TITLE}"
fi
echo -e ""
echo -e "\e[92m  Setting up ${COMPONENT_NAME}...\e[97m"
echo -e ""
echo -e "\e[93m  ------------------------------------------------------------------------------\e[96m"
echo -e ""

## CHECK FOR PREREQUISITE PACKAGES

echo -e "\e[95m  Installing packages needed to fulfill dependencies for ${COMPONENT_NAME}...\e[97m"
echo -e ""
# Required by install script.
CheckPackage git
CheckPackage curl
# Required for USB SDR devices.
CheckPackage librtlsdr-dev
CheckPackage libusb-1.0-0-dev
CheckPackage rtl-sdr
# Required by component.
CheckPackage build-essential
CheckPackage debhelper
CheckPackage python-dev
CheckPackage python3-dev
echo -e ""
echo -e "\e[95m  Configuring this device to run the ${COMPONENT_NAME} binaries...\e[97m"
echo -e ""

## DOWNLOAD OR UPDATE THE COMPONENT SOURCE

if [[ true ]] ; then
    # Download from github.
    COMPONENT_GITHUB_URL_SHORT=`echo ${COMPONENT_GITHUB_URL} | sed -e 's/http:\/\///g' -e 's/https:\/\///g' | tr '[A-Z]' '[a-z]'`
    COMPONENT_GITHUB_PROJECT=`echo ${COMPONENT_GITHUB_URL} | awk -F "/" '{print $NF}' | sed -e 's/\.git$//g'`
    COMPONENT_BUILD_DIRECTORY="${RECEIVER_BUILD_DIRECTORY}/${COMPONENT_GITHUB_PROJECT}"

    echo -e ""
    echo -e "\e[95m  Preparing the ${COMPONENT_NAME} Git repository...\e[97m"
    echo -e ""

    # Check if already installed and located where we would expect it to be.
    if [[ -x `which mlat-client` ]] && [[ -d ${COMPONENT_BUILD_DIRECTORY}/.git ]] ; then
        # A directory containing the source code exists, checking if this can be update from github.
        echo -e "\e[94m  Entering the ${COMPONENT_NAME} git repository directory...\e[97m"
        cd ${COMPONENT_BUILD_DIRECTORY} 2>&1
        CheckReturnCode
        ACTION=$(git remote update 2>&1)
        if [[ `git status -uno | grep -c "is behind"` -gt 0 ]] ; then
            # Local branch is behind remote so update.
            echo -en "\e[33m  Updating ${COMPONENT_GITHUB_PROJECT} from \"\e[37m${COMPONENT_GITHUB_URL_SHORT}\e[33m\"...\e[97m"
            ACTION=$(git pull 2>&1)
            DO_INSTALL_FROM_GIT="true"
        else
            echo -en "\e[33m  Local ${COMPONENT_GITHUB_PROJECT} repository is up to date with \"\e[37m${COMPONENT_GITHUB_URL_SHORT}\e[33m\"...\e[97m"
        fi
    else
        # A directory containing the source code does not exist in the build directory.
        echo -en "\e[33m  Cloning ${COMPONENT_GITHUB_PROJECT} from \"\e[37m${COMPONENT_GITHUB_URL_SHORT}\e[33m\"...\e[97m"
        ACTION=$(git clone https://${COMPONENT_GITHUB_URL_SHORT} ${COMPONENT_BUILD_DIRECTORY} 2>&1)
        DO_INSTALL_FROM_GIT="true"
    fi
    CheckReturnCode

    # Compile and install.
    if [[ "${DO_INSTALL_FROM_GIT}" = "true" ]] ; then
        echo -e ""
        echo -e "\e[95m  Building and installing the ${COMPONENT_NAME} package...\e[97m"
        echo -e ""
        if [[ ! "${PWD}" = ${COMPONENT_BUILD_DIRECTORY} ]] ; then
            echo -e "\e[94m  Entering the ${COMPONENT_NAME} git repository directory...\e[97m"
            echo -e ""
            cd ${COMPONENT_BUILD_DIRECTORY} 2>&1
        fi
        # Build binary package.
        echo -e "\e[94m  Building the ${COMPONENT_NAME} package...\e[97m"
        echo -e ""
        dpkg-buildpackage -b -uc 2>&1
        echo -e ""
        # Install binary package.
        echo -e "\e[94m  Installing the ${COMPONENT_NAME} package...\e[97m"
        echo -e ""
        sudo dpkg -i ${RECEIVER_BUILD_DIRECTORY}/mlat-client_${MLAT_CLIENT_VERSION}*.deb 2>&1
        echo -e ""
        # Create binary archive directory.
        if [[ ! -d "${BINARIES_DIRECTORY}" ]] ; then
            echo -e "\e[94m  Creating archive directory...\e[97m"
            echo -e ""
            mkdir -v ${BINARIES_DIRECTORY} 2>&1
            echo -e ""
        fi
        # Archive binary package.
        echo -e "\e[94m  Archiving the ${COMPONENT_NAME} package...\e[97m"
        echo -e ""
        for LOCAL_FILE in `ls ${RECEIVER_BUILD_DIRECTORY}/mlat-client_* ${BINARIES_DIRECTORY}
            mv -v -f ${LOCAL_FILE} ${BINARIES_DIRECTORY} 2>&1
        done
        echo -e ""

        # Check that the mlat-client package was installed successfully.
        echo -e ""
        echo -e "\e[94m  Checking that the ${COMPONENT_NAME} package was installed properly...\e[97m"
        echo -e ""
        if [[ $(dpkg-query -W -f='${STATUS}' mlat-client 2>/dev/null | grep -c "ok installed") -eq 0 ]] ; then
            # If the mlat-client package could not be installed halt setup.
            echo -e ""
            echo -e "\e[91m  \e[5mINSTALLATION HALTED!\e[25m"
            echo -e "  UNABLE TO INSTALL A REQUIRED PACKAGE."
            echo -e "  SETUP HAS BEEN TERMINATED!"
            echo -e ""
            echo -e "\e[93mThe package \"${COMPONENT_NAME}\" could not be installed.\e[39m"
            echo -e ""
            echo -e "\e[93m  ------------------------------------------------------------------------------"
            echo -e "\e[92m  ADS-B Exchange feed setup halted.\e[39m"
            echo -e ""
            if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "false" ]] ; then
                read -p "Press enter to continue..." CONTINUE
            fi
            exit 1
        fi
    else
        echo -en "\e[33m  ${COMPONENT_GITHUB_PROJECT} is already installed..."
    fi
    CheckReturnCode
    unset DO_INSTALL_FROM_GIT
fi

### SETUP COMPLETE

# Return to the project root directory.
echo -en "\e[94m  Returning to ${RECEIVER_PROJECT_TITLE} root directory...\e[97m"
cd ${RECEIVER_ROOT_DIRECTORY} 2>&1
ACTION=${PWD}
CheckReturnCode

echo -e "\e[93m  ------------------------------------------------------------------------------\n"
echo -e "\e[92m  ${COMPONENT_NAME} setup is complete.\e[39m"
echo -e ""
if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "false" ]] ; then
    read -p "Press enter to continue..." CONTINUE
fi

exit 0
