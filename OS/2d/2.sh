#! /bin/bash

#$1 - file whose links we're looking for
#$2 - address of output file

#input example:
#/home/danila/snap/notepad-plus-plus/124/notepad-plus-plus/localization/afrikaans.xml

if [ $# == 1 ]
then
	ls -R -li /home | grep `ls -i $1 | cut -d " " -f 1`;
elif [ $# == 2 ]
then
	ls -R -li /home | grep `ls -i $1 | cut -d " " -f 1` > $2;
else
	echo "Illegal number of arguments";
fi 