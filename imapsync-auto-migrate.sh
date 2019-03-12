#!/bin/bash
#imapsync-auto-migrate.sh
#Author: Damian Ciszak
#Contact: ciszakdamian(at)gmail.com
#LogDir /var/log/imapsync-auto-migrate/

#remove old status file
rm status.txt

#get value
host_remote="$1"
host_dst="$2"
random=$(head -200 /dev/urandom | cksum | cut -f1 -d " ")
mxip=$(dig "$host_remote" MX +short | head -1 | awk '{print $2}' | xargs -i dig +short {})

#create log
logdir="/var/log/imapsync-auto-migrate"
mkdir -p $logdir
mainlog="$logdir"/main.log
echo "#DOMAIN: $host_remote MX IP: $mxip DST: $host_dst" >> $mainlog

#use mx as source imap server
echo -n "Do you want use domain mx record as source IMAP server? y/n: "
read -r q

if [ "$q" = "y" ]; then
    host_remote=$mxip
fi

#line=1;
while read -r line; do
    mail=$(echo "$line" | awk '{print $1}')
    pass=$(echo "$line" | awk '{print $2}')
    lpass=$(echo "$line" | awk '{print $2}')

    cmd="imapsync --host1 '$host_remote' --host2 '$host_dst' --user1 '$mail' --user2 '$mail' --password1 '$pass' --password2 '$lpass' --ssl1 --logdir $logdir/logs --logfile '$random'-'$mail'"
    imapsync="$cmd ; echo \"\$? $mail\" | tee -a $mainlog status.txt > /dev/null"

    #set minimum free memory (kB)
    minmem=700000

    #check free memory
    memfree=$(grep MemFree /proc/meminfo | awk '{print $2}')
    while [ "$memfree" -le "$minmem"  ] ; do
        memfree=$(grep MemFree /proc/meminfo | awk '{print $2}')
        echo "work $memfree"
        sleep 1
    done

    echo "$cmd"

    screen -dmS "$mail" bash -c "$imapsync ; exec bash"

    sleep 1
done < mails.txt
screen -d
