#!/bin/bash
echo "without flags---------------------------" > $2;
od $1 >> $2;
for flag in a b c d f
do
    echo "flag = -$flag---------------------------" >> $2;
    od -$flag $1 >> $2;

done