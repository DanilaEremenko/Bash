#! /bin/bash
#$1 - directory
#$2 - chmod 

find $1 -name '*.sh' -exec chmod $2 {} \;
