#!/bin/bash
backupPath=/root/backupname2
logFile=/root/backupname2/log
lastTagsFile=/mnt/backup_fdb/running_backups
backupDuration=30
deltaTime=3600
lastTag=''
function removeTmp {
  rm $backupPath/tmp*
}

function toLog {
  local baseColor="\033[0m"
  if ! [ -z $2 ]; then
    local color="\033[${2}m"
  else
    local color=$baseColor
  fi  
  echo -e "$color$(date +[%d-%m-%y\ %H:%M:%S]) - $1$baseColor" >> $logFile    
}

function stopBackup {
  if [ -z "$1" ]; then
    toLog "No running backups" 31
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
    toLog "$success"
    sed -i "/$tag/d" $lastTagsFile
    return 0
  elif ! [ -z "$failed" ]; then
    toLog "$failed" 31
    return 1
  fi
}

function getLastTag {
  local count
  local lastTag
  count=$(cat $lastTagsFile | wc -l)
  lastTag=$(cat $lastTagsFile | tail -n 1)
  #count=$(fdbcli --exec "status details" | awk -v RS='' '/Running backup tags/' | sed 1d | wc -l)
  #lastTag=$(fdbcli --exec "status details" | awk -v RS='' '/Running backup tags/' | sed 1d | awk 'NR == 1{print$1}')
  if [[ $count -gt 1 ]]; then
    toLog "More than one backup running" 31
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
    #sed -i -s "\$a $tag" $lastTagsFile
    echo "$tag" >> $lastTagsFile
    toLog "$success"
    return 0
  elif ! [ -z "$failed" ]; then
    toLog "$failed" 31
    return 1
  fi
}

function deleteOldBackups {
  find $backupPath -type d -mtime +$backupDuration | xargs -rL1 fdbbackup delete -d 2>&1 > /dev/null
}

touch $lastTagsFile
lastTag=$(getLastTag)

if ! [ -z "$lastTag" ]; then
  currentTime=$(date +%s)
  tagTime=$(echo $lastTag | awk -F ':' '{print$1}')
  if [ $(( $currentTime-$tagTime )) -lt $deltaTime ]; then
    exit
  fi
  if startBackup; then
    stopBackup $lastTag
    deleteOldBackups
  fi
else
  startBackup;
fi

exit
