#! /bin/bash


#$1 - name of checked directory
checkDir(){

cd $1;

((checkedDirNumber++));
listOfCheckedDirs="$listOfCheckedDirs\n$1";

i=0;
fileName="";
fileParams="";

for fileInf in $(ls -l | awk '{print $1" "$9}')
do
	
	
	if [[ $(( $i % 2 )) == 1 && $i != 0 ]]
	then
		fileParams=$fileInf;
		#echo "fileParams = $fileParams";
	elif [[ $(($i % 2)) == 0 && $i != 0 ]]
	then
		fileName=$fileInf;
		#echo "fileName = $fileName"
		type=$( echo $fileParams | cut '-c1' )
		listContains $type 
		
		if [[ $containsResult == 0 ]]
		then
			listOfTypes=$listOfTypes$type;
			listOfExamples="$listOfExamples\n$fileName";
			((lengthOfList++));
		fi
		
		containsResult=0;
		
		
		#checked calculating
		if [[ $type == 'd'  && "$checkedDirNumber" -lt "$MAX_DIR_NUMBER" && $RECURS_IS_ALLOWED == 1 ]]
		then
			checkDir $fileName;
		else
			((checkedFilesNumber++));
			listOfCheckedFiles="$listOfCheckedFiles\n$fileName";
		fi
	fi
	
	#echo -e "\n-----------------------------\n";
	((i++));
	

done

i=0;

cd .. ;


}

#$1 - checked type
listContains(){


for ((j=1 ; j <= $lengthOfList ; j++))
do 
	if [[ $(echo $listOfTypes | cut -c$j) == $1 ]]
	then 
		containsResult=1;
		j=$lengthOfList;
	fi
	
#	echo "$listOfTypes";
#	if [[ $containsResult == 0 ]]
#	then
#		echo "NOT CONTAINS"; 
#	elif [[ $containsResult == 1 ]]
#	then
#		echo "CONTAINS";
#	fi
#	echo $1;
done

}





#$1 - address of checked directory


#GC
MAX_DIR_NUMBER=20;
RECURS_IS_ALLOWED=0;

#GV
containsResult=0;

#GV for report
listOfTypes="";
lengthOfList=0;
listOfExamples="";

checkedFilesNumber=0;
listOfCheckedFiles="";

checkedDirNumber=0;
listOfCheckedDirs="";

#------------------------

checkDir $1;

echo -e "listOfTypes:$listOfTypes\n";
echo -e "listOfExamples:$listOfExamples\n";
echo -e "lengthOfList = $lengthOfList\n";
echo -e "checkedDirNumber = $checkedDirNumber\n";
echo -e "checkedFilesNumber = $checkedFilesNumber\n";

echo -e "listOfCheckedFiles:\n$listOfCheckedFiles\n";
echo -e "listOfCheckedDirs:\n$listOfCheckedDirs\n";
