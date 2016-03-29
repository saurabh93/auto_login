#!/bin/bash


#### Description: Install auto_login functionality in bash enviorment
#### Requirements: Bash Version >= 3.2,expect package,bashrc or bash_profile & gnupg
#### Directory= .lib in ${HOME}
#### Files:auto_login.conf in ${Home}  


clear #Clear screen

#Variables
HOME=${HOME:-$(dirname "$(pwd)")}
lib_path=${HOME}/.lib_auto
conf='auto_login.conf'
src=$(pwd)/src
count=0
FILENAME='encrypt.file'

#ERROR's
E_NO_PARAM=67
E_NO_PERM=68
E_NO_FILE_OR_DIR=65
E_NO_INP=66
E_CMD_NOT_FOUND=70=70
E_FILE_FORMAT=71
E_SYNTAX_ERROR=72

#ARRAYS
CMD_LIST=(bash expect gpg ssh)
FILE_LIST=(f.bashrc f.profile f.bash_profile f.gnupg/pubring.gpg f.gnupg/secring.gpg)
SRC_LIST=(central.sh login.exp pass_gen.sh)


#Trap exit & display ERROR CODE
trap 'echo "EXIT CODE:$?";exit' EXIT

#Functions

check_command_exist() 
{
	test "$#" -eq 0 && exit "$E_NO_PARAM" #Checking Number of Arguments
	
	#Check commands exist or not
	for inp in "${@}"
	do
		[[ $(command -v "$inp") ]]
		rc=$?;test "$rc" -eq 0 && status='OK' || status='Not Found'
		echo -e	"$inp:	$rc" >> ${lib_path}/${conf}
		echo -e	"            $inp: $status" 
		sleep 1
	done
}

check_files()
{
	for files in "${@}"
	do
		[[ -s ${HOME}/${files:1} ]] #Split 1st char of file 'f' & check file exist
		rc=$?;test "$rc" -eq 0 && status='OK' || status='Not Found'
                echo -e "${files}:  $rc" >> ${lib_path}/${conf} #Update ${conf}
                echo -e "            ${files:1}: $status" 
                sleep 1

	done
}

check_run_time()
{
	echo -e "${conf} found.Checking/Updating config"
	local count
	
	#Check configuration file,check for pre-requisites again & update ${conf}
	for cmd in "${@}"
	do
		cmd_status=$(grep "^${cmd}" ${lib_path}/${conf} | awk '{print$2}') #Get status from ${conf} file
		if [[ "$cmd_status" -ne 0 || -z "$cmd_status" ]];then
			sed -i "s:^${cmd}::g;/^:/d" ${lib_path}/${conf}	#Remove Entry of command/file from ${conf}
			{ [[ "$cmd" =~ f.[a-z] ]] && check_files "$cmd"; } || check_command_exist "$cmd" #Update status of CMD/Files	
			count=$((count+1)) #Increase count for FILE/CMD not found status
		fi
	done
	
	if [[ "$count" -gt 6 ]];then #Since number of files are 5 
		cmd_status="$(grep 1 ${lib_path}/${conf} | grep -v "^f" | awk '{print$1}' | tr -d '\n')"
		test ! -z "$cmd_status" && echo "Commands $cmd_status does not exist" && exit ${E_CMD_NOT_FOUND=70}
	fi
	sleep 2
}
		
#Search prerequisites

if [[ -f ${lib_path}/${conf} ]];then
	check_run_time "${CMD_LIST[@]}" "${FILE_LIST[@]}"
else
	mkdir -p "${lib_path}" || exit "${E_NO_FILE_OR_DIR}"
	echo -e "Checking Pre-requisites"
	check_command_exist "${CMD_LIST[@]}" && check_files "${FILE_LIST[@]}"
fi


echo -e "Checking files for copying."
for num in {0,1,2}
do
	status=$(fgrep ${FILE_LIST[$num]} ${lib_path}/${conf} | awk '{print$2}')

	[[ "$status" -eq 1 ]] && count=$((count+1)) 

	if [[ "$count" -eq 3 ]];then #If true copy files from /etc/skel or create .bashrc & update ${conf}
	    { [[ -f /etc/skel/${FILE_LIST[0]:1} ]] && cp -v /etc/skel/${FILE_LIST[0]:1} ${HOME} && check_run_time ${FILE_LIST[0]}; } || \
	       { touch ${HOME}/.bashrc && check_run_time ${FILE_LIST[0]}; }|| exit "${E_NO_PERM}" 
	fi
done

sleep 1


#GPG check

for files in "${FILE_LIST[@]:3:1}"
do
	status=$(grep ${files} ${lib_path}/${conf} | awk '{print$2}')
	
	if [[ "$status" -eq 1 ]];then
		echo -e "gpg is not setup.Want to setup Y/N?"
		read -t 200 ans || exit ${E_NO_INP}
		
		if [[ "$ans" = 'Y' ]];then
			gpg --gen-key
		else
			echo "NO INPUT"
			exit ${E_NO_INP}
		fi
	fi
done

sleep 2
##Password file genration
{ [[ -s "$src"/${SRC_LIST[0]} ]] && [[ -s "$src"/${SRC_LIST[1]} ]] && [[ -s "$src"/${SRC_LIST[2]} ]]; } || \
{ echo "Source file list Not Present.Check $src directory exist & files ${SRC_LIST[@]} are present." && exit ${E_NO_FILE_OR_DIR}; }
cd "$src" && cp "${SRC_LIST[@]}" ${lib_path} || exit ${E_NO_PERM}

#Get Input from User
printf %b "\nPlease provide the file with password & ip list With below Mentioned Format.
FORMAT: File must contain ip & password on same line seperated with 'space or tab' with each set on new line e.g
192.168.1.1 password1 or 192.168.1.1	password1
192.168.1.2 password2 (Please provide absolute path)\n"
sleep 2

read -t 200 -rp "Enter FileName=" file_name || { echo "NO INPUT" && exit ${E_NO_INP}; }
[ -s "$file_name" ] || exit ${E_NO_FILE_OR_DIR}

#Encode file & encrypt with gpg
"$src"/./pass_gen.sh -f "$file_name" 1> /dev/null && mv "${FILENAME}.gpg" ${lib_path} && \
echo -e "You may use $src/${SRC_LIST[2]} script to create Encrypted password file any time"

