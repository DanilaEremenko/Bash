#! /bin/bash

touch report
MAX_FILES_IN_DIR=3
dirNumber=0
filesNumber=0
error=false
errorsIndexes=''

echo -e '\t\t\tReport\n\n\n' > report 
#Получаем список нужных директорий
for dirName in $(ls -l | grep lis_| awk '{print $9}')
do 	
	 
	echo -e "Number of Listing = $dirNumber" >> report

	((dirNumber++))
	
	cd $dirName

	echo -e "\tParsed files:"
	filesInDir=0	
	
		

	#Получаем список файлов в директории	
	for fileName in $(ls -l | grep rw-| awk '{print $9}') 
	do	
		
		
		#Определяем тип файла
		type=$(echo $fileName | cut -d '.' -f2) 
		echo "type = $type"
		
		
		if [ "$type" == "in" ]
		then
			((filesInDir++))
			((filesNumber++))
			echo 'Input added'
			echo 'Input :' >> ../report
		elif [ "$type" == "out" ]
		then
			((filesInDir++))
			((filesNumber++))
			echo 'Output added'
			echo 'Output :' >> ../report 
		elif [ "$type" == "l" ]
		then
			((filesInDir++))
			((filesNumber++))
			echo 'Lex code Added'
			echo 'lexFile :' >> ../report 
		fi
	
		#Запсываем содержимое файла в report
		cat $fileName >> ../report
		echo "$fileName parsed" 
		echo -e '------------------------' >>../report
	done
	
	if [ $filesInDir != $MAX_FILES_IN_DIR ]
	then
		errorsIndexes+=" $dirName"
		error=true
	fi
	echo "Founded files in dir = $filesInDir"

	cd ..
	echo -e "\n\n\n\n\n" >> report

	echo "-----------------------------------"	
done

echo "Number of dirs = $dirNumber"
echo "Number of files = $filesNumber"

if [ $error ]
then
	echo $errorsIndexes
fi
