#!/bin/bash
# BSD 3-Clause License
#
# Copyright 2022 Hewlett Packard Enterprise Development LP
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from this
# software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

BASE_DIR=$(pwd)
WORK_DIR=/tmp/emu.tmp

ASYNC_SLEEP=0
API_PORT=443
MOCKUP=DL380a
SETUP_ONLY=
AUTH=

function print_help {
    cat <<EOF

Helper to set up a Swordfish emulator. This will take care of getting the
necessary source files ready and start a local instance of the emulator.

USAGE:

    $(basename $0) [--port PORT] [--workspace DIR] [--no-start] [--auth AUTH_STR] [--mockup MOCKUP] [--async-sleep SLEEP]

Options:

    -p | --port PORT     -- Port to run the emulator on. Default is $API_PORT.

    -w | --workspace DIR -- Directory to set up the emulator. Defaults to
                            '$WORK_DIR'.

    -n | --no-start      -- Prepare the emulator but do not start it.

    -a | --auth AUTH_STR -- Specify initial set of credentials for Basic
                            authorization for contacting the emulator.
                            (<username1>:<password1>:<role1>;<username2>:<password2>:<role2>...)
    -m | --mockup MOCKUP -- Specify the mockup type for this emulator.

    -s | --async-sleep SLEEP -- Specify the sleep time in seconds for simulated async operations.
                            Default is $ASYNC_SLEEP seconds.

EOF
}

# Extract command line args
while [ "$1" != "" ]; do
    case $1 in
        -p | --port )
            shift
            API_PORT=$1
            ;;
        -w | --workspace )
            shift
            WORK_DIR=$1
            ;;
        -n | --no-start)
            SETUP_ONLY="true"
            ;;
        -a | --auth )
            shift
            AUTH=$1
            ;;
        -m | --mockup )
            shift
            MOCKUP=$1
            ;;
        -s | --async-sleep )
            shift
            ASYNC_SLEEP=$1
            ;;
        *)
            print_help
            exit 1
    esac
    shift
done

# Do some system sanity checks first
if ! [ -x "$(command -v python3)" ]; then
    echo "Error: python3 is required to run the emulator and executable not" \
         "found"
    echo ""
    echo "See https://www.python.org/downloads/ for installation instructions."
    echo ""
    exit 1
fi

if ! [ -x "$(command -v virtualenv)" ]; then
    echo "Error: virtualenv is required."
    echo ""
    echo "See https://virtualenv.pypa.io/en/stable/installation/ for" \
         "installation instructions."
    echo ""
    exit 1
fi

if ! [ -x "$(command -v git)" ]; then
    echo "Error: git is required."
    echo ""
    echo "See https://git-scm.com/book/en/v2/Getting-Started-Installing-Git" \
         "for installation instructions."
    echo ""
    exit 1
fi

echo "Creating workspace: '$WORK_DIR'..."
rm -fr $WORK_DIR
mkdir $WORK_DIR

# Get the Redfish base
# echo "Getting Redfish emulator base files..."
# git clone --depth 1 https://github.com/DMTF/Redfish-Interface-Emulator \
#    $WORK_DIR



# Copy over BMI bits
echo "Applying BMI additions..."
cp -r -f $BASE_DIR/src/* $WORK_DIR/
cp -r -f $BASE_DIR/mockups/ $WORK_DIR/api_emulator/redfish/static/

# Set up our virtual environment
echo "Setting up emulator Python virtualenv and requirements..."
cd $WORK_DIR
virtualenv --python=python3 venv
venv/bin/pip install -q -r requirements.txt

echo "Setting up credentials $AUTH"
export AUTH_CONFIG=$AUTH
export MOCKUP_FOLDER=$MOCKUP
export ASYNC_SLEEP=$ASYNC_SLEEP

if [ "$SETUP_ONLY" == "true" ]; then
    echo ""
    echo "Emulator files have been prepared. Run the following to start the" \
         "emulator:"
    echo ""
    echo "   cd $WORK_DIR"
    echo "   ./venv/bin/python emulator.py"
    echo ""
    exit 0
fi

# Start up the emulator
cat <<EOF

---------------------------------------------------------------------
Starting CSM Redfish Interface Emulator. Access the local instance using the URL:

   http://localhost:$API_PORT

$(tput bold)Press Ctrl-C when done.$(tput sgr0)
---------------------------------------------------------------------
EOF

venv/bin/python emulator.py -port $API_PORT

echo ""
echo "Emulator can be rerun from '$WORK_DIR' by running the command:"
echo ""
echo "./venv/bin/python emulator.py"
echo ""
