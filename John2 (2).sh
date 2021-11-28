#!/bin/bash
#. ./John.sh
echo "Hello,John! How many keys you want to put in the base? Enter a value:"
read count
echo "How many process will be run in parallel? Enter a value:"
read copies
re='^[0-9]+$'

if ! [[ $count =~ $re ]] || ! [[ $copies =~ $re ]]; then
	echo "error: Not a number" >&2;
	exit 1
fi

function putIntoDB() {
local i=0
while [ $i -lt $count ]
do
	fdbcli --exec "writemode on; set $i $RANDOM; writemode off" > /dev/null
	i=$(( $i + 1 ))
done
}

while [ $copies -gt 0 ]
do
	putIntoDB &
	copies=$(( $copies - 1 ))
	echo -en "\033[1K"
	echo -en "\rEntries count: $copies" 
done
echo -e "\nDone"
exit
