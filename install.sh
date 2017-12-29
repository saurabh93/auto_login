#!/bin/bash


# Description: Install auto_login functionality in bash enviorment
# Requirements: Bash Version >= 3.2,expect package,bashrc or bash_profile & gnupg
# Directory= .lib in ${HOME}
# Files:auto_login.conf in ${Home}  


clear #Clear screen

CURR_DIR=$(pwd)
SCRIPT_DIR=$(dirname $0)

. "${CURR_DIR}"/"${SCRIPT_DIR}"/src/err_hndl.sh

# Variables
HOME=${HOME:-$(dirname "$(pwd)")}
lib_path=${HOME}/.lib_auto
conf='auto_login.conf'
src="${CURR_DIR}"/"${SCRIPT_DIR}"/src
count=0
FILENAME='encrypt.file'
lineno=""
LOGIN_STARTUP=""

# ERROR's
E_NO_ARG=67
E_NO_PERM=68
E_NO_FILE_OR_DIR=65
E_NO_INP=66
E_CMD_NOT_FOUND=70
E_FILE_FORMAT=71
E_SYNTAX_ERROR=72

# Messages
ARG='BAD_ARGUMENTS'
EMP='UNKNOWN'
NINP='No INPUT PROVIDED'

# ARRAYS
CMD_LIST=(bash expect gpg ssh)
FILE_LIST=(f.bashrc f.profile f.bash_profile f.gnupg/pubring.gpg f.gnupg/secring.gpg)
SRC_LIST=(csource.sh login.exp pass_gen.sh)


# Functions

# Check command is installed or not & update ${conf}

check_command_exist() 
{
	test "$#" -eq 0 && { lineno=${LINENO:-$EMP};echo "$ARG" >&2;exit "$E_NO_ARG"; } 	
	
	for inp in "${@}"
	do
		[[ $(command -v "$inp") ]] && rc=$? || rc=$? # WorkAround for set -e
		test "$rc" -eq 0 && status='OK' || status='Not Found'
		echo -e	"$inp:	$rc" >> ${lib_path}/${conf}
		echo -e	"            $inp: $status" 
		sleep 1
	done
}

# Check neccessary files exist or not & update ${conf}

check_files()
{
	test "$#" -eq 0 && { lineno=${LINENO:-$EMP};echo "$ARG" >&2;exit "$E_NO_ARG"; }

	for files in "${@}"
	do
		[[ -s ${HOME}/${files:1} ]] && rc=$? || rc=$? # Split 1st char 'f' & check file exist
		test "$rc" -eq 0 && status='OK' || status='Not Found'
                echo -e "${files}:  $rc" >> ${lib_path}/${conf} # Update ${conf}
                echo -e "            ${files:1}: $status" 
                sleep 1

	done
}

# Check configuration file if exist,check for pre-requisites again & update ${conf}

check_run_time()
{
	test "$#" -eq 0 && { lineno=${LINENO:-$EMP};echo "$ARG" >&2;exit "$E_NO_ARG"; } # Checking Number of Arguments

	echo -e "${conf} found.Checking/Updating config"
	
	for cmd in "${@}"
	do
		cmd_status=$(grep "^${cmd}" ${lib_path}/${conf} | awk '{print$2}') # Get status from ${conf} file
		if [[ "$cmd_status" -ne 0 || -z "$cmd_status" ]];then
			sed -i "s:^${cmd}::g;/^:/d" ${lib_path}/${conf}	# Remove Entry of command/file from ${conf}
			{ [[ "$cmd" =~ f.[a-z] ]] && check_files "$cmd"; } || check_command_exist "$cmd" # Update status of CMD/Files	
		fi
	done
	
	sleep 1
}

#### @MAIN
		
# Search prerequisites

if [[ -f ${lib_path}/${conf} ]];then
	check_run_time "${CMD_LIST[@]}" "${FILE_LIST[@]}"
else
	mkdir -p "${lib_path}" || { lineno=${LINENO:-$EMP};exit "$E_NO_PERM"; }
	echo -e "Checking Pre-requisites"
	check_command_exist "${CMD_LIST[@]}";check_files "${FILE_LIST[@]}"
fi

# Check All neccessary commands exist or not

cmd_status="$(grep 1 ${lib_path}/${conf} | grep -v "^f" | awk '{print$1}' | tr -d '\n')"
test ! -z "$cmd_status" && echo "$cmd_status command(s) not found" >&2 && exit ${E_CMD_NOT_FOUND}


# Copy bash Enviorment from /etc/skel directory or create .bashrc

echo -e "Checking files for copying."
for num in {0,1,2}
do
	status=$(fgrep ${FILE_LIST[$num]} ${lib_path}/${conf} | awk '{print$2}')

	[[ "$status" -eq 0 ]] && LOGIN_STARTUP=${FILE_LIST[$num]:1} && break || count=$((count+1))
	if [[ "$count" -eq 3 ]];then # If true copy files from /etc/skel or create .bashrc & update ${conf}
	    { [[ -r /etc/skel/${FILE_LIST[0]:1} ]] && cp -v /etc/skel/${FILE_LIST[0]:1} ${HOME} && check_run_time ${FILE_LIST[0]}; } || \
	    { printf "# ~/.bashrc" > ${HOME}/${FILE_LIST[0]:1} && check_run_time ${FILE_LIST[0]}; }|| exit "${E_NO_PERM}"
		LOGIN_STARTUP=${FILE_LIST[0]:1} 
	fi
done

sleep 1


# GPG check

for files in "${FILE_LIST[@]:3:2}"
do
	status=$(grep ${files} ${lib_path}/${conf} | awk '{print$2}')
	
	if [[ "$status" -eq 1 ]];then
		echo -e "gpg is not setup.Want to setup Y/N?"
		read -r ans || { lineno="${LINENO:-$EMP}";echo "$NINP" >&2;exit ${E_NO_INP}; }
		
		if [[ "$ans" = 'Y' ]];then
			gpg --gen-key
		else
			echo "GPG not setup" >&2
			lineno="${LINENO:-$EMP}"
			exit ${E_NO_INP}
		fi
	fi
done

sleep 2

# Copy files from "$src" to ${lib_path}

cd "$src" 
chmod u+x "${SRC_LIST[@]}" || { lineno=${LINENO:-$EMP};exit ${E_NO_PERM}; }
cp -n "${SRC_LIST[@]}" ${lib_path} || { lineno=${LINENO:-$EMP};echo "Check files $src/${SRC_LIST[@]} presents">&2;exit ${E_NO_PERM}; }

# Get Input from User

printf %b "\nPlease provide the file with password & ip list With below Mentioned Format.
FORMAT: File must contain ip & password on same line seperated with 'space or tab' with each set on new line e.g
192.168.1.1 password1 or 192.168.1.1	password1
192.168.1.2 password2 (Please provide absolute path)\n"
sleep 2

echo -en "Enter Filename="
read -r file_name || { lineno="$LINENO";echo "$NINP" >&2;exit ${E_NO_INP}; }
if [[ ! -s "$file_name" ]] || [[ -d "$file_name" ]];then
	echo "File '$file_name' does not exist" >&2 
	lineno="${LINENO:-UNKNOWN}" && exit ${E_NO_FILE_OR_DIR}
fi


# Encode file & encrypt them.

bash "$src"/pass_gen.sh -f "$file_name" 1> /dev/null 
mv "${FILENAME}.gpg" ${lib_path} 
echo -e "You may use ${lib_path}/${SRC_LIST[2]} script to create Encrypted password file any time";sleep 5

# Adding $lib_path to $LOGIN_STARTUP file
grep -q "#login_auto" $HOME/$LOGIN_STARTUP || echo -e "\n#login_auto lib \n. $lib_path/${SRC_LIST[0]}" >> $HOME/$LOGIN_STARTUP

# Message
echo -e "\nPlease source the $LOGIN_STARTUP file '. $HOME/$LOGIN_STARTUP' or login again for the applied changes to take affect."
echo -e "\nType auto_login(without arguments) on shell for more information on commands."
exit 0
