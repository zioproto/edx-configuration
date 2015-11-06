#!/bin/sh

#This script is used for backend server volume's backup. This script will take two 
# arguments; a UUID of the backup server and the number of old snapshots to keep.
#Usage:  ./backup.sh <UUID-of-the-backup-server> <number-of-old-snapshots-to-keep>
#Example: ./backup.sh ebddcc34-8c4b-40e6-8f3c-6fe7114079c3 2
#In this example the backup script will take snapshots of the mysql and mongodb volumes
#attached to the ebddcc34-8c4b-40e6-8f3c-6fe7114079c3 server. Only two old snapshots 
#will be spared and rest of the old snapshots will be deleted.

if [ $# -ne 2 ]; then
    echo "$0: usage: ./backup.sh <UUID-of-the-backup-server> <number-of-old-snapshots-to-keep>"
    exit 1
fi

UUID=$1 #UUID of the backend instance.
total_snapshots=$2 #Number of old snapshots to keep.

# Define a timestamp variable.
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

#Count the total number of snapshots.
snap_count=$( cinder snapshot-list | grep available | sed 's/\|/ /'|awk '{print $1}' | wc -l)

#Delete extra snapshots.
while [ $snap_count -gt $total_snapshots ]
do
   snap_uuids=$( cinder snapshot-list | grep mysql | sort -r -k1 | sed 's/\|/ /'|awk '{print $1}' )
   delete_snap=$(echo $snap_uuids | awk '{ print $1 }')
   cinder snapshot-delete $delete_snap
   echo "mysql snapshot $delete_snap deleted"

   snap_uuids=$( cinder snapshot-list | grep mongo | sort -r -k1 | sed 's/\|/ /'|awk '{print $1}' )
   delete_snap=$(echo $snap_uuids | awk '{ print $1 }')
   cinder snapshot-delete $delete_snap
   echo "mongo snapshot $delete_snap deleted"

   snap_count=`expr $snap_count - 2`
   if [ $snap_count -eq $total_snapshots ]
   then
      break
   fi
   sleep 5
done

#ID of the mongo volume.
mongo_volume=$(cinder list | grep $UUID | grep mongo | sed 's/\|/ /'|awk '{print $1}')

#ID of the mysql volume.
mysql_volume=$(cinder list | grep $UUID | grep mysql | sed 's/\|/ /'|awk '{print $1}')

#Creates a snapshot of mongo volume.
cinder snapshot-create --force True --name mongo-$UUID-$timestamp $mongo_volume

#Creates a snapshot of mysql volume.
cinder snapshot-create --force True --name mysql-$UUID-$timestamp $mysql_volume
