#!/usr/bin/env bash

# ------------------------------------------------------
# ------------------------------------------------------
# author: LHW1987654@163.com
# ------------------------------------------------------
# ------------------------------------------------------

TARGET_PATH="$1"
# docker image name
IMAGE_NAME='anaconda'
# docker container name
CONTAINER_NAME='anaconda'
# docker container full repository
CONTAINER_FULL="daocloud.io/lhw1987654/dev-env:$IMAGE_NAME"
#valume path
#>>>>>>>>>>>[ Please modify the path below to your path ] <<<<<<
BASE_PATH='/pd/tank'
#http port
HTTP_PORT='9988'
#passowrd, DO NOT modify unless you know how to generate it 
#ref:https://jupyter-notebook.readthedocs.io/en/stable/public_server.html
#ref:http://blog.runsheng.xyz/start-a-ipython-notebook-server-with-password-login.html
PASSWORD='123456'
PASSWORD_HASH='sha1:957ad9084964:d525192eb6fcbea0051ec33d0183f2d3768a3027'

# ------------------------------------------------------
# do not modify
TARGET_VALUME='/opt/notebooks'

# ------------------------------------------------------
path_replace() {
  A=` echo $2 | sed -e 's/\//@@@/g' `
  B=` echo $3 | sed -e 's/\//@@@/g' `
  C=` echo $1 | sed -e 's/\//@@@/g' `
  C=`echo $C | sed -e "s/$A/$B/" `
  echo $C | sed -e 's/@@@/\//g'
}
realpath ()
{
    f=$@;
    if [ -d "$f" ]; then
        base="";
        dir="$f";
    else
        base="/$(basename "$f")";
        dir=$(dirname "$f");
    fi;
    dir=$(cd "$dir" && /bin/pwd);
    echo "$dir$base"
}
checkTargetPath(){
	echo "Info: checking target path ..."
	if [ ! -d "$BASE_PATH" ]; then
		echo "Error: The base path dose not exist: $BASE_PATH"
		echo "Error: Please edit this shell file and modify the BASE_PATH"
		exit
	fi
	if [ ! -n "$TARGET_PATH" ]; then
		echo "Warning: parameter directory missing. will using current path"
		TARGET_PATH=`pwd`
	fi

	if [ ! -d "$TARGET_PATH" ]; then
		echo "Error: directory dose not exist: $TARGET_PATH"
		exit
	fi

	TARGET_PATH=`realpath "$TARGET_PATH"`

	if [ ! -d "$TARGET_PATH" ]; then
		echo "Error: after realpath operation, the directory dose not exist: $TARGET_PATH"
		exit
	fi

	TARGET_PATH=`path_replace  "$TARGET_PATH" "$BASE_PATH/" "$TARGET_VALUME/" `

	echo "Info: got target path: $TARGET_PATH"
}

# ------------------------------------------------------
checkDockerImage(){
	echo "Info: checking docker image $IMAGE_NAME... "
	ANACODA=`docker images | grep "$IMAGE_NAME" | awk '{print $1":"$2}'`
	if [ ! -n "$ANACODA" ]; then
		echo "Warning: no $IMAGE_NAME docker image found!"
		echo "Warning: will pull docker image $IMAGE_NAME "
		docker pull "$CONTAINER_FULL"
	fi

	ANACODA=`docker images | grep "$IMAGE_NAME" | awk '{print $1":"$2}'`
	if [ ! -n "$ANACODA" ]; then
		echo "Error: no $IMAGE_NAME docker image found!"
		echo "Error: It seems pulling docker image $IMAGE_NAME failed"
		exit
	fi
	echo "Info: got docker image: $ANACODA"
}

# ------------------------------------------------------
checkDockerContainer(){
	echo "Info: checking docker container $CONTAINER_NAME ..."
	#CONTAINER=`docker ps --format "table {{.Names}}" | grep "$CONTAINER_NAME"`
	CONTAINER=`docker ps | grep "$CONTAINER_NAME" | rev | awk '{print $1}' | rev`
	if [ ! -n "$CONTAINER" ]; then
		echo "Warning: docker container $CONTAINER_NAME is not found"
		echo "Info: running docker container and will name the container as $CONTAINER_NAME"
		
	docker run -d --name "$CONTAINER_NAME" \
	  -e "PASSWORD=$PASSWORD" \
	  -p "$HTTP_PORT:8888" \
	  -P --hostname=newdev \
	  -v "$BASE_PATH:$TARGET_VALUME" \
	  -v /tmp:/tmp \
	  --restart=always \
	  "$ANACODA"
	fi

	#CONTAINER=`docker ps --format "table {{.Names}}" | grep "$CONTAINER_NAME"`
	CONTAINER=`docker ps | grep "$CONTAINER_NAME" | rev | awk '{print $1}' | rev`
        if [ ! -n "$CONTAINER" ]; then
		echo "Error: no $CONTAINER_NAME docker container found!"
		echo "Error: It seems pulling docker container $CONTAINER_NAME failed"
		exit
	fi
	docker exec anaconda  jupyter notebook --generate-config --allow-root -y
	docker exec anaconda  bash -c "echo \"c.NotebookApp.password = u'$PASSWORD_HASH'\" >> /root/.jupyter/jupyter_notebook_config.py "
	echo "Info: got docker container: $CONTAINER"
}

# ------------------------------------------------------
printPassword(){
	echo '-----------------------------------------------------------------'
	echo '-----------------------------------------------------------------'
	echo "                   Your passowrd is $PASSWORD                    "
	echo '-----------------------------------------------------------------'
	echo '-----------------------------------------------------------------'	
}

# ------------------------------------------------------
removeContainer(){
	if [ 'reset' == "$TARGET_PATH" ]; then
		echo "Warning: removing container $CONTAINER_NAME"
		docker rm -f "$CONTAINER_NAME"
		TARGET_PATH="$2"
	fi
}

# ------------------------------------------------------
jupyterNotebook(){
	echo "Info: staring jupyter notebook ..."
	docker exec "$CONTAINER_NAME" \
		jupyter notebook \
		--notebook-dir="$TARGET_PATH" \
		--ip=* \
		--port=8888 \
		--no-browser \
		-y \
		--debug \
		--allow-root
}

# ------------------------------------------------------
# main procedure

removeContainer
checkTargetPath
checkDockerImage
checkDockerContainer
printPassword
URL="http://localhost:$HTTP_PORT/login?next=%2Ftree&password=$PASSWORD"
echo "Your url: $URL"
open "$URL"
jupyterNotebook









