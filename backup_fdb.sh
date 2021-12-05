#!/bin/bash
backupPath=/root/backupname2
logFile=/root/backupname2/log
backupDuration=30
lastTag=''
function removeTmp {
  rm $backupPath/tmp*
}

function toLog {
  local color="\033[${1}m"
  local baseColor="\033[37m"
  echo -e "$color$(date +[%d-%m-%y\ %H:%M:%S]) - $2$baseColor" >> $logFile    
}

function stopBackup {
  if [ -z "$1" ]; then
    toLog '31' "No running backups"
    return 1
  fi
  local tag=$1
  local success
  local failed
  fdbbackup discontinue -t $tag > $backupPath/tmp11 2> $backupPath/tmp22
  local success=$(cat $backupPath/tmp11)
  local failed=$(cat $backupPath/tmp22) 
  removeTmp
  if ! [ -z "$success" ]; then
    toLog 37 "$success"
    return 0
  elif ! [ -z "$failed" ]; then
    toLog 31 "$failed"
    return 1
  fi
}

function getLastTag {
  local count
  local lastTag
  count=$(fdbcli --exec "status details" | awk -v RS='' '/Running backup tags/' | sed 1d | wc -l)
  lastTag=$(fdbcli --exec "status details" | awk -v RS='' '/Running backup tags/' | sed 1d | awk 'NR == 1{print$1}')
  if [[ $count -gt 1 ]]; then
    toLog 31 "More than one backup running"
  fi
  echo $lastTag
}

function startBackup {
  local tag=$(date +%s:%F)
  fdbbackup start -d file://$backupPath -s 3600 -t $tag > $backupPath/tmp1 2> $backupPath/tmp2
  local success=$(cat $backupPath/tmp1)
  local failed=$(cat $backupPath/tmp2) 
  removeTmp
  if ! [ -z "$success" ]; then
    toLog '37' "$success"
    return 0
  elif ! [ -z "$failed" ]; then
    toLog '31' "$failed"
    return 1
  fi
}

function deleteOldBackups {
  find $backupPath -type d -mtime +$backupDuration | xargs -L1 fdbbackup delete -d
}


lastTag=$(getLastTag)
if startBackup; then
  stopBackup $lastTag
  deleteOldBackups
fi

exit
