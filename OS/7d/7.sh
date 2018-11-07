#! /bin/bash
#$1 - testing directory

touch testReport;

maxFileNumber=1000000;

cd $1;

while [[ 1 ]]
do
    #File creating
    for (( i=0 ; i < $maxFileNumber ; i++ ))
    do
        touch "tFile$i";
    done

    echo "--------------------------------------------------" >> "../testReport";
    echo "MAX FILES NUMBER" >> "../testReport";
    ls -l | wc  >> "../testReport";
    echo "--------------------------------------------------" >> "../testReport";
    echo "MAX CAPACITY" >> "../testReport";
    du -h >> "../testReport";
    echo "--------------------------------------------------" >> "../testReport";


    #File removing
    for fileName in $(ls)
    do
        if [[ $( echo $fileName | cut -c1-5 ) == 'tFile' ]]
        then
            rm $fileName;
        fi
    done

done
