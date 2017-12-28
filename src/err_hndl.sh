#*** error_handle library ***##

name=err_hndl
ver=1


set -e 
set -o nounset
set -o errtrace
exec 2> /tmp/err.txt

ERR_FILE='/tmp/err.txt'
LINE_NO=""
EXIT_CODE=""
FUNCNAME_=""
FILE=""
ERR_DESC=""
err_start=2
line_count=""

declare -a err_array

catch_exit()
{
	if [[ "$#" -gt 1 ]];then
		LINE_NO="$1"
		FUNCNAME_="$2"
		EXIT_CODE=$exit_status
		
		test -s "$ERR_FILE" && ERR_DESC=$(cat "$ERR_FILE")
	
		# Print Error to stdout in a fancy way :)
        
	        test -t 1 && tput bold && tput setf 4
                echo -e "[EXIT_HANDLER]!: \n \n"

                tput setf 1
                echo -e "FILE/CMD:      ${0}\n"
                echo -e "LINE:          ${LINE_NO}\n"
                echo -e "FUNC:          ${FUNCNAME_}\n"
		
                echo -e "EXIT CODE:     $EXIT_CODE"

                tput setf 4
                echo -e "ERROR DESCRIPTION:"
                echo -e "${ERR_DESC%:}"
   		echo -e "NOTE: Error's found.If exit code is '0' program executed successfuly"

                tput sgr0 #Reset tput
		

	else
		FUNCNAME_=$1
		if [[ -s "$ERR_FILE" ]];then
			line_count=$(wc -l < $ERR_FILE)			
			local IFS=:
			err_array=($(cat $ERR_FILE))
			unset IFS
			
			FILE=${err_array[0]:-UNKNOWN}
			LINE_NO=${err_array[1]:-UNKNOWN}

			# Fetching Line number if available
			
			[[ "$LINE_NO" =~ ([a-z]+)[[:space:]]([0-9]+) ]] && LINE_NO=${BASH_REMATCH[2]}
			[[ "$LINE_NO" =~ ^[0-9]+ ]] || LINE_NO=UNKNOWN 
			
			# Setting err_start variable as per LINE_NO & FILE varibale values
			if [[ $LINE_NO = UNKNOWN ]];then
				[[ $FILE != UNKNOWN ]] && err_start=1
				[[ $FILE  = UNKNOWN ]] && err_start=0
			fi

			# Input all error in Variable

			for ((i="$err_start";i<${#err_array[@]};i++))
			do
				ERR_DESC="$ERR_DESC  ${err_array[$i]}:"
			done				
			
			ERR_DESC=${ERR_DESC:-UNKNOWN}
			# Print Error to stdout in a fancy way :)
			
			test -t 1 && tput bold && tput setf 4
			echo -e "[EXIT_HANDLER]!: \n \n"

			tput setf 1		
			echo -e "FILE/CMD:	${FILE}\n"
			echo -e "LINE:		${LINE_NO}\n"
			echo -e "FUNC:		${FUNCNAME_}\n"
		
			echo -e "EXIT CODE:	$exit_status"
			
			tput setf 4
			echo -e "ERROR DESCRIPTION:"
			echo -e "${ERR_DESC%:}"
			echo -e "NOTE: Error's found.If exit code is '0' program executed successfuly"

			tput sgr0 #Reset tput
		
		else
			test "$exit_status" -eq 0 && return 0
			
			test -t 1 && tput bold && tput setf 4
                        echo -e "[EXIT_HANDLER]!: \n \n"

                        tput setf 1
                        echo -e "FILE:          ${0}\n"
                        echo -e "LINE:          UNKNOWN\n"
                        echo -e "FUNC:          ${FUNCNAME_}\n"
			
                        echo -e "EXIT CODE:     $exit_status"

                        tput setf 4
                        echo -e "ERROR DESCRIPTION:"
                        echo -e "UNKNOWN"
			echo -e "NOTE: Error's found.If exit code is '0' program executed successfuly"

                        tput sgr0 #Reset tput

		fi
	fi
}

trap 'exit_status=$?;FUNCTION=${FUNCNAME:-NONE};catch_exit $lineno $FUNCTION' EXIT 

return 0
