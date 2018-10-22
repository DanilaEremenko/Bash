#! /bin/bash

#$1 - file whose links we're looking for
#$2 - checked directory
#$3 - outputFileName

if [ $# == 2 ]
then
	ls -lR $2 | grep ^l.*$1 | cat -n;
elif [ $# == 3 ]
then
	ls -lR $2 | grep ^l.*$1 | cat -n > $3;
else
	echo "Illegal number of arguments";
fi 