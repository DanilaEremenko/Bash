#WORK WITH NUMBERS AND LOOP-------------------------------------------------------------
dirParamsNumber=2;
dirNameNumber=10;

for dirInf in $(ls -l)
do

	if [[ $i == $dirParamsNumber ]]
	then
		dirParams=$dirInf;
		((dirParamsNumber+=9));
		echo "dirParams = $dirParams";
	elif [[ $i == $dirNameNumber ]]
	then
		dirName=$dirInf;
		((dirNameNumber+=9));
		echo "dirName = $dirName";
	fi
	echo -e "i = $i\n------------\n"
	((i++));


done


#Comparing of digit
if [ "$a" -lt "$b" ]
then 
	echo true;
else 
	echo false;
fi 
