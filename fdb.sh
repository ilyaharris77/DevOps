#!/bin/bash
#. ./John.sh
echo -n > /tmp/result_local
echo -n > /tmp/result_db

fdbcli --exec "writemode on; clearrange \"\" \xFF; writemode off" > /dev/null

function validateInput() {
  local re='^[0-9]+$'
  if ! [[ $1 =~ $re ]]; then
	  echo "error: Not a number" >&2;
	  exit 1
  fi
}

function putIntoDB() {
local i=$1
while [ $i -lt $(($1+$2)) ]
do
  local data=$(echo $RANDOM | base64)
  fdbcli --exec "writemode on; set $i $data; writemode off" > /dev/null
	echo "\`$i' is \`$data'" >> /tmp/result_local
  i=$(( $i + 1 ))
done
}

echo "Hello,John! How many keys you want to put in the base? Enter a value:"
read count
validateInput $count
putIntoDB 0 $count
echo "$count keys was added! How much more to put? Enter a value:"
read count1
validateInput $count
putIntoDB $count $count1
echo "$count1 keys was added! Press Enter to compare results"
read
fdbcli --exec "getrange \"\" \\xFF $(($count+$count1))" > /tmp/result_db
sort /tmp/result_db -o /tmp/result_db
sed -i '/\(^$\|Range limited to\)/d' /tmp/result_db
sort /tmp/result_local -o /tmp/result_local
status=$(diff -q /tmp/result_local /tmp/result_db)
if [ -z "$status" ]; then
  echo -e "\033[32mData not differ"
else
  echo -e "\033[31mData differ"
fi
echo -e "\033[37m\033[40m"
exit
