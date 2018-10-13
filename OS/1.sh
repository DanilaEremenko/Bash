#! /bin/bash


#$1 - name of checked directory
checkDir(){

cd $1;

i=0;

dirName="";
dirParams="";
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


}

#$1 - checked type
listContains(){


for ((i=1 ; i <= $lengthOfList ; i++))
do 
	if [[ $(echo $listOfTypes | cut -c$i) == $1 ]]
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


