landregistry-wsgi
=================

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup - The basics of getting started with WSGI](#setup)
    * [Beginning with wsgi](#beginning-with-wsgi)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
7. [Release notes](#release-notes)


## Overview

Manages the installation and configuration of Python WSGI applications intended to be run on Land Registry infrastructure.


## Module Description

LandRegistry-WSGI provides a new Puppet type, `wsgi::application`, which handles the installation and configuration of Python WSGI applications using Gunicorn and SystemD.


## Setup


### Beginning with wsgi

Simply providing a git repository to pull your application's source code from, as well as a network port to bind to is enough to get started.

``` puppet
wsgi::application { 'cases-frontend':
  bind   => '5000',
  source => 'https://github.com/LandRegistry/cases-frontend.git'
}
```


### Directory structure of WSGI applications

Python WSGI applications deployed using LandRegistry-WSGI will
have the following structure:

| File/Directory           | Description                                           |
|--------------------------|-------------------------------------------------------|
| logs/                    | Runtime access and output logs for the service        |
| source/                  | Application code, identical to git repository         |
| virtualenv/              | Python 3 environment containing third-party libraries |
| COMMIT                   | Git commit hash of the deployed application           |
| lr-*APPLICATION*.pid     | Process ID for the service while it is running        |
| lr-*APPLICATION*.service | SystemD unit file for running the service             |
| settings.conf            | Variables that will be exposed to the service         |
| startup.sh               | Starts the service & runs maintenance tasks           |
| VERSION                  | Semantic version number of the deployed application   |


Full representation of the directory structure:

    /opt/landregistry/applications/APPLICATION
      ├── logs/
      │    ├── access.log
      │    └── error.log
      ├── source/
      │    ├── acceptance_tests/
      │    ├── application/
      │    │    ├── static/
      │    │    ├── templates/
      │    │    └── routes.py
      │    ├── tests/
      │    ├── config.py
      │    ├── manage.py
      │    └── requirements.txt
      ├── virtualenv/
      │    ├── bin/
      │    │    ├── activate
      │    │    ├── easy_install
      │    │    ├── gunicorn
      │    │    ├── pip
      │    │    └── python -> /usr/local/bin/python3.4
      │    ├── include/
      │    ├── lib/
      │    │    └── python3.4/
      │    │         └── site-packages/
      │    ├── lib64 -> lib
      │    └── pyvenv.cfg
      ├── COMMIT
      ├── lr-APPLICATION.pid
      ├── lr-APPLICATION.service -> /usr/lib/systemd/system/lr-APPLICATION.service
      ├── settings.conf
      ├── startup.sh
      └── VERSION


## Usage

Coming soon...


## Reference

Coming soon...


## Limitations

Currently LandRegistry::WSGI makes some fairly strict assumptions about your system and setup. It's not recommended that this module is used by the general public at this point.

Firstly, only Git is currently supported as a source. Installation from a package will come soon, but will be fairly inflexible.

Secondly, it is assumed that you wish to install your application under `/opt/landregistry/applications`.

Thirdly, Gunicorn is currently the only available web server supported.


## Development

Coming soon...


## Release Notes

June 08 2015 - [**0.1.0**] Initial alpha release
