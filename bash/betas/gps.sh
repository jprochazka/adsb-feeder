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

PACKAGES="gpsd gpsd-clients libcap-dev libssl-dev ntpdate pps-tools python-gps texinfo timelimit"
SERVICES_DISABLE="hciuart serial-getty@ttyAMA0.service serial-getty@ttyS0.service ntp.service gpsd.socket gpsd.service"
SERVICES_ENABLE="gpsd.service ntp.service"
BOOT_CONFIG="/boot/config.txt"
GPS_TTY_DEV="ttyAMA0"
GPS_PPS_DEV="pps0"
GPS_SYMLINK_RULE="/etc/udev/rules.d/10-pps.rules"
GPS_SERVICE_CONFIG="/etc/default/gpsd"
NTP_DHCP_HOOK="/lib/dhcpcd/dhcpcd-hooks/50-ntp.conf"
NTP_DHCP_FILE="/var/lib/ntp/ntp.conf.dhcp"

# Component service script variables.

### INCLUDE EXTERNAL SCRIPTS

source ${RECEIVER_BASH_DIRECTORY}/variables.sh
source ${RECEIVER_BASH_DIRECTORY}/functions.sh

# Source the automated install configuration file if this is an automated installation.
if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "true" ]] ; then
    source ${RECEIVER_CONFIGURATION_FILE}
fi

# To be moved to functions.sh

#################################################################################
# Apt install function.

function CheckPackage () {
    if [[ -n $1 ]] ; then
        ACTION=$(sudo apt-get install -y $1 2>&1)
    fi
}

#################################################################################
# Apt remove function.

function Apt_Remove () {
    if [[ -n $1 ]] ; then
        ACTION=$(sudo apt remove $1 2>&1)
    fi
}

#################################################################################
# Apt remove function.

function Apt_Hold () {
    if [[ -n $1 ]] ; then
        ACTION=$(sudo apt-mark hold $1 2>&1)
    fi
}

#################################################################################
# Start a system service.

function Service_Start () {
    if [[ -n $1 ]] ; then
        local LOCAL_SERVICE_NAME="$1"
        local LOCAL_SERVICE_STATUS=$(sudo systemctl status ${LOCAL_SERVICE_NAME} 2>&1)
        if [[ `echo ${LOCAL_SERVICE_STATUS} | egrep "Active:" | egrep -c ": active"` -gt 0 ]] ; then
            echo -en "  Restarting service \"${LOCAL_SERVICE_NAME}\"..."
            ACTION=$(sudo systemctl reload-or-restart ${LOCAL_SERVICE_NAME} 2>&1)
        elif [[ `echo ${LOCAL_SERVICE_STATUS} | egrep "Active:" | egrep -c ": active"` -eq 0 ]] ; then
            echo -en "  Starting service \"${LOCAL_SERVICE_NAME}\"..."
            ACTION=$(sudo systemctl start ${LOCAL_SERVICE_NAME} 2>&1)
        else
            echo -en "  Error: unable to start service \"$1\"..."
            false
        fi
    else
        echo -en "  Error: no service provided..."
    fi
}

#################################################################################
# Stop a system service.

function Service_Stop () {
    if [[ -n $1 ]] ; then
        local LOCAL_SERVICE_NAME="$1"
        local LOCAL_SERVICE_STATUS=$(sudo systemctl status ${LOCAL_SERVICE_NAME} 2>&1)
        if [[ `echo ${LOCAL_SERVICE_STATUS} | egrep "Active:" | egrep -c ": active"` -gt 0 ]] ; then
            echo -en "  Stopping service \"${LOCAL_SERVICE_NAME}\"..."
            ACTION=$(sudo systemctl stop ${LOCAL_SERVICE_NAME} 2>&1)
        elif [[ `echo ${LOCAL_SERVICE_STATUS} | egrep "Active:" | egrep -c ": inactive"` -gt 0 ]] ; then
            # echo -en "  Service \"${LOCAL_SERVICE_NAME}\" already stopped..."
            true
        else
            echo -en "  Error: unable to stop service \"${LOCAL_SERVICE_NAME}\"..."
            false
        fi
    else
        echo -en "  Error: no service provided..."
    fi
}

#################################################################################
# Enable a system service.

function Service_Enable () {
    if [[ -n $1 ]] ; then
        local LOCAL_SERVICE_NAME="$1"
        local LOCAL_SERVICE_STATUS=$(sudo systemctl status ${LOCAL_SERVICE_NAME} 2>&1)
        if [[ `echo ${LOCAL_SERVICE_STATUS} | egrep "Loaded:" | egrep -c "; enabled"` -eq 0 ]] ; then
            echo -en "  Enabling service \"${LOCAL_SERVICE_NAME}\"..."
            ACTION=$(sudo systemctl enable ${LOCAL_SERVICE_NAME} 2>&1)
        elif [[ `echo ${LOCAL_SERVICE_STATUS} | egrep "Loaded:" | egrep -c "; enabled"` -gt 0 ]] ; then
            #echo -en "  Service \"${LOCAL_SERVICE_NAME}\" already enabled..."
            true
        else
            echo -en "  Error: unable to enable service \"${LOCAL_SERVICE_NAME}\"..."
            false
        fi
    else
        echo -en "  Error: no service provided..."
        false
    fi
}

#################################################################################
# Disable a system service.

function Service_Disable () {
    if [[ -n $1 ]] ; then
        local LOCAL_SERVICE_NAME="$1"
        local LOCAL_SERVICE_STATUS=$(sudo systemctl status ${LOCAL_SERVICE_NAME} 2>&1)
        if [[ `echo ${LOCAL_SERVICE_STATUS} | egrep "Loaded:" | egrep -c "; enabled"` -gt 0 ]] ; then
            echo -en "  Disabling service \"${LOCAL_SERVICE_NAME}\"..."
            ACTION=$(sudo systemctl disable ${LOCAL_SERVICE_NAME} 2>&1)
        elif [[ `echo ${LOCAL_SERVICE_STATUS} | egrep "Loaded:" | egrep -c "; disabled"` -gt 0 ]] ; then
            #echo -en "  Service \"$1\" already disabled..."
            true
        else
            echo -en "  Error: unable to disable service \"${LOCAL_SERVICE_NAME}\"..."
            false
        fi
    else
        echo -en "  Error: no service provided..."
        false
    fi
}

#################################################################################
# Check if I2C is enabled, if not use raspi-config to enable it.

function Enable_I2C () {
    if [[ `sudo raspi-config nonint get_i2c 2>&1` -eq 1 ]] ; then
        echo -en "\e[33m  Enabling I2C interface...\e[97m"
        ACTION=$(sudo raspi-config nonint do_i2c 0 2>&1)
    else
        echo -en "\e[33m  I2C interface support already enabled...\e[97m"
    fi
}

#################################################################################
# Check if SPI is enabled, if not use raspi-config to enable it.

function Enable_SPI () {
    if [[ `sudo raspi-config nonint get_spi 2>&1` -eq 1 ]] ; then
        echo -en "\e[33m  Enabling SPI interface...\e[97m"
        ACTION=$(sudo raspi-config nonint do_spi 0 2>&1)
        REBOOT_REQUIRED="true"
    else
        echo -en "\e[33m  SPI interface support already enabled...\e[97m"
    fi
}

#################################################################################
# Enable serial port on RPi.

function Enable_Serial () {
    if [[ `egrep -c "enable_uart=" ${BOOT_CONFIG}` -eq 0 ]] ; then
        echo -en "  Enabling serial port..."
        if [[ `tail -n1 ${BOOT_CONFIG} | egrep -c "[a-z0-9#]"` -gt 0 ]] ; then
            ACTION=$(echo -en "\n" | tee -a ${BOOT_CONFIG})
            REBOOT_REQUIRED="true"
        fi
        ACTION=$(echo -en "# Enable UART on RPi3\nenable_uart=1\n\n" | tee -a ${BOOT_CONFIG})
    elif [[ `egrep -c "enable_uart=0" ${BOOT_CONFIG}` -eq 1 ]] ; then
        echo -en "  Enabling serial port..."
        ACTION=$(sudo sed -i -e 's/enable_uart=0/enable_uart=1/g' ${BOOT_CONFIG} 2>&1)
    elif [[ `egrep -c "enable_uart=1" ${BOOT_CONFIG}` -eq 1 ]] ; then
        echo -en "  The serial port is already enabled..."
    fi
}

#################################################################################
# Disable Bluetooth on RPi3.

function Disable_Bluetooth () {
    if [[ `egrep -c "(dtoverlay=pi3-disable-bt|dtoverlay=pi3-miniuart-bt)" ${BOOT_CONFIG}` -eq 0 ]] ; then
        echo -en "  Disabling Bluetooth on RPi3..."
        if [[ `tail -n1 ${BOOT_CONFIG} | egrep -c "[a-z0-9#]"` -gt 0 ]] ; then
            ACTION=$(echo -en "\n" | tee -a ${BOOT_CONFIG})
        fi
        ACTION=$(echo -en "# Disabling Bluetooth on RPi3\ndtoverlay=pi3-disable-bt\n\n" | tee -a ${BOOT_CONFIG})
        REBOOT_REQUIRED="true"
    elif [[ `egrep -c "dtoverlay=pi3-disable-bt" ${BOOT_CONFIG}` -gt 0 ]] ; then
        echo -en "  Verifying that Bluetooth is disabled..."
    elif [[ `egrep -c "dtoverlay=pi3-miniuart-bt" ${BOOT_CONFIG}` -gt 0 ]] ; then
        echo -en "  Verifying that Bluetooth was moved to software serial port..."
    fi
}

#################################################################################
# Enable RPi GPIO pin for PPS signal input.

function Enable_PPS () {
    if [[ `egrep -c "dtoverlay=pps-gpio,gpiopin" ${BOOT_CONFIG}` -eq 0 ]] ; then
        echo -en "  Enabling GPS PPS from GPIO pin \"${GPS_PPS_PIN}\"..."
        if [[ `tail -n1 ${BOOT_CONFIG} | egrep -c "[a-z0-9#]"` -gt 0 ]] ; then
            ACTION=$(echo -en "\n" | tee -a ${BOOT_CONFIG})
        fi
        ACTION=$(echo -en "# Enable GPS PPS from GPIO pin ${GPS_PPS_PIN}.\ndtoverlay=pps-gpio,gpiopin=${GPS_PPS_PIN}\n\n" | tee -a ${BOOT_CONFIG})
        REBOOT_REQUIRED="true"
    else
        GPS_PPS_CONFIGURED_PIN=`egrep "dtoverlay=pps-gpio,gpiopin" ${BOOT_CONFIG} | awk -F "=" '{print $3}'`
        echo -en "  GPS PPS already enabled from GPIO pin ${GPS_PPS_CONFIGURED_PIN}..."
    fi
}

#################################################################################
# Check for GPS signals on tty.

function Check_GPS_TTY () {
    if [[ `echo ${GPS_TTY_DEV} | egrep -c "tty"` -gt 0 ]] ; then
        echo -en "  Testing for GPS signal from \"${GPS_TTY_DEV}\"..."
        GPS_TTY_TEST=`timelimit -q -t 3 cat /dev/${GPS_TTY_DEV} 2>&1`
        if [[ `echo "${GPS_TTY_TEST}" | egrep -c "GP(GGA|GLL|GSA|GSV|RMC|VTG)"` -gt 0 ]] ; then
            echo -en "  Success..."
        elif [[ -z "${GPS_TTY_TEST}" ]] ; then
            echo -en "  Error: no data returned by device \"/dev/${GPS_TTY_DEV}\"..."
            false
        else
            echo -en "  Error: no signal detected..."
            false
        fi
    else
        echo -en "  Error: GPS device not found at \"/dev/${GPS_TTY_DEV}\"..."
        false
    fi
}

#################################################################################
# Check for PPS signals.

function Check_GPS_PPS () {
    if [[ `echo ${GPS_PPS_DEV} | egrep -c "pps"` -gt 0 ]] ; then
        echo -en "  Testing for GPS PPS pulses from \"${GPS_PPS_DEV}\"..."
        GPS_PPS_TEST=`timelimit -q -t 3 ppstest /dev/${GPS_PPS_DEV} 2>&1`
        if [[ `echo "${GPS_PPS_TEST}" | egrep -c ", sequence: [0-9]* - clear  [0-9]\."` -gt 0 ]] ; then
            echo -en "  Success..."
        elif [[ `echo "${GPS_PPS_TEST}" | egrep -c "unable to open"` -gt 0 ]] ; then
            echo -en "  Error: no data returned by device \"/dev/${GPS_PPS_DEV}\"..."
            false
        else
            echo -en "  Failed, no signal detected..."
            false
        fi
    else
        echo -en "  Error: PPS device not found at \"/dev/${GPS_PPS_DEV}\"..."
        false
    fi
}

#################################################################################
# Create UDEV Symlink.

function Create_UDEV_Symlink () {
    if [[ ! -f "${GPS_SYMLINK_RULE}" ]] ; then
        echo -en "  Creating device symlinks..."
        ACTION=$(echo -en "KERNEL==\"${GPS_TTY_DEV}\", SYMLINK+=\"gps0\"\nKERNEL==\"${GPS_PPS_DEV}\", OWNER=\"root\", GROUP=\"tty\", MODE=\"0660\", SYMLINK+=\"gpspps0\"\n" | tee ${GPS_SYMLINK_RULE})
        ACTION=$(sudo udevadm trigger 2>&1)
    fi
}

#################################################################################
# Configure GPS service.

function Configure_Service_GPS () {
    if [[ -f "${GPS_SERVICE_CONFIG}" ]] ; then
        KEYPAIRS="START_DAEMON=true USBAUTO=false DEVICES=/dev/gps0 GPSD_OPTIONS=-n GPSD_SOCKET=/var/run/gpsd.sock"
        for LOCAL_KEYPAIR in ${KEYPAIRS} ; do
            local LOCAL_KEY=`echo -E "${LOCAL_KEYPAIR}" | gawk -F "=" '{print $1}'`
            local LOCAL_VALUE=`echo -E "${LOCAL_KEYPAIR}" | gawk -F "=" '{print $2}'`
            local LOCAL_VALUE_ESCAPED=`echo -E "${LOCAL_KEYPAIR}" | gawk -F "=" '{print $2}'| sed -e 's/\\//\\\\\//g'`
            if [[ `grep -c "^${LOCAL_KEY}" ${GPS_SERVICE_CONFIG}` -eq 0 ]] ; then
                if [[ `tail -n1 ${GPS_SERVICE_CONFIG} | egrep -c "[a-z0-9#]"` -gt 0 ]] ; then
                    ACTION=$(echo -en "\n" | tee -a ${GPS_SERVICE_CONFIG})
                fi
                ACTION=$(echo -en "\n# Added by GPS setup.\n${LOCAL_KEY}=\"${LOCAL_VALUE}\"\n\n" | tee -a ${GPS_SERVICE_CONFIG})
            else
                LOCAL_VALUE_CURRENT=`egrep "^${LOCAL_KEY} *= *\"" ${GPS_SERVICE_CONFIG} | awk -F "=" '{print $2}' | sed -e 's/"//g' -e 's/^ //g'`
                if [[ ! "${LOCAL_VALUE_CURRENT}" = "${VALUE}" ]] ; then
                    if [[ -n "${LOCAL_VALUE_ESCAPED}" ]] ; then
                        ACTION=$(sudo sed -i -e "s/^\(${LOCAL_KEY} *= *\).*/\1\"${LOCAL_VALUE_ESCAPED}\"/" ${GPS_SERVICE_CONFIG} 2>&1)
                    fi
                fi
            fi
            unset LOCAL_KEY
            unset LOCAL_VALUE
            unset LOCAL_VALUE_ESCAPED
            unset LOCAL_VALUE_CURRENT
        done
    fi
}

#################################################################################
# Remove DHCP hooks.

function Remove_DHCP_Hooks () {
    if [[ -f "${NTP_DHCP_HOOK}" ]] || [[ -f "${NTP_DHCP_FILES}" ]] ; then
        echo -en "  Prevening DHCP from updating NTP config..."
        ACTION=$(sudo rm -v ${NTP_DHCP_HOOK} ${NTP_DHCP_FILE} 2>&1)
    fi
}

#################################################################################
# Check if a directory exists, if not create it.
function Make_Dir () {
    # Requires: a directory
    if [[ -n "$1" ]] ; then
        if [[ ! -d "$1" ]] ; then
            echo -en "  Creating build directory \"$1\"..."
            ACTION=$(mkdir -v $1)
        else
            echo -en "  Build directory \"$1\" already exists..."
        fi
    else
        false
    fi
}

#################################################################################
# Download latetest source.
function Download_Source_NTP () {
    # Requires: ${NTP_SOURCE_DIR} ${NTP_SOURCE_FILE} ${NTP_SOURCE_URL}
    if [[ -n "${NTP_SOURCE_DIR}" ]] && [[ -n "${NTP_SOURCE_FILE}" ]] && [[ -n "${NTP_SOURCE_URL}" ]] ; then
        ACTION=$(curl -s -L "${NTP_SOURCE_URL}" -o "${NTP_SOURCE_DIR}/${NTP_SOURCE_FILE}")
        if [[ -f "${NTP_SOURCE_DIR}/${NTP_SOURCE_FILE}" ]] ; then
            echo -en  "Source file \"${NTP_SOURCE_FILE}\" downloaded sucessfully..."
        else
            echo -en "  Error: Unable to download source..."
            false
        fi
    else
        echo -en "  Error: Unable to download source..."
        false
    fi
}

#################################################################################
# Verify MD5 of source.
function Verify_Source_NTP () {
    # Requires: ${NTP_SOURCE_DIR} ${NTP_SOURCE_FILE} ${NTP_SOURCE_MD5}
    if [[ -f "${NTP_SOURCE_DIR}/${NTP_SOURCE_FILE}" ]] ; then
         if [[ -n "${NTP_SOURCE_MD5}" ]] ; then
             if [[ `md5sum "${NTP_SOURCE_DIR}/${NTP_SOURCE_FILE}" | awk '{print $1}'` = "${NTP_SOURCE_MD5}" ]] ; then
                 echo -en "  MD5 checksum verified for \"${NTP_SOURCE_FILE}\"..."
             else
                 echo -en "  Error: MD5 mismatch..."
                 false
             fi
        else
            echo -en "  Error: no MD5 supplied..."
            false
        fi
    else
        echo -en "  Error: Unable to access local file \"${NTP_SOURCE_DIR}/${NTP_SOURCE_FILE}\"...."
        false
    fi
}

#################################################################################
# Unpack source.
function Unpack_Source_NTP () {
    # Requires: ${NTP_SOURCE_DIR} ${NTP_SOURCE_FILE} ${NTP_SOURCE_VERSION}
    if [[ -f "${NTP_SOURCE_DIR}/${NTP_SOURCE_FILE}" ]] ; then
        ACTION=$(tar -vxzf "${NTP_SOURCE_DIR}/${NTP_SOURCE_FILE}" -C "${NTP_SOURCE_DIR}")
        if [[ -d "${NTP_SOURCE_DIR}/${NTP_SOURCE_VERSION}" ]] ; then
            echo -en "  Successfully extracted \"${NTP_SOURCE_FILE}\" to \"${NTP_SOURCE_DIR}\"..."
        else
             echo -en "  Error: Unable to extract \"${NTP_SOURCE_FILE}\" to \"${NTP_SOURCE_DIR}\"..."
             false
        fi
    else
        echo -en "  Error: Unable to extract \"${NTP_SOURCE_FILE}\" to \"${NTP_SOURCE_DIR}\"..."
        false
    fi

}

#################################################################################
# Compile source.
function Compile_Source_NTP () {
    # Requires: ${NTP_SOURCE_DIR} ${NTP_SOURCE_VERSION} ${NTP_SOURCE_CFLAGS}
    if [[ -d "${NTP_SOURCE_DIR}/${NTP_SOURCE_VERSION}" ]] ; then
        echo -en "  Compiling \"${NTP_SOURCE_VERSION}\" from source..."
        cd ${NTP_SOURCE_DIR}/${NTP_SOURCE_VERSION} 2>&1
        if [[ `ls -l *.h 2>/dev/null | grep -c "\.h"` -gt 0 ]] ; then
            ACTION=$(sudo make -C "${NTP_SOURCE_DIR}/${NTP_SOURCE_VERSION}" clean 2>&1)
        fi
        if [[ -x "configure" ]] ; then
            ACTION=$(./configure ${NTP_SOURCE_CFLAGS} 2>&1)
        fi
        if [[ -f "Makefile" ]] ; then
            ACTION=$(make -C "${NTP_SOURCE_DIR}/${NTP_SOURCE_VERSION}" 2>&1)
        fi
        if [[ `grep -c "^install:" Makefile` -gt 0 ]] ; then
            ACTION=$(sudo make -C "${NTP_SOURCE_DIR}/${NTP_SOURCE_VERSION}" install 2>&1)
        fi
    else
        echo -en "  Error: build directory not found"
        false
    fi
}

### START CONFIGURATION

echo -en "\n\e[1m  Installing GPS based NTP time server\e[0m\n\n\n"

### INSTALL PACKAGES

for PACKAGE in ${PACKAGES} ; do
    echo -en "  Installing package ${PACKAGE}..."
    CheckPackage ${PACKAGE}
    CheckReturnCode
done

### DISABLE SERVICES

for SERVICE in ${SERVICES_DISABLE} ; do
    echo -en "  Disabling service ${SERVICE}..."
    Service_Stop ${SERVICE}
    Service_Disable ${SERVICE}
    CheckReturnCode
done

### ENABLE SERIAL PORTS

Enable_Serial 
CheckReturnCode

### DISABLE BLUETOOTH

Check_Hardware
CheckReturnCode

if [[ -n "${HARDWARE_REVISION}" ]] ; then
    # Swap serial ports on Raspberry Pi 3.
    if [[ "${HARDWARE_REVISION}" = "a02082" ]] || [[ "${HARDWARE_REVISION}" = "a22082" ]] ; then
        Disable_Bluetooth
        CheckReturnCode
    fi
fi

### CONFIGURE PPS

Enable_PPS
CheckReturnCode

### TEST GPS AND PPS SIGNALS

if [[ "${REBOOT_REQUIRED}" = "true" ]] ; then
    echo -en "\n\e[1m  A Reboot will be required before GPS and PPS signals can be tested! \e[0m"
else
    if [[ -n "${GPS_TTY_DEV}" ]] && [[ -n "${GPS_PPS_DEV}" ]] ; then 
        # Check GPS signal.
        Check_GPS_TTY
        CheckReturnCode
        # And PPS signal.
        Check_GPS_PPS
        CheckReturnCode
    elif [[ -n "${GPS_TTY_DEV}" ]] ; then
        # Otherwise test GPS signal.
        Check_GPS_TTY
        CheckReturnCode
    else
       echo -en "  Unable to run GPS or PPS signal tests..."
    fi
fi

### CREATE SYMLINKS TO GPS AND PPS DEVICES

Create_UDEV_Symlink
CheckReturnCode

### GPSD SERVICE

Configure_Service_GPS
CheckReturnCode
 
### PREVENT DHCP FROM UPDATING NTP CONFIG

Remove_DHCP_Hooks
CheckReturnCode

### INSTALL NTP WITH PPS SUPPORT

NTP_SOURCE_DIR="${PWD}/build/ntp"
NTP_SOURCE_RSS="http://support.ntp.org/rss/releases.xml"
NTP_SOURCE_URL=`curl -s -L "${NTP_SOURCE_RSS}" -o - | grep -A1 "Stable</tit" | grep "<link>" | sed -e 's/<link>//g' -e 's/<\/link>//g' -e 's/\ //g'`
NTP_SOURCE_FILE=`echo ${NTP_SOURCE_URL} | awk -F "/" '{print $NF}'`
NTP_SOURCE_VERSION=`echo ${NTP_SOURCE_FILE} | sed -e 's/.tar.gz//g'`
NTP_SOURCE_MD5=`curl -s -L "${NTP_SOURCE_URL}.md5" -o - |grep "${NTP_SOURCE_FILE}" | awk '{print $1}'`
NTP_SOURCE_CFLAGS=" --enable-all-clocks --enable-parse-clocks --disable-local-libopts --enable-step-slew --without-ntpsnmpd --enable-linuxcaps --prefix=/usr"
MAKE_CFLAGS="-j4"

# Remove system package.
Apt_Remove ntp
CheckReturnCode

# Prevent it from being reinstalled.
Apt_Hold ntp
CheckReturnCode

# Make build directory.
Make_Dir ${NTP_SOURCE_DIR}
CheckReturnCode

# Check if existing source exits and matches expected MD5, if not then download.
until (Verify_Source_NTP && CheckReturnCode) ; do
    Download_Source_NTP
    CheckReturnCode
    sleep 5
done

# Unpack source.
Unpack_Source_NTP
CheckReturnCode

# Compile soure.
Compile_Source_NTP
CheckReturnCode

### RENABLE SERVICES

for SERVICE in ${SERVICES_ENABLE} ; do
    echo -en "  Enabling service ${SERVICE}..."
    Service_Enable ${SERVICE}
    Service_Start ${SERVICE}
    CheckReturnCode
done

# Not sure if this is reqired, but was mentioned in several guides..

if [[ ! -L "/etc/systemd/system/multi-user.target.wants/gpsd.service" ]] ; then
    echo -en "  Possible fix for GPSd failing to launch on startup, TBC..."
    ACTION=$(sudo ln -s /lib/systemd/system/gpsd.service /etc/systemd/system/multi-user.target.wants/ 2>&1)
    CheckReturnCode
fi

### SETUP COMPLETE

# Return to the project root directory.
if [[ ! "${PWD}" = "${RECEIVER_ROOT_DIRECTORY}" ]] ; then
    echo -en "\e[94m  Returning to ${RECEIVER_PROJECT_TITLE} root directory...\e[97m"
    cd ${RECEIVER_ROOT_DIRECTORY} 2>&1
    CheckReturnCode
fi

echo -e "\e[93m  ------------------------------------------------------------------------------\n"
echo -e "\e[92m  Installation of GPS based NTP time server is complete.\e[39m"
echo -e ""
if [[ "${RECEIVER_AUTOMATED_INSTALL}" = "false" ]] ; then
    read -p "Press enter to continue..." CONTINUE
fi

exit 0
