#! /bin/sh

for filt in $(find -name 'filter_*')
do
  cp $filt filters/
done
