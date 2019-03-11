#!/bin/bash

rm status.txt

host_remote="$1"
host_lh="$2"
random=$(head -200 /dev/urandom | cksum | cut -f1 -d " ")

mkdir -p logi

line=1;
while read -r line; do
    mail=$(echo "$line" | awk '{print $1}')
    pass=$(echo "$line" | awk '{print $2}')
    lpass=$(echo "$line" | awk '{print $2}')

    cmd="imapsync --host1 '$host_remote' --host2 '$host_lh' --user1 '$mail' --user2 '$mail' --password1 '$pass' --password2 '$lpass' --ssl1 --logdir logi --logfile '$random'-'$mail'"
    imapsync="$cmd ; echo \"\$? $mail\" >> status.txt"

    #set minimum free memory (kB)
    minmem=700000

    #check free memory
    memfree=$(grep MemFree /proc/meminfo | awk '{print $2}')
    while [ "$memfree" -le "$minmem"  ] ; do
        memfree=$(grep MemFree /proc/meminfo | awk '{print $2}')
        echo "memory limit $memfree"
        sleep 1
    done

    echo "$cmd"

    screen -dmS "$mail" bash -c "$imapsync ; exec bash"

    sleep 1
done < mails.txt
screen -d
