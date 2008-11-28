#!/bin/sh

# Author:	Zhang Huangbin <michaelbibby (at) gmail.com>

POTFILE='./iredadmin.pot'
BUGADDR='michaelbibby@gmail.com'

# Extract localizable messages from a collection of source files.
pybabel extract --sort-output --msgid-bugs-address=${BUGADDR} -o ${POTFILE} -F setup.cfg ..

# Create a new translations catalog based on a PO template file.
#pybabel init -i ${POTFILE} -l en_US -d .

# Update an existing new translations catalog based on a PO template file.
#pybabel update -i ${POTFILE} -l en_US -d .
