#!/bin/bash

timestamp=$(date +%Y%m%d_%H%M%S)
log_path="`pwd`"
filename=docker_cleanup_$timestamp.log
log=$log_path/$filename


docker_space_before(){
CURRENTSPACE=`docker system df`
}
docker_find (){
REMOVEIMAGES=`docker images | grep " [seconds|minutes|hours|days|months|weeks]* ago" | awk '{print $3}'`

}

docker_cleanup(){
docker rmi ${REMOVEIMAGES}
}

docker_space_after(){
CURRENTSPACE=`docker system df`
}
docker_space_before
docker_find
docker_cleanup
docker_space_after
