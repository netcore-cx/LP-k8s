#!/bin/bash

function Check_return {
if [ $1 != 0 ]
then
  exit 1
fi
}



echo -n "All pod start  "
count=0
while [ $count != 2 ]
do
  sleep 1
  echo -n "-"
  count=0
  for i in `seq 1 2`
  do
    echo -n "-"
    get=`kubectl get pod -o wide | grep gluster-$i-pod`
    read name ready  status restarts age ip node <<< `echo $get`
    if [ "$status" = "Running" ] && [ "$ready" = "1/1" ]
    then
      let "count += 1"
    fi
  done
done
echo "> ok"

#Ip Address for Gluster-1
get=`kubectl get pod -o wide | grep gluster-1-pod`
read name ready  status restarts age ip node <<< `echo $get`
gluster1ip=$ip

#Ip Address for Gluster-2
get=`kubectl get pod -o wide | grep gluster-2-pod`
read name ready  status restarts age ip node <<< `echo $get`
gluster2ip=$ip

#Create repo /srv/gluster/  [ PostgreSQL, Mongo, GitBucket ]
kubectl exec -ti gluster-1-pod -- bash -c "mkdir /srv/gluster/PostgreSQL /srv/gluster/Mongo /srv/gluster/GitBucket /srv/gluster/Redis /srv/gluster/GitLab"
kubectl exec -ti gluster-2-pod -- bash -c "mkdir /srv/gluster/PostgreSQL /srv/gluster/Mongo /srv/gluster/GitBucket /srv/gluster/Redis /srv/gluster/GitLab"

#Add resolv on /etc/hosts
kubectl exec -ti gluster-1-pod -- bash -c "gluster peer probe $gluster2ip"

kubectl exec -ti gluster-1-pod -- bash -c "gluster volume create volume-PostgreSQL replica 2 $gluster1ip:/srv/gluster/PostgreSQL $gluster2ip:/srv/gluster/PostgreSQL force"
kubectl exec -ti gluster-1-pod -- bash -c "gluster volume create volume-Mongo replica 2 $gluster1ip:/srv/gluster/Mongo $gluster2ip:/srv/gluster/Mongo force"
kubectl exec -ti gluster-1-pod -- bash -c "gluster volume create volume-GitBucket replica 2 $gluster1ip:/srv/gluster/GitBucket $gluster2ip:/srv/gluster/GitBucket force"
kubectl exec -ti gluster-1-pod -- bash -c "gluster volume create volume-Redis replica 2 $gluster1ip:/srv/gluster/Redis $gluster2ip:/srv/gluster/Redis force"
kubectl exec -ti gluster-1-pod -- bash -c "gluster volume create volume-GitLab replica 2 $gluster1ip:/srv/gluster/GitLab $gluster2ip:/srv/gluster/GitLab force"

kubectl exec -ti gluster-1-pod -- bash -c "gluster volume start volume-PostgreSQL"
kubectl exec -ti gluster-1-pod -- bash -c "gluster volume start volume-Mongo"
kubectl exec -ti gluster-1-pod -- bash -c "gluster volume start volume-GitBucket"
kubectl exec -ti gluster-1-pod -- bash -c "gluster volume start volume-Redis"
kubectl exec -ti gluster-1-pod -- bash -c "gluster volume start volume-GitLab"
