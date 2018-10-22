#! /bin/bash
#$1 - checked directory

for type in b c d p f l s d
do
find $1 -type $type -ls > "type_$type";

done 