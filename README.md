# Migrating MySQL cluster to Google Compute Engine using HAProxy

## Overview
This repository contains the accompanying code for the [Migrating a MySQL cluster to Compute Engine Using HAProxy](https://cloud.google.com/solutions/migrating-mysql-cluster-compute-engine-haproxy) tutorial.


## Files
* `client.sh` - Startup script for the MySQL client instance.
* `mysql-startup.sh` - Startup script for MySQL server instances. It configures either a primary or replica instance based on instance metadata and populates a sample database.
* `mysql-dm.jinja` - Contains a Deployment Manager template for instanciating a MySQL cluster composed of a primary and replica instances, plus one client instance.
* `run.sh` - This script brings it all together. It copies the files to a GCS bucket and runs deployment manager.
Usage : `./run.sh PROJECT_ID GCS_BUCKET_NAME`
