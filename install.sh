#!/bin/bash


#### Description: Install auto_login functionality in bash enviorment
#### Requirements: Bash Version >= 3.2,expect package,bashrc or bash_profile
#### Files/Directory  
####################:Directory= .lib in ${HOME}
####################:Files= auto_login.conf (Configuration Created)
####################:


clear #Clear screen

#Variables
lib_path=${HOME}/.lib_auto
conf='auto_login.conf'

#ERROR's
NO_PARAM=67
DIR_PERM=68


#Functions

check_command_exist()
{
	echo "Checking pre-requisites"
	test "$#" -eq 0 && echo "ERROR:${NO_PARAM}" && exit 1
	for inp in ${@}
	do
		[[ $(command -v $inp) ]]
		rc=$?;test "$rc" -eq 0 && status='OK' || status='Not Found'
		echo -e	"$inp:	$rc" >> ${lib_path}/${conf}
		echo -e	"            $inp: $status" 
		sleep 1
	done
}

check_run_time()
{
	echo "Checking configuration"
	local count
	for cmd in {bash,expect,gpg}
	do
		cmd_status=$(grep "$cmd" ${lib_path}/${conf} | awk '{print$2}')
		if [[ "$cmd_status" -ne 0 ]];then
			sed -i "/$cmd/d" ${lib_path}/${conf}
			check_command_exist "$cmd"			
			count=$((count+1))
		fi
	done
	
	if [[ "$count" -ne 0 ]];then
		cmd_status=$(grep 1 ${lib_path}/${conf} | awk '{print$1}')
		test ! -z "$cmd_status" && echo "Commands $cmd_status does not exist" && exit 1
	fi
	
}

	
	

#Search prerequisites

#if [[ ! $(uname -s) =~ (L|l)inux ]];then
#	echo "Not a linux system.Exiting"
#fi

test -f ${lib_path}/${conf}  && check_run_time || \
{ mkdir -p ${lib_path} || exit ${DIR_PERM} && check_command_exist bash expect gpg; } 




