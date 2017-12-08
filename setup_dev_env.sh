#!/bin/bash

if [ ! -d adagios ]; then
  echo "Cloning Adagios"
  git clone git://github.com/opinkerfi/adagios.git adagios
fi

if [ ! -d pynag ]; then
  echo "Cloning Pynag"
  git clone git://github.com/pynag/pynag.git pynag
fi

if [ ! -f docker-compose.yml ]; then
  read -sn 1 -p "Do you want me to fetch docker-compose.yml (y|n)? "
  if [[ $REPLY == "y" ]]; then
    curl https://raw.githubusercontent.com/opinkerfi/docker-adagios-git/master/docker-compose.yml > docker-compose.yml
  fi
fi

if [ -f docker-compose.yml ]; then
  read -sn 1 -p "Do you want me to start the docker instance via docker-compose (y|n)? "
  if [[ $REPLY == "y" ]]; then
    docker-compose up
  fi
fi

