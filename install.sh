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
CMD_NOT_FOUND=70

#ARRAYS
CMD_LIST=(bash expect gpg)
FILE_LSIT=(f.bashrc f.profile f.bash_profile f.gnupg/pubring.gpg f.gnupg/secring.gpg)
SRC_LIST=(central.sh login.exp)
#Functions

check_command_exist() 
{
	test "$#" -eq 0 && echo "ERROR:${NO_PARAM}" && exit 1 #Checking Number of Arguments
	
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
		[[ -s ${HOME}/${files:1} ]]
		rc=$?;test "$rc" -eq 0 && status='OK' || status='Not Found'
                echo -e "${files}:  $rc" >> ${lib_path}/${conf}
                echo -e "            ${files:1}: $status" 
                sleep 1

	done
}

check_run_time()
{
	echo -e "${conf} found.Checking for config"
	local count
	
	#Check configuration file,check for pre-requisites again & update ${conf}
	for cmd in "${@}"
	do
		cmd_status=$(grep "^${cmd}" ${lib_path}/${conf} | awk '{print$2}')
		if [[ "$cmd_status" -ne 0 ]];then
			sed -i "s:^${cmd}::g;/^:/d" ${lib_path}/${conf}	
			[[ "$cmd" =~ f.[a-z] ]] && check_files "$cmd" || check_command_exist "$cmd"			
			count=$((count+1))
		fi
	done
	
	if [[ "$count" -gt 5 ]];then
		cmd_status="$(grep 1 ${lib_path}/${conf} | grep -v "^f" | awk '{print$1}' | tr -d '\n')"
		test ! -z "$cmd_status" && echo "Commands $cmd_status does not exist" && exit ${CMD_NOT_FOUND}
	fi
	sleep 2
}
		
#Search prerequisites

{ test -f ${lib_path}/${conf}  && check_run_time ${CMD_LIST[@]} ${FILE_LSIT[@]}; }|| \
{ mkdir -p ${lib_path} || exit ${DIR_PERM} && echo "Checking Pre-requisites" && \
  check_command_exist ${CMD_LIST[@]} && check_files ${FILE_LSIT[@]}; } 


echo -e "Checking files for copying."
for num in {0,1,2}
do
	status=$(fgrep ${FILE_LSIT[$num]} ${lib_path}/${conf} | awk '{print$2}')

	[[ "$status" -eq 1 ]] && count=$((count+1)) 
	if [[ "$count" -eq 3 ]];then
		{ [[ -f /etc/skel/${FILE_LSIT[0]} ]] && cp -v /etc/skel/${FILE_LSIT[0]} ${HOME}; } ||  \
		touch ${HOME}/.bashrc || echo -e "${NO_PERM}" 
	fi
done

#GPG check

for files in ${FILE_LSIT[@]:3:1}
do
	status=$(grep ${files} ${lib_path}/${conf} | awk '{print$2}')
	
	if [[ "$status" -eq 1 ]];then
		echo -e "gpg is not setup.Want to setup Y/N?"
		read -t 5 ans || exit ${NO_INP}
		
		if [[ "$ans" = 'Y' ]];then
			gpg --gen-key
		else
			exit ${NO_INP}
		fi
	fi
done
