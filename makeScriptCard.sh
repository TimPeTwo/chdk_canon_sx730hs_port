#!/bin/bash
#Enable powershot basic scripting on a memory card
if [ $# -ne 1 ] ; then
  echo
  echo "Usage : ./makeScriptCard.sh [ device ]"
  echo
  echo " [ device ] is a fat32 / fat16 partition on the memory card"
  echo " example : ./makeScriptCard.sh /dev/sdb1"
  echo "NOTE: please run as root"
  exit 112
fi
echo Boot sector of $1 will be modified. If you are not sure this is what you want then cancel with Ctrl-C
sleep 8
#TAG on boot sector
if ! echo -n SCRIPT | dd bs=1 count=6 seek=496 of=$1 ; then {
   echo failed writing to boot sector
   exit 113
} fi
if mount | grep /mnt ; then {
    umount /mnt
} fi
if ! mount $1 /mnt ; then {
    echo failed to mount
    exit 114
} fi
#create script request file
echo -n "for DC_scriptdisk" > /mnt/script.req
#Example script
echo 'private sub sayHello()
  a=LCDMsg_Create()
  LCDMsg_SetStr(a,"Hello World!")
end sub
private sub Initialize()
  UI.CreatePublic()
  sayHello()
end sub
'>/mnt/extend.m
#Done !
echo "Please check /mnt for files extend.m and script.req"
