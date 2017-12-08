# docker-adagios-git
Docker image for Adagios built from git (Nagios 4-Adagios)

[![Docker Stars](https://img.shields.io/docker/stars/opinkerfi/adagios-git.svg)]()
[![Docker Pulls](https://img.shields.io/docker/pulls/opinkerfi/adagios-git.svg)]()
[![GitHub tag](https://img.shields.io/github/tag/opinkerfi/adagios-git.svg)]()
[![GitHub release](https://img.shields.io/github/release/opinkerfi/adagios-git.svg)]()

## Usage
 

```
docker create \ 
  --name=my-adagios \
  -p 80:80 \
  opinkerfi/adagios-git
```

Log in with user `thrukadmin` and password `thrukadmin`

## Parameters

The parameters are split into two halves, separated by a colon, the left hand side representing the host and the right the container side. 
For example with a port -p external:internal - what this shows is the port mapping from internal to external of the container.
So -p 8080:80 would expose port 80 from inside the container to be accessible from the host's IP on port 8080
http://192.168.x.x:8080 would show you what's running INSIDE the container on port 80.

* `-p 80` - Port for Adagios webui

For shell access whilst the container is running do `docker exec -it my-adagios /bin/bash`.

To access Adagios
:80/adagios
To access Nagios 4 UI
:80/nagios

## Local development of Adagios with adagios-git docker image

### Via docker run command

```SHELL
docker run -it -p 8080:80 \
-v ~/code/test/adagios:/opt/adagios \
-v ~/code/test/pynag:/opt/pynag \
-v ~/code/test/logs:/var/log/nagios \
--name adagios opinkerfi/adagios-git:latest
```
### Via docker-compose

```SHELL
docker-compose up
```
where the contents of docker-compose.yml is similar to the example provided

```YAML
version: '3.1'

services:
  adagios:
    image: opinkerfi/adagios-git:latest
    ports:
      - 8080:80
    volumes:
      - adagios:/opt/adagios
      - pynag:/opt/pynag
      - logs:/var/log/nagios
      - nagios:/etc/nagios

volumes:
  adagios:
  pynag:
  logs:
  nagios:

```

### Basic development environment setup via shell script

We have created a small script that you can use to setup the local development environment

```SHELL
cd ~/my/adagios/env/dev/folder # Folder that you want to keep the code for pynag and adagios
curl https://raw.githubusercontent.com/opinkerfi/docker-adagios-git/master/setup_dev_env.sh | bash - 
```
