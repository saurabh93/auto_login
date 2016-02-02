#!/bin/bash


#### Description: Install auto_login functionality in bash enviorment
#### Requirements: Bash Version >= 3.2,expect package,bashrc or bash_profile
#### Files/Directory  
####################:Directory= .lib in ${HOME}
####################:Files= auto_login.conf (Configuration Created)
####################:


clear #Clear screen

#Variables
HOME=${HOME:-$(pwd)}
lib_path=${HOME}/.lib_auto
conf='auto_login.conf'
src=${HOME}/src
count=0

#ERROR's
NO_PARAM=67
NO_PERM=68
NO_FILE=65
NO_INP=66

#ARRAYS
CMD_LIST=(bash expect gpg)
FILE_LSIT=(.bashrc .profile .bash_profile .gnupg/pubring.gpg .gnupg/secring.gpg)
SRC_LIST=(central.sh login.exp)
#Functions

check_command_exist() 
{
	test "$#" -eq 0 && echo "ERROR:${NO_PARAM}" && exit 1 #Checking Number of Arguments
	
	#Check commands exist or not
	for inp in "${CMD_LIST[@]}"
	do
		[[ $(command -v "$inp") ]]
		rc=$?;test "$rc" -eq 0 && status='OK' || status='Not Found'
		echo -e	"$inp:	$rc" >> ${lib_path}/${conf}
		echo -e	"            $inp: $status" 
		sleep 1
	done
}

check_run_time()
{
	echo -e "${conf} found.Checking for config"
	local count
	
	#Check configuration file,check for pre-requisites again & update ${conf}
	for cmd in "${CMD_LIST[@]}"
	do
		cmd_status=$(fgrep "^$cmd" ${lib_path}/${conf} | awk '{print$2}')
		if [[ "$cmd_status" -ne 0 ]];then
			sed -i "/$cmd/d" ${lib_path}/${conf}
			check_command_exist "$cmd"			
			count=$((count+1))
		fi
	done
	
	if [[ "$count" -ne 0 ]];then
		cmd_status="$(grep 1 ${lib_path}/${conf} | awk '{print$1}' | tr -d '\n')"
		test ! -z "$cmd_status" && echo "Commands $cmd_status does not exist" && exit 1
	fi
	sleep 2
}

check_files()
{
	egrep -q '.bashrc|profile' ${lib_path}/${conf} && return 0 	
	for files in "${FILE_LSIT[@]}"
	do
		[[ -s ${HOME}/${files} ]]
		rc=$?;test "$rc" -eq 0 && status='OK' || status='Not Found'
                echo -e "${files}:  $rc" >> ${lib_path}/${conf}
                echo -e "            ${files}: $status" 
                sleep 1

	done
} 
		

#Search prerequisites

{ test -f ${lib_path}/${conf}  && check_run_time && check_files; }|| \
{ mkdir -p ${lib_path} || exit ${DIR_PERM} && echo "Checking Pre-requisites" && check_command_exist bash expect gpg && check_files; } 

echo -e "Checking files for copying."
for num in {0,1,2}
do
	status=$(fgrep ${FILE_LSIT[$num]} ${lib_path}/${conf} | awk '{print$2}')
	[[ "$status" -eq 1 ]] && count=$((count+1)) 
	if [[ "$count" -eq 3 ]];then
		{ [[ -f /etc/skel/${FILE_LSIT[0]} ]] && cp -v /etc/skel/${FILE_LSIT[0]} ${HOME}; } ||  touch ${HOME}/.bashrc || \
		echo -e "${NO_PERM}" 
	fi
done

#GPG check

for files in ${FILE_LSIT[@]:3:1}
do
	status=$(grep ${files} ${lib_path}/${conf} | awk '{print$2}')
	
	if [[ "$status" -eq 1 ]];then
		echo -e "gpg is not setup.Want to setup Y/N?"
		read -t 5 ans || exit ${NO_INP}
		
		if [[ "$ans" -eq 'Y' ]];then
			gpg --gen-key
		else
			exit ${NO_INP}
		fi
	fi
done
