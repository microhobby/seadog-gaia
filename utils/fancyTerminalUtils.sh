RED='\x1b[0;41m'
GREEN='\x1b[42;30m'
NC='\033[0m' # No Color
BOLD='\033[1m'
NORMAL='\033[2m'
lastError=0

# last error check
function lastErrorCheck () {
	lst=$?
	if [ "$lst" -ne "0" ]; then
		echo $lst
	else
		echo $1
	fi
}

# kill the subshells on case of error
function checkErrorAndKill () {
	lst=$?
	
	if [ "$lst" -ne "0" ]; then
		writelnError $@
		sleep 1
		
		kill 0
	fi
}

function writelnError () {
	echo -e "${RED} $@ ${NC}"
}

function writeln () {
	echo -e "${GREEN} $@ ${NC}"
}
