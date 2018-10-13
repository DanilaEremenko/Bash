#! /bin/bash


#i=3;

#if [ $(($i % 3)) == 0 ];
#then 
#echo "true";
#else 
#echo "false";
#fi

i=1;

if [[ $(echo abc | cut -c$i) == a ]]
then 
echo true;
else 
echo false;
fi
