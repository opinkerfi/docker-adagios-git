# docker-adagios-git
Docker image for Adagios built from git.
The image has Adagios running with Nagios 4, PNP4Nagios and Livestatus.

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

Log in with user `nagiosadmin` and password `nagiosadmin`

## Parameters

The parameters are split into two halves, separated by a colon, the left hand side representing the host and the right the container side. 
For example with a port -p external:internal - what this shows is the port mapping from internal to external of the container.
So -p 8080:80 would expose port 80 from inside the container to be accessible from the host's IP on port 8080
http://192.168.x.x:8080 would show you what's running INSIDE the container on port 80.

* `-p 80` - Port for Adagios webui
* `-p 6557` - Port for MK Livestatus - https://mathias-kettner.de/checkmk_livestatus.html

For shell access whilst the container is running do `docker exec -it my-adagios /bin/bash`.

To access Adagios
:80/adagios
To access Nagios 4 UI
:80/nagios

## Local development of Adagios with adagios-git docker image

### Via docker run command
This docker command runs Adagios on http://localhost:8080 and MK Livestatus on 6557/tcp.
The Adagios/Pynag code from github is accessable in your local ~/code directory so you can make any changes and then restart the container to see the progress of your work. Adagios uses MK Livestatus for communicating with Nagios and it is possible to communicate with Livestatus remotely on port 6557/tcp. Please see the guide below for more information on Livestatus communication. 

```SHELL
docker run -it -p 8080:80 \
-p 6557:6557 \
-v ~/code/adagios:/opt/adagios \
-v ~/code/pynag:/opt/pynag \
-v ~/code/logs:/var/log/nagios \
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
      - 6557:6557
    volumes:
      - ./adagios:/opt/adagios
      - ./pynag:/opt/pynag
      - ./logs:/var/log/nagios

volumes:
  adagios:
  pynag:
  logs:

```

### Basic development environment setup via shell script

We have created a small script that you can use to setup the local development environment

```SHELL
cd ~/my/adagios/env/dev/folder # Folder that you want to keep the code for pynag and adagios
bash -c "$(curl -L https://raw.githubusercontent.com/opinkerfi/docker-adagios-git/master/setup_dev_env.sh)"
```
To access your Adagios development container, direct your browser to http://0.0.0.0:8080
Now do some changes with your Adagios or Pynag code inside your local volumes that you created before and restart your container.

```SHELL
docker-compose restart
```
When the container restarts it will install Adagios and Pynag from your local volumes.
Your new code changes should now reflect on your Adagios developement container.

## Working with Livestatus remotely

Get status information for all hosts with Livestatus
```SHELL
echo "GET hosts" | nc localhost 6557
```
