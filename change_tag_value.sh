#!/bin/bash

## Change Tags Values
## MUST BE KEY(1st) VALUE(2nd) in following arrays



declare -A OLD_TAGS=( [Stack]=Staging )
declare -A NEW_TAGS=( [Stack]=Prod )


instance_ids=/tmp/instances_ids_list
volume_ids=/tmp/volume_ids_list
region=us-east-1

clean_up(){

   echo "Initiated cleanup task"
   sleep 1
   for f in $instance_ids $volume_ids
   do
       [[ -f $f ]] && rm -rfv $f
   done
   echo "cleanup completed successfully"
   exit

}


trap clean_up INT TERM HUP

get_instances_ids(){
   local key=$1
   local value=$2
   echo "collecting details of old tags"
   aws ec2 describe-instances \
            --query 'Reservations[*].Instances[*].[InstanceId]' \
            --filters Name=tag:$key,Values=$value --output text > $instance_ids
        echo "Instance IDs captured in $instance_ids"
   echo "Done"
}

get_volumes_ids(){
    if [[ ! -f $instance_ids ]]
    then
       echo "Must be run after get_instance_ids function"
       exit 1
    fi
    for i in $( < $instance_ids )
    do
         aws ec2 describe-instances \
            --no-verify-ssl --instance-id $i \
                --region $region | \
                        awk '/VolumeId/{ gsub(/,/,"");;gsub(/"/,""); print $2}' \
                        >> $volume_ids
    done
    echo "Volumes IDs captured in $volume_ids"
}

change_tag(){

    local key=$1
    local value=$2

    echo "Applying tags $key=$value"
    for i in $( cat $instance_ids  $volume_ids );
    do
             aws ec2 --no-verify-ssl create-tags \
                   --resources $i \
                   --tags Key=$key,Value=$value
    done
    echo "Done"

}

for key in ${!OLD_TAGS[@]}
do
   get_instances_ids $key ${OLD_TAGS[$key]}
   get_volumes_ids
   change_tag $key ${NEW_TAGS[$key]}
done

clean_up
