#! /bin/bash


#$1 - name of checked directory
checkDir(){

cd $1;

i=0;

fileName="";
fileParams="";
fileParamsNumber=2;
fileNameNumber=10;

for fileInf in $(ls -l)
do 

	if [[ $i == $fileParamsNumber ]]
	then
		fileParams=$fileInf;
		((fileParamsNumber+=9));
		echo "fileParams = $fileParams";
	elif [[ $i == $fileNameNumber ]]
	then
		fileName=$fileInf;
		((fileNameNumber+=9));
		echo "fileName = $fileName";
		typeOfFile=$(echo  $fileParams | cut -c1);
		listContains $typeOfFile;
		if [[ $containsResult == 0 ]]
		then
			listOfTypes=$listOfTypes$typeOfFile;
			((lengthOfList++));
			echo "lengthOfList  = $lengthOfList";
			echo "listOfTypes = $listOfTypes";
		fi
		echo "listOfTypes  = '$listOfTypes'";
		echo -e "i = $i\n------------\n"
	fi
	((i++));
	

done


}

#$1 - checked type
listContains(){

containsResult=0;
for ((j=1 ; j <= $lengthOfList ; j++))
do 
	
	checkedSymbol=$(echo $listOfTypes | cut -c$j);
	
	if [[ $checkedSymbol == $1 ]]
	then 
		containsResult=1;
	fi
	
	
done

}





#$1 - address of checked directory

listOfTypes="";
lengthOfList=0;
containsResult=0;

checkDir $1;



