#! /bin/bash

#$1 - address of output file

if [ $# == 1 ]
then
	ls -R -l /dev |sort -n |uniq -w1  > $1;
elif [ $# == 0 ]
then
	ls -R -l /dev |sort -n |uniq -w1;
else
	echo "Illegal number of arguments";
fi 