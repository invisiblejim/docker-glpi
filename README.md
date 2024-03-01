#Forked from [Diouxx/docker-glpi](https://github.com/DiouxX/docker-glpi)

The following Changes have been made from the upstream repo:

- Upgrade PHP from 7.4 to 8.1
- Configure GLPI Config, Files and Log Locations outside of wwwroot folder for better security and to separate application data from application code

I am using the following persistent GLPI volumes in Docker Compose to accomodate the additional file locations:

      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
      - glpi_version:/var/www/html/glpi   (Name this according to your current GLPI Version eg. glpi_10_0_0_5)
      - glpi_config:/etc/glpi             (Config Directory Located out of wwwroot)
      - glpi_files:/var/lib/glpi          (GLPI Files Located out of wwwroot)
      - glpi_logs:/var/log/glpi           (Log Files Located out of wwwroot)
      - glpi_phpconf:/etc/php/8.1/apache2 (facilitates config of php.ini for things like maximum upload size)
      
To upgrade your GLPI container to a newer GLPI version:

1.  Back up your GLPI Data and database by whatever means you prefer
2.  Edit your Docker compose file to rename the 'glpi_10_0_0_5' volume to the new volume number. (Do not delete or rename the actual exisiting docker volume)
3.  Specify the VERSION_GLPI environment variable for your new GLPI version
4.  Run docker compose down followed by docker compose up -d
5.  Docker will pull the image for the new version, create an new volume for the new version's application files but your data will remain on the other volumes.
6.  Browse to GLPI and complete the upgrade wizard as usual
7.  If needed, copy any required data from volume glpi_version to volume glpi_new_version (may be needed for plugins and such)
8.  Once you are happy you no longer need it you can remove volume glpi_version

This is essentially a manual upgrade orchestrated via docker compose and avoiding unnecessary copying of files.
      
      

# Project to deploy GLPI with docker

![Docker Pulls](https://img.shields.io/docker/pulls/diouxx/glpi) ![Docker Stars](https://img.shields.io/docker/stars/diouxx/glpi) [![](https://images.microbadger.com/badges/image/diouxx/glpi.svg)](http://microbadger.com/images/diouxx/glpi "Get your own image badge on microbadger.com") ![Docker Cloud Automated build](https://img.shields.io/docker/cloud/automated/diouxx/glpi)

# Table of Contents
- [Project to deploy GLPI with docker](#project-to-deploy-glpi-with-docker)
- [Table of Contents](#table-of-contents)
- [Introduction](#introduction)
  - [Default accounts](#default-accounts)
- [Deploy with CLI](#deploy-with-cli)
  - [Deploy GLPI](#deploy-glpi)
  - [Deploy GLPI with existing database](#deploy-glpi-with-existing-database)
  - [Deploy GLPI with database and persistence data](#deploy-glpi-with-database-and-persistence-data)
  - [Deploy a specific release of GLPI](#deploy-a-specific-release-of-glpi)
- [Deploy with docker-compose](#deploy-with-docker-compose)
  - [Deploy without persistence data ( for quickly test )](#deploy-without-persistence-data--for-quickly-test-)
  - [Deploy a specific release](#deploy-a-specific-release)
  - [Deploy with persistence data](#deploy-with-persistence-data)
    - [mariadb.env](#mariadbenv)
    - [docker-compose .yml](#docker-compose-yml)
- [Environnment variables](#environnment-variables)
  - [TIMEZONE](#timezone)

# Introduction

Install and run an GLPI instance with docker

## Default accounts

More info in the 📄[Docs](https://glpi-install.readthedocs.io/en/latest/install/wizard.html#end-of-installation)

| Login/Password     	| Role              	|
|--------------------	|-------------------	|
| glpi/glpi          	| admin account     	|
| tech/tech          	| technical account 	|
| normal/normal      	| "normal" account  	|
| post-only/postonly 	| post-only account 	|

# Deploy with CLI

## Deploy GLPI 
```sh
docker run --name mariadb -e MARIADB_ROOT_PASSWORD=diouxx -e MARIADB_DATABASE=glpidb -e MARIADB_USER=glpi_user -e MARIADB_PASSWORD=glpi -d mariadb:10.7
docker run --name glpi --link mariadb:mariadb -p 80:80 -d diouxx/glpi
```

## Deploy GLPI with existing database
```sh
docker run --name glpi --link yourdatabase:mariadb -p 80:80 -d diouxx/glpi
```

## Deploy GLPI with database and persistence data

For an usage on production environnement or daily usage, it's recommanded to use container with volumes to persistent data.

* First, create MariaDB container with volume

```sh
docker run --name mariadb -e MARIADB_ROOT_PASSWORD=diouxx -e MARIADB_DATABASE=glpidb -e MARIADB_USER=glpi_user -e MARIADB_PASSWORD=glpi --volume /var/lib/mysql:/var/lib/mysql -d mariadb:10.7
```

* Then, create GLPI container with volume and link MariaDB container

```sh
docker run --name glpi --link mariadb:mariadb --volume /var/www/html/glpi:/var/www/html/glpi -p 80:80 -d diouxx/glpi
```

Enjoy :)

## Deploy a specific release of GLPI
Default, docker run will use the latest release of GLPI.
For an usage on production environnement, it's recommanded to set specific release.
Here an example for release 9.1.6 :
```sh
docker run --name glpi --hostname glpi --link mariadb:mariadb --volume /var/www/html/glpi:/var/www/html/glpi -p 80:80 --env "VERSION_GLPI=9.1.6" -d diouxx/glpi
```

# Deploy with docker-compose

## Deploy without persistence data ( for quickly test )
```yaml
version: "3.8"

services:
#MariaDB Container
  mariadb:
    image: mariadb:10.7
    container_name: mariadb
    hostname: mariadb
    environment:
      - MARIADB_ROOT_PASSWORD=password
      - MARIADB_DATABASE=glpidb
      - MARIADB_USER=glpi_user
      - MARIADB_PASSWORD=glpi

#GLPI Container
  glpi:
    image: diouxx/glpi
    container_name : glpi
    hostname: glpi
    ports:
      - "80:80"
```

## Deploy a specific release

```yaml
version: "3.8"

services:
#MariaDB Container
  mariadb:
    image: mariadb:10.7
    container_name: mariadb
    hostname: mariadb
    environment:
      - MARIADB_ROOT_PASSWORD=password
      - MARIADB_DATABASE=glpidb
      - MARIADB_USER=glpi_user
      - MARIADB_PASSWORD=glpi

#GLPI Container
  glpi:
    image: diouxx/glpi
    container_name : glpi
    hostname: glpi
    environment:
      - VERSION_GLPI=9.5.6
    ports:
      - "80:80"
```

## Deploy with persistence data

To deploy with docker compose, you use *docker-compose.yml* and *mariadb.env* file.
You can modify **_mariadb.env_** to personalize settings like :

* MariaDB root password
* GLPI database
* GLPI user database
* GLPI user password


### mariadb.env
```
MARIADB_ROOT_PASSWORD=diouxx
MARIADB_DATABASE=glpidb
MARIADB_USER=glpi_user
MARIADB_PASSWORD=glpi
```

### docker-compose .yml
```yaml
version: "3.2"

services:
#MariaDB Container
  mariadb:
    image: mariadb:10.7
    container_name: mariadb
    hostname: mariadb
    volumes:
      - /var/lib/mysql:/var/lib/mysql
    env_file:
      - ./mariadb.env
    restart: always

#GLPI Container
  glpi:
    image: diouxx/glpi
    container_name : glpi
    hostname: glpi
    ports:
      - "80:80"
    volumes:
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
      - /var/www/html/glpi/:/var/www/html/glpi
    environment:
      - TIMEZONE=Europe/Brussels
    restart: always
```

To deploy, just run the following command on the same directory as files

```sh
docker-compose up -d
```

# Environnment variables

## TIMEZONE
If you need to set timezone for Apache and PHP

From commande line
```sh
docker run --name glpi --hostname glpi --link mariadb:mariadb --volumes-from glpi-data -p 80:80 --env "TIMEZONE=Europe/Brussels" -d diouxx/glpi
```

From docker-compose

Modify this settings
```yaml
environment:
     TIMEZONE=Europe/Brussels
```
