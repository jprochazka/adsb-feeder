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
# Copyright (c) 2015 Joseph A. Prochazka                                            #
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

#######################################################################
# Detect if a package is installed and if not attempt to install it.

function CheckPackage {
    ATTEMPT=1
    MAXATTEMPTS=5
    WAITTIME=5

    while (( $ATTEMPT -le `(($MAXATTEMPTS + 1))` )); do

        # If the maximum attempts has been reached...
        if [ $ATTEMPT -gt $MAXATTEMPTS ]; then
            echo ""
            echo -e "\e[91m  \e[5mINSTALLATION HALTED!\e[25m"
            echo -e "  UNABLE TO INSTALL A REQUIRED PACKAGE."
            echo -e "  SETUP HAS BEEN TERMINATED!"
            echo ""
            echo -e "\e[93mThe package \"$1\" could not be installed in $MAXATTEMPTS attempts.\e[39m"
            echo ""
            exit 1
        fi

        # Check if the package is already installed.
        printf "\e[94m  Checking if the package $1 is installed..."
        if [ $(dpkg-query -W -f='${STATUS}' $1 2>/dev/null | grep -c "ok installed") -eq 0 ]; then

            # If this is not the first attempt at installing this package...
            if [ $ATTEMPT -gt 1 ]; then
                echo -e "\e[91m  \e[5m[INSTALLATION ATTEMPT FAILED]\e[25m"
                echo -e "\e[94m  Attempting to Install the package $1 again in $WAITTIME seconds (ATTEMPT $ATTEMPT OF $MAXATTEMPTS)..."
                sleep $WAITTIME
            else
                echo -e "\e[91m [NOT INSTALLED]"
                echo -e "\e[94m  Installing the package $1..."
            fi

            # Attempt to install the required package.
            echo -e "\e[97m"
            ATTEMPT=$((ATTEMPT+1))
            sudo apt-get install -y $1
            echo -e "\e[39m"
        else
            # The package appears to be installed.
            echo -e "\e[92m [OK]\e[39m"
            break
        fi
    done
}

#################################################################################
# Change a setting in a configuration file.
# The function expects 3 parameters to be passed to it in the following order.
# ChangeConfig KEY VALUE FILE

function ChangeConfig {
    # Use sed to locate the "KEY" then replace the "VALUE", the portion after the equals sign, in the specified "FILE".
    # This function should work with any configuration file with settings formated as KEY="VALUE".
    sudo sed -i "s/\($1 *= *\).*/\1\"$2\"/" $3
}

function GetConfig {
    # Use sed to locate the "KEY" then read the "VALUE", the portion after the equals sign, in the specified "FILE".
    # This function should work with any configuration file with settings formated as KEY="VALUE".
    sudo sed -n '/^$1=\(.*\)$/s//\1/p' $2
    echo `sed -n "/^$1=\"\(.*\)\"$/s//\1/p" $2`
}

function CommentConfig {
    # Use sed to locate the "KEY" then comment out the line containing it in the specified "FILE".
    sudo sed -i -e "/$1/s/^#*/#/" $2
}

function UncommentConfig {
    # Use sed to locate the "KEY" then uncomment the line containing it in the specified "FILE".
    sudo sed -i -e "/$1/s/^#//" $2
}
