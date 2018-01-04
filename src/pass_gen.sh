#!/bin/bash

# ###############Description################
#> Generate encoded ip,password file.
#> Requires: Password & IP list in file or via standard input.
#> Output  : Output will be in encrypted file or on std-out
# ##########################################


clear #Clear screen

array=(5 7 8 3 2 9 4 6 5 8)
tmpfile='tmp'
FILENAME='encrypt.file'
ip_patt='[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'
passFile=''
oldEncryptFile='oldEncryptFile'

#ERRORS
E_NO_FILE_OR_DIR=65
E_FILE_FORMAT=71
E_SYNTAX_ERROR=72
E_GPG_PASSWORD=73

usage()
{
	ERROR=$1
	ERROR=${ERROR:-No_ERROR}
	echo "ERROR: $ERROR" >&2
	echo -e "
		Usage: ${0//*\//} [OPTION]... [input-file] [std-in] -u [SOURCE]
			
		-f
			Specify the fiename containing password.Encrypted password & ip will be redirect to $FILENAME
              		FORMAT: File must contain ip & password on same line separated with 'space or tab' with each set on new line e.g
	        	192.168.1.1 password1 or 192.168.1.1	password1
		        192.168.1.2 password2
			LINES STARTING WITH '#' & 'space' WILL BE IGNORED		
		
		-s	
			Specify password & ip on stdin,output will redirect to stdout
			FORMAT:see e.g below

		-g	
			Specify two files containing password & ip respectively.Output will be redirected to ${FILENAME}
		        FORMAT: Map both file with there contents i.e first line of password_file, must contain the
				PASSWORD for first IP, in ip_list_file.And Provide absolute path
			LINES STARTING WITH '#' & 'space' WILL BE IGNORED		
                -u
                        Update/Modify the existing encrypted file with the new data.Data will be provided by user through
                        other script parameter e.g '-f' or '-s'. One parameter is mandatory with this option.
                        FORMAT:see e.g below
				
		NOTE: IF MULTIPLE OPTIONS PROVIDED SAME WILL BE PROCESSED IN ABOVE SEQUENCE
	e.g
		${0//*\//} -s 'password ip' (sequence should be as shown)
		${0//*\//} -f  filename
		${0//*\//} -g 'file1 file2'
                ${0//*\//} -f  filename -u 'location of encrypted file'
	"
	exit ${!ERROR}
}

clean_files()
{
    rm $FILENAME ${oldEncryptFile} ${tmpfile} ${tmpfile}.1
}

logic_encrypt()
{
	local pass=$1 ip=$2
		rand=$(( RANDOM % ${#array[@]}))
        	iter=${array[$rand]}
                for((i=0;i<iter;i++))
                do
                        pass=$(echo "$pass" | base64 -w 0)
                done
		iter=$(echo "$iter" | base64)
        echo -e "$ip$pass&$iter"

}

encrypt_file()
{
	enc_file=$1
	echo -e "Encrypting Files.Enter password for gpg when prompted"
        gpg --no-use-agent -s --encrypt "$enc_file"
	
	test "$?" -ne 0 && clean_files && exit 1
        clean_files
}

update_file()
{
        local inp=$1

	echo -n "Enter your gpg key password when prompted."
	gpg -d ${passFile} > ${oldEncryptFile}

	test $? -ne 0 && clean_files && exit 1
	
	# If update_file() is called through standard input(-s) option than
	# invert the grep matching as per value in $inp variable, else assume
	# -f or -g options are used & invert the grep matching as per $FILENAME.

	if [[ ! -z $inp ]];then
	    grep -v "$inp" ${oldEncryptFile} > ${tmpfile} 
	    cat ${tmpfile} >> $FILENAME
	    encrypt_file $FILENAME
	else
	    grep -o ${ip_patt} $FILENAME > ${tmpfile}
	    grep -v -f ${tmpfile} ${oldEncryptFile} > ${tmpfile}.1
	    cat ${tmpfile}.1 >> $FILENAME
	fi

}

while getopts "f:s:g:u:h" arg
do

	case ${arg} in
		
		f)
			file=${OPTARG}
			[[ -s "$file" ]] || usage E_NO_FILE_OR_DIR
			;;
		s)
			std=(${OPTARG})
			[[ "${std[1]}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || usage "E_SYNTAX_ERROR" 
			;;
		g)
			files=(${OPTARG})
			[[ -s "${files[0]}" && -s "${files[1]}" ]] || usage E_NO_FILE_OR_DIR
			;;
		u)
		        passFile=${OPTARG}
			[[ -s "${passFile}" && ! -d "${passFile}" ]] || usage FILE_NOT_EXIST
			;;
	        h)
		        usage
			;;
	esac
done

if [[ -z "$file" && -z "${std[@]}" && -z "${files[@]}" ]];then
	usage
fi

>"$FILENAME"	
if [[ ! -z "$file" ]];then
	echo "Encoding Input file"

	while IFS=$'\n' read -r field
	do
		echo "$field" | grep -q '^#\|^$' && continue;
		f1=$(echo "$field" | awk '{print$1}')
		f2=$(echo "$field" | awk '{print$2}')
		[ -z "$f1" ] || [ -z "$f2" ]  && usage E_FILE_FORMAT
		
		echo "$f1" | grep -qo ^$ip_patt$;rc=$?
		echo "$f2" | grep -qo ^$ip_patt$;rc2=$?
		{ [ $rc -eq 0 ] && ip="$f1" && pass="$f2"; } || { [ $rc2 -eq 0 ] && ip="$f2" && pass="$f1"; } \
        	|| usage E_FILE_FORMAT		
		
		fin=$(logic_encrypt "$pass" "$ip")
		
		echo "$fin" >> "$FILENAME"
	done < "$file"
	
	[[ ! -z ${passFile} ]] && update_file
	encrypt_file "$FILENAME"
fi
		
if [[ ! -z "${std[@]}" ]];then
	echo -e "\nEncoding std Input"
	
	fin=$(logic_encrypt "${std[0]}" "${std[1]}")

	if [[ ! -z ${passFile} ]];then
	    echo $fin >> $FILENAME && update_file ${std[1]}
	else
	    echo -e "Copy below encoded output to your password file,encrypt the same with gpg."
	    echo "$fin"
	fi
fi

if [[ ! -z "${files[@]}" ]];then
	
	echo -e "\nCreating Encoded file"
	
	sed -n '1p' "${files[0]}" | grep -qo ^$ip_patt$;rc=$?
	sed -n '1p' "${files[1]}" | grep -qo ^$ip_patt$;rc2=$?
	
	{ [ $rc -eq 0 ] && ip_file="${files[0]}" && pass_file="${files[1]}"; } || \
	{ [ $rc2 -eq 0 ] && ip_file="${files[1]}" && pass_file="${files[0]}"; } \
        || usage E_FILE_FORMAT
	
	paste -d'\t' "${ip_file}" "${pass_file}" > "$tmpfile"

	while IFS=$'\n' read -r field
	do
		echo "$field" | grep -q '^#\|^$' && continue
		ip=$(echo "$field" | awk '{print$1}')
		pass=$(echo "$field" | awk '{print$2}')
	
		fin=$(logic_encrypt "$pass" "$ip")
	
		echo "$fin" >> $FILENAME
	done < "$tmpfile"
	rm -vf "$tmpfile"
	
	[[ ! -z ${passFile} ]] && update_file
	encrypt_file "$FILENAME"
fi
