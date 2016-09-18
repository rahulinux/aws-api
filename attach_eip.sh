#!/bin/bash


function attach_eip(){

   local instance_id=$1
   if [[ -z $instance_id ]]
   then
       echo "FAIL :: Instance ID require..." >&2
       return 1
   else
       ## Allocat ip
       aws ec2 allocate-address --domain vpc > /tmp/eip_allocate
       eip_id=$(grep "AllocationId" /tmp/eip_allocate | grep -oP '(?<=:\s\").*(?=\")' )
       eip=$( grep  "PublicIp" /tmp/eip_allocate | grep -oP '(?<=:\s\").*(?=\")' )

       ## Attach to instance
       if aws ec2 associate-address --instance-id $i --allocation-id $eip_id
       then
           echo "EIP Successfully attached to $instance_id [$eip]"
       else
           echo "Something went wrong while attaching eip ID: $eip_id" >&2
       fi
   fi
}

attach_eip i-asdf934nf
