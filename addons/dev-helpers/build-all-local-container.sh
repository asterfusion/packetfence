#!/bin/bash

set -o nounset -o pipefail -o errexit
PF_PATH=/usr/local/pf

source $PF_PATH/addons/functions/helpers.functions

cd $PF_PATH

main_splitter

name="${1:-}"
if [ -z "$name" ]; then
  DOCKERFILE_DIRS=$(find containers/ -type f -name "Dockerfile" \
                         -not -path "*/pfdebian/*" \
                         -not -path "*/radiusd/*" \
                         -not -path "*/pfconnector-*/*" \
                         -printf "%P\n")
  for file in ${DOCKERFILE_DIRS}; do
    # remove /Dockerfile suffix
    CONTAINERS_IMAGES+=" ${file%/Dockerfile}"
  done
else
  CONTAINERS_IMAGES+="$name"
fi

for img in ${CONTAINERS_IMAGES}; do
  dockerfile=containers/$img/Dockerfile

  if ! [ -f $dockerfile ]; then
    echo "'$img' is not a valid container name."

    sub_splitter

    echo "The following images can be built using this tool:"
    output_all_container_images

    exit 1
  fi

  if  [ -e result/debian/$img.tar.gz ]; then
    echo "The images $img.tar.gz alreay exist"
    continue
  fi
  source $PF_PATH/conf/build_id

  img_name=packetfence/$img:$TAG_OR_BRANCH_NAME

  echo "Building image $img_name"

  sub_splitter
  if docker images --quiet --filter "reference=$img_name";then
	  echo "$img_name exists"
  else
  	if [ "$img" == "fingerbank-db" ];then 
  		docker pull ghcr.io/inverse-inc/packetfence/fingerbank-db:$TAG_OR_BRANCH_NAME
    		docker tag ghcr.io/inverse-inc/packetfence/fingerbank-db:$TAG_OR_BRANCH_NAME $img_name 
  	else	  
  		docker build -t $img_name \
    		--build-arg=BUILD_PFAPPSERVER_VUE=yes \
    		--build-arg=KNK_REGISTRY_URL=ghcr.io/inverse-inc/packetfence \
    		--build-arg=IMAGE_TAG=$TAG_OR_BRANCH_NAME \
    		-f containers/$img/Dockerfile .
  	fi
        echo "New image build from $dockerfile -> $img_name"
  fi
  main_splitter

  docker save -o result/debian/$img.tar.gz $img_name
  echo "docker save -o result/debian/$img.tar.gz  $img_name"
done
