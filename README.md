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

* `-p 80` - Port for adagios webui

For shell access whilst the container is running do `docker exec -it my-adagios /bin/bash`.
