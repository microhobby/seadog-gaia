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

function writelnError () {
	echo -e "${RED} $1 ${NC}"
}

function writeln () {
	echo -e "${GREEN} $1 ${NC}"
}
