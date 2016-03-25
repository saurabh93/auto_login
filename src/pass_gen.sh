#!/bin/bash

######Description#######
#Genrate Random password encrytion pattern.
#Requires:File with password list or Provide password
#Output: Will be genrated on stdout
########################



array=(5 7 8 3 2 9 4 6 5 8)
tmpfile='tmp'
FILENAME='encrypt.file'
ip_patt='[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'

usage()
{
	ERROR=$1
	ERROR=${ERROR:-No_ERROR}
	echo "ERROR: $ERROR"
	echo -e "
		Usage: $0 [OPTION] [password] [input-file]..
			
		-f
			Specify the fiename containing password.Encrypted password & ip will be redirect to stdout	 	
              		FORMAT: File must contain ip & password on same line seperated with 'space or tab' with each set on new line e.g
	        	192.168.1.1 password1 or 192.168.1.1	password1
		        192.168.1.2 password2
		
		-s	
			Specify password & ip on stdin,output will redirect to stdout
			FORMAT:see e.g below

		-g,	
			Specify two files containing password & ip respectively.Output will be redirected to ${FILENAME}
		        FORMAT: Map both file with there contents i.e first line of passowrd_file, must contain the
				PASSWORD for first IP, in ip_list_file.And Provide absoulte path
		
				
		NOTE: IF MULTIPLE OPTIONS PROVIDED SAME WILL BE PROCESSED IN ABOVE SEQUENCE
	e.g
		$0 -s 'password ip' (sequence should be as shown)
		$0 -f filename
		$0 -g 'file1 file2'
	"
	exit 	
}

logic_encrypt()
{
	local pass=$1 ip=$2
		rand=$(( $RANDOM % ${#array[@]}))
        	iter=${array[$rand]}
                for((i=0;i<iter;i++))
                do
                        pass=$(echo "$pass" | base64 -w 0)
                done
		iter=$(echo $iter | base64);ip=$(echo $ip | base64)
        echo -e "$ip&$pass&$iter"

}
	
while getopts "f:s:g:" arg
do

	case ${arg} in
		
		f)
			file=${OPTARG}
			[[ -s "$file" ]] || usage FILE_NOT_EXIST
			;;
		s)
			std=(${OPTARG})
			[[ "${std[1]}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || usage "Syntax_error=Invalid IP" 
			;;
		g)
			files=(${OPTARG})
			[[ -s "${files[0]}" && -s "${files[1]}" ]] || usage FILES_DOES_NOT_EXIST
	esac
done

if [[ -z "$file" && -z "${std[@]}" && -z "${files[@]}" ]];then
	usage
fi

#if [[ ! -z "$file" && ! -z "$std" ]];then
#	usage "Provide Single input at a time"
#	exit 1
#fi
	
if [[ ! -z "$file" ]];then
	echo "Encrypting Input file"
	IFS=$'\n'
	for field in $(cat $file)
	do
		f1=$(echo $field | awk '{print$1}')
		f2=$(echo $field | awk '{print$2}')
		[ -z $f1 ] || [ -z $f2 ]  && usage FILE_FORMAT
		
		echo "$f1" | grep -qo ^$ip_patt$;rc=$?
		echo "$f2" | grep -qo ^$ip_patt$;rc2=$?
		{ [ $rc -eq 0 ] && ip="$f1" && pass="$f2"; } || { [ $rc2 -eq 0 ] && ip="$f2" && pass="$f1"; } \
		|| usage FILE_FORMAT		
		
		fin=$(logic_encrypt "$pass" "$ip")
		
		echo "$fin"
	done
fi
		
if [[ ! -z "${std[@]}" ]];then
	echo -e "\nEncrypting std Input"
	
	fin=$(logic_encrypt "${std[0]}" "${std[1]}")

	echo $fin
fi

if [[ ! -z "${files[@]}" ]];then
	IFS=$'\n'
	echo -e "\nCreating Encrypted file"
	
	sed -n '1p' ${files[0]} | grep -qo ^$ip_patt$;rc=$?
	sed -n '1p' ${files[1]} | grep -qo ^$ip_patt$;rc2=$?
	
	{ [ $rc -eq 0 ] && ip_file="${files[0]}" && pass_file="${files[1]}"; } || \
	{ [ $rc2 -eq 0 ] && ip_file="${files[1]}" && pass_file="$files[0]}"; } \
        || usage FILE_FORMAT
	
	paste -d'\t' ${ip_file} ${pass_file} > $tmpfile

	for field in $(cat $tmpfile)
	do
		ip=$(echo $field | awk '{print$1}')
		pass=$(echo $field | awk '{print$2}')
	
		fin=$(logic_encrypt "$pass" "$ip")
	
		echo "$fin" >> $FILENAME
	done
fi
