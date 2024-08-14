#!/bin/bash

## PRE INSTALLATION OPERATIONS

source $RECEIVER_BASH_DIRECTORY/variables.sh
source $RECEIVER_BASH_DIRECTORY/functions.sh

clear
log_project_title
log_title_heading "Setting up the FlightAware Dump1090 decoder"
log_title_message "------------------------------------------------------------------------------"
if ! whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" \
              --title "FlightAware Dump1090 Decoder Setup" \
              --yesno "FlightAware Dump1090 is an ADS-B, Mode S, and Mode 3A/3C demodulator and decoder that will receive and decode aircraft transponder messages received via a directly connected software defined radio, or from data provided over a network connection.\n\nWebsite: https://www.flightaware.com/\nGitHub Repository: https://github.com/flightaware/dump1090\n\nWould you like to begin the setup process now?" \
              14 78; then
    echo ""
    log_alert_heading "INSTALLATION HALTED"
    log_alert_message "Setup has been halted at the request of the user"
    echo ""
    log_title_message "------------------------------------------------------------------------------"
    log_title_heading "FlightAware Dump1090 decoder setup halted"
    echo ""
    exit 1
fi


## GATHER REQUIRED INFORMATION FROM THE USER

log_heading "Gather information required to configure the decoder(s)"

log_message "Checking if an ADS-B decoder is installed"
adsb_decoder_installed="false"
if [[ $(dpkg-query -W -f='${STATUS}' dump1090-fa 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
    log_message "An ADS-B decoder appears to be installed"
    adsb_decoder_installed="true"
fi

log_message "Checking if a UAT decoder is installed"
uat_decoder_installed="false"
if [[ $(dpkg-query -W -f='${STATUS}' dump978-fa 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
    log_message "A UAT decoder appears to be installed"
    uat_decoder_installed="true"
fi

log_message "Checking if an ACARS decoder is installed"
acars_decoder_installed="false"
if [[ -f /usr/local/bin/acarsdec ]]; then
    log_message "An ACARS decoder appears to be installed"
    acars_decoder_installed="true"
fi

if [[ "${uat_decoder_installed}" == "true" || "${acars_decoder_installed}" == "true" ]]; then
    log_message "Informing the user that existing decoder(s) appears to be installed"
    whiptail --backtitle "ACARSDEC Decoder Configuration" \
             --title "RTL-SDR Dongle Assignments" \
             --msgbox "It appears that existing decoder(s) have been installed on this device. In order to run ACARSDEC in tandem with other decoders you will need to specifiy which RTL-SDR dongle each decoder is to use.\n\nKeep in mind in order to run multiple decoders on a single device you will need to have multiple RTL-SDR devices connected to your device." \
             12 78

    if [[ "${uat_decoder_installed}" == "true" ]]; then
        log_message "Determining which device is currently assigned to the UAT decoder"
        receiver_options=`get_config "RECEIVER_OPTIONS" "/etc/default/dump978-fa"`
        current_uat_device_number=$receiver_options | grep -o -P '(?<=serial=).*(?= --)'
        log_message "Asking the user to assign a RTL-SDR device number to the UAT decoder"
        uat_device_number_title="Enter the UAT Decoder RTL-SDR Device Number"
        while [[ -z $uat_device_number ]] ; do
            uat_device_number=$(whiptail --backtitle "ACARSDEC Decoder Configuration" \
                                         --title "${uat_device_number_title}" \
                                         --inputbox "\nEnter the RTL-SDR device number to assign your UAT decoder." \
                                         8 78 \
                                         "${current_uat_device_number}" 3>&1 1>&2 2>&3)
            exit_status=$?
            if [[ $exit_status != 0 ]]; then
                log_alert_heading "INSTALLATION HALTED"
                log_alert_message "Setup has been halted due to lack of required information"
                echo ""
                log_title_message "------------------------------------------------------------------------------"
                log_title_heading "FlightAware Dump1090 decoder setup halted"
                exit 1
            fi
            uat_device_number_title="Enter the UAT Decoder RTL-SDR Device Number (REQUIRED)"
        done
    fi

    if [[ "${acars_decoder_installed}" == "true" ]]; then
        log_message "Determining which device is currently assigned to the UAT decoder"
        exec_start=`get_config "ExecStart" "/etc/systemd/system/acarsdec.service"`
        current_acars_device_number=`echo $exec_start | grep -o -P '(?<=-r ).*(?= -A)'`
        log_message "Asking the user to assign a RTL-SDR device number to ACARSDEC"
        acars_device_number_title="Enter the ACARSDEC RTL-SDR Device Number"
        while [[ -z $acars_device_number ]] ; do
            acars_device_number=$(whiptail --backtitle "ACARSDEC Decoder Configuration" \
                                           --title "${acars_device_number_title}" \
                                           --inputbox "\nEnter the RTL-SDR device number to assign your ACARSDEC decoder." \
                                           8 78 \
                                           "${current_acars_device_number}" 3>&1 1>&2 2>&3)
            exit_status=$?
            if [[ $exit_status != 0 ]]; then
                log_alert_heading "INSTALLATION HALTED"
                log_alert_message "Setup has been halted due to lack of required information"
                echo ""
                log_title_message "------------------------------------------------------------------------------"
                log_title_heading "FlightAware Dump1090 decoder setup halted"
                exit 1
            fi
            acars_device_number_title="Enter the ACARSDEC RTL-SDR Device Number (REQUIRED)"
        done
    fi

    current_adsb_device_number=""
    if [[ "${absb_decoder_installed}" == "true" ]]; then
        log_message "Determining which device is currently assigned to the ADS-B decoder"
        current_adsb_device_number=`get_config "RECEIVER_SERIAL" "/etc/default/dump1090-fa"`
    fi
    log_message "Asking the user to assign a RTL-SDR device number to the ADS-B decoder"
    adsb_device_number_title="Enter the ADS-B Decoder RTL-SDR Device Number"
    while [[ -z $adsb_device_number ]] ; do
        adsb_device_number=$(whiptail --backtitle "ACARSDEC Decoder Configuration" \
                                      --title "${adsb_device_number_title}" \
                                      --inputbox "\nEnter the RTL-SDR device number to assign your ADS-B decoder." \
                                      8 78 \
                                      "${current_adsb_device_number}" 3>&1 1>&2 2>&3)
        exit_status=$?
        if [[ $exit_status != 0 ]]; then
            log_alert_heading "INSTALLATION HALTED"
            log_alert_message "Setup has been halted due to lack of required information"
            echo ""
            log_title_message "------------------------------------------------------------------------------"
            log_title_heading "FlightAware Dump1090 decoder setup halted"
            exit 1
        fi
        adsb_device_number_title="Enter the ADS-B Decoder RTL-SDR Device Number (REQUIRED)"
    done
fi


## CHECK FOR PREREQUISITE PACKAGES

log_heading "Installing packages needed to fulfill FlightAware Dump1090 decoder dependencies"

check_package build-essential
check_package debhelper
check_package devscripts
check_package fakeroot
check_package libbladerf-dev
check_package libhackrf-dev
check_package liblimesuite-dev
check_package libncurses-dev
check_package librtlsdr-dev
check_package libsoapysdr-dev
check_package lighttpd
check_package pkg-config


## BLACKLIST UNWANTED RTL-SDR MODULES

log_heading "Blacklist unwanted RTL-SDR kernel modules."

blacklist_modules


## CLONE OR PULL THE FLIGHTAWARE DUMP1090 DECODER SOURCE

log_heading "Preparing the FlightAware Dump1090 Git repository"

if [[ -d $RECEIVER_BUILD_DIRECTORY/dump1090-fa/dump1090 && -d $RECEIVER_BUILD_DIRECTORY/dump1090-fa/dump1090/.git ]]; then
    log_message "Entering the dump1090 git repository directory"
    cd $RECEIVER_BUILD_DIRECTORY/dump1090-fa/dump1090
    log_message "Pulling the dump1090 git repository"
    echo ""
    git pull 2>&1 | tee -a $RECEIVER_LOG_FILE
else
    log_message "Creating the FlightAware dump1090 Project build directory"
    echo ""
    mkdir -v $RECEIVER_BUILD_DIRECTORY/dump1090-fa 2>&1 | tee -a $RECEIVER_LOG_FILE
    echo ""
    log_message "Entering the FlightAware dump1090 Project build directory"
    cd $RECEIVER_BUILD_DIRECTORY/dump1090-fa
    log_message "Cloning the dump1090 git repository"
    echo ""
    git clone https://github.com/flightaware/dump1090.git 2>&1 | tee -a $RECEIVER_LOG_FILE
fi


## BUILD AND INSTALL THE DUMP1090-FA PACKAGE

log_heading "Building the FlightAware dump1090-fa package"

log_message "Entering the dump1090 Git repository"
cd $RECEIVER_BUILD_DIRECTORY/dump1090-fa/dump1090

log_message "Determining which distribution to build the package tree for"
case $RECEIVER_OS_CODE_NAME in
    focal)
        distro="buster"
        ;;
    bullseye|jammy|bookworm|noble)
        distro="bullseye"
        ;;
esac
log_message "Preparing to build dump1090-fa for ${distro}"
echo ""
./prepare-build.sh $distro 2>&1 | tee -a $RECEIVER_LOG_FILE
echo ""
log_message "Entering the package-${distro} directory"
cd $RECEIVER_BUILD_DIRECTORY/dump1090-fa/dump1090/package-$distro
log_message "Building the dump1090-fa Debian package"
echo ""
dpkg-buildpackage -b --no-sign 2>&1 | tee -a $RECEIVER_LOG_FILE
echo ""
log_message "Installing the dump1090-fa Debian package"
echo ""
sudo dpkg -i $RECEIVER_BUILD_DIRECTORY/dump1090-fa/dump1090/dump1090-fa_$DUMP1090_FA_VERSION_*.deb 2>&1 | tee -a $RECEIVER_LOG_FILE
echo ""

log_message "Checking that the dump1090-fa Debian package was installed"
if [[ $(dpkg-query -W -f='${STATUS}' dump1090-fa 2>/dev/null | grep -c "ok installed") -eq 0 ]]; then
    echo ""
    log_alert_heading "INSTALLATION HALTED"
    echo ""
    log_alert_message "The dump1090-fa Debian package failed to install"
    log_alert_message "Setup has been terminated"
    echo ""
    log_title_message "------------------------------------------------------------------------------"
    log_title_heading "FlightAware Dump1090 decoder setup halted"
    echo ""
    read -p "Press enter to continue..." discard
    exit 1
fi

if [[ ! -d $RECEIVER_BUILD_DIRECTORY/package-archive ]]; then
    log_message "Creating the Debian package archive directory"
    echo ""
    mkdir -v $RECEIVER_BUILD_DIRECTORY/package-archive 2>&1 | tee -a $RECEIVER_LOG_FILE
    echo ""
fi
log_message "Copying the dump1090-fa Debian package into the Debian package archive directory"
echo ""
cp -vf $RECEIVER_BUILD_DIRECTORY/dump1090-fa/dump1090/*.deb $RECEIVER_BUILD_DIRECTORY/package-archive/ 2>&1 | tee -a $RECEIVER_LOG_FILE


## CONFIGURATION

if [[ "${uat_decoder_installed}" == "true" || "${acars_decoder_installed}" == "true" ]]; then

    log_heading "Configuring the decoders so they can work in tandem"

    if [[ "${uat_decoder_installed}" == "true" ]]; then
        log_message "Assigning RTL-SDR device number ${uat_device_number} to the FlightAware Dump978 decoder"
        sudo sed -i -e "s/driver=rtlsdr/driver=rtlsdr,serial=${uat_device_number}/g" /etc/default/dump978-fa
        log_message "Restarting dump978-fa"
        sudo systemctl restart dump978-fa
    fi

    if [[ "${acars_decoder_installed}" == "true" ]]; then
        log_message "Assigning RTL-SDR device number ${acars_device_number} to ACARSDEC"
        sudo sed -i -e "s/\(.*-r \)\([0-9]\+\)\( .*\)/\1${acars_device_number}\3/g" /etc/systemd/system/acarsdec.service
        log_message "Reloading systemd units"
        sudo systemctl daemon-reload
        log_message "Restarting ACARSDEC"
        sudo systemctl restart acarsdec
    fi

    log_message "Assigning RTL-SDR device number ${adsb_device_number} to the FlightAware Dump1090 decoder"
    change_config "RECEIVER_SERIAL" $adsb_device_number "/etc/default/dump1090-fa"
    log_message "Restarting dump1090-fa"
    sudo systemctl restart dump1090-fa
fi


## POST INSTALLATION OPERATIONS

log_heading "Performing post installation operations"

log_message "Checking if a heywhatsthat upintheair.json file exists"
if [[ ! -f "/usr/share/dump1090-fa/html/upintheair.json" ]]; then
    log_message "Asking the user if they want to add heywhatsthat maximum range rings"
    if (whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" \
                 --title "Setup heywhaststhat Maximum Range Rings" \
                 --yesno "Maximum range rings can be added to the FlightAware Dump1090 map usings data obtained from heywhatsthat. In order to add these rings to your FlightAware dump1090 map you will first need to visit http://www.heywhatsthat.com and generate a new panorama centered on the location of your receiver. Once your panorama has been generated a link to the panorama will be displayed in the top left hand portion of the page. You will need the view ID which is the series of letters and  numbers after ?view= in the URL.\n\nWould you like to add heywhatsthat maximum range rings to your map?" \
                 16 78); then
        log_message "Asking the user for the heywhatsthat panarama ID"
        heywhatsthat_panorama_id_title="Enter the heywhatsthat Panorama ID"
        while [[ -z $heywhatsthat_panorama_id ]] ; do
            heywhatsthat_panorama_id=$(whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" \
                                                --title "${heywhatsthat_panorama_id_title}" \
                                                --inputbox "Please enter your Heywhatsthat panorama ID." \
                                                8 78 3>&1 1>&2 2>&3)
            whiptail_exit_status=$?
            if [[ $whiptail_exit_status != 0 ]]; then
                log_alert_message "Setup of heywhatsthat maximum range rings was cancelled"
                break
            fi
            heywhatsthat_panorama_id_title="Enter the Heywhatsthat Panorama ID [REQUIRED]"
        done
	if [[ $whiptail_exit_status == 0 ]]; then
            log_message "Asking the user what the altitude is for the first ring"
            heywhatsthat_ring_one_altitude_title="First heywhatsthat Ring Altitude"
            while [[ -z $heywhatsthat_ring_one_altitude ]] ; do
                heywhatsthat_ring_one_altitude=$(whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" \
                                                          --title "${heywhatsthat_ring_one_altitude_title}" \
                                                          --nocancel \
                                                          --inputbox "Enter the first ring's altitude in meters.\n(default 3048 meters or 10000 feet)" \
                                                          8 78 \
                                                          "3048" 3>&1 1>&2 2>&3)
                heywhatsthat_ring_one_altitude_title="First heywhatsthat Ring Altitude [REQUIRED]"
            done
            log_message "Asking the user what the altitude is for the second ring"
            heywhatsthat_ring_two_altitude_title="Second heywhatsthat Ring Altitude"
            while [[ -z $heywhatsthat_ring_two_altitude ]] ; do
                heywhatsthat_ring_two_altitude=$(whiptail --backtitle "${RECEIVER_PROJECT_TITLE}" \
                                                          --title "${heywhatsthat_ring_two_altitude_title}" \
                                                          --nocancel \
                                                          --inputbox "Enter the second ring's altitude in meters.\n(default 12192 meters or 40000 feet)" \
                                                          8 78 \
                                                          "12192" 3>&1 1>&2 2>&3)
                heywhatsthat_ring_two_altitude_title="Second heywhatsthat Ring Altitude [REQUIRED]"
            done

            log_message "Downloading JSON data file assigned to panorama ID ${heywhatsthat_panorama_id}"
            echo ""
            sudo wget -v -O /usr/share/skyaware/html/upintheair.json "http://www.heywhatsthat.com/api/upintheair.json?id=${heywhatsthat_panarama_id}&refraction=0.25&alts=${heywhatsthat_ring_one_altitude},${heywhatsthat_ring_two_altitude}" 2>&1 | tee -a $RECEIVER_LOG_FILE
            echo ""
            log_message "Heywhatsthat configuration complete"
        fi
    else
        log_message "Heywhatsthat maximum range rings was skipped"
    fi
fi


## SETUP COMPLETE

log_message "Returning to ${RECEIVER_PROJECT_TITLE} root directory"
cd $RECEIVER_ROOT_DIRECTORY

echo ""
log_title_message "------------------------------------------------------------------------------"
log_title_heading "FlightAware Dump1090 decoder setup is complete"
echo ""
read -p "Press enter to continue..." discard

exit 0
