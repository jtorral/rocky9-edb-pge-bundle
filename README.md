# rocky9-pge17-bundle ( EDB - PGE )


This docker bundle uses the enterprisedb (EDB) **PGE** distribution.
You will need an access token in order to download the packages from the EDB repository.

PGE is what is known as Enterprisedb's **Postgres Extended Server**, which is a specialized distribution of the open source postgres database.

PGE is designed to provide an enterprise ready version of postgres by adding a limited number of advanced features that can't be implemented purely as extensions to the community version, while maintaining core compatibility

Some benefits of PGE includes additional features such as ..

- Transparent Data Encryption (TDE) which is a significant addition, as it encrypts data at rest, addressing a critical security requirement for many enterprises.
-  Enhanced Replication Optimization which includes features that optimize replication, which are used by other EDB tools like EDB Postgres Distributed to support high availability and geo distributed clusters.
- WAL Pacing Delays is an operational feature to avoid flooding transaction logs (WAL), helping to maintain system stability.
- Security Features like password profiles and data redaction to limit the exposure of sensitive data.

In addition to using PGE for this bundle, there are additional packages which can be levereged for training or just practicing and experimenting. This bundle, like the [rocky9-pg17-bundle](https://github.com/jtorral/rocky9-pg17-bundle) which uses the community edition of postgres 17 includes additional packages as listed below.

 - pgbackrest
 - pgbouncer
 - patroni-etcd
 - pg_repack_17
 - pg_top
 - repmgr_17
 - haproxy
 - proxysql
 - etcd
 - pgpool-II


## UPDATE
Finally added the ARM version so you can run on an **M*x*** Mackbook  or other ARM based systems


### 1. Docker Image Building and Container Creation

To create the Docker image, clone the repository from the provided GitHub link and run the `docker build` command. This command builds an image tagged as **rocky9-pg17-bundle** from the `Dockerfile` in the local directory.

https://github.com/jtorral/rocky9-pg17-bundle

### Build the image

The EDB distributions require a subscription in order to download from the repository. With that being said, you should have an access token in order to access the repository. You will need this access token as part of your docker build command.

**You will need your access token to run the build command.**

For example, to build the docker image on regular **x86 system** you would run your docker build command as follows:

    docker build --build-arg MYTOKEN="your_access_toke_here" --progress=plain -t rocky9-pge17-bundle .

The above flag **`--progress=plain`** will help identify any issues by providing more details during the docker build process

For the **ARM based system** build the image using these options. Don't forget the dot at the end.

    docker build -f DockerfileArm --progress=plain  --build-arg TARGETARCH=aarch64 --build-arg MYTOKEN="your_access_token_here" -t rocky9-pge17-bundle-arm .

In the above command we ( Optionally change the image name to **rocky9-pg17-bundle-arm** but you could leave it as **rocky9-pg17-bundle** if you like.


### Technical Note: AArch64 (ARM) Implementation

**Due to the current lack of widespread AArch64 optimized RPM packages for certain dependencies, particularly when compared to standard x86 repositories, this Dockerfile had to be engineered to fetch and compile packages directly from source within the build environment. While this approach ensures functionality (validated on my MacBook Pro M4), please consider this an actively developing component. Feedback on any issues encountered during your ARM based build is highly appreciated.**

## Some notes on the PGE install

Some default file locations and environment setting shave change from the community version.

For example ...

postgres bin directory for the EDB distribution is:

    /usr/edb/pge17/bin

The socket dir for postgres is now 

    /var/run/edb-pge

These changes affect how you connect to the database.  Having saud that, make sure you either

    export PGHOST=/var/run/edb-pge

or 

Run psql locally as 

    psql -h /var/run/edb-pge

If you export PGHOST as noted above, a simple psql will connect you.

Or you can connect to local host as well

    psql -h 127.0.0.1


You can then run the [genDeploy](https://github.com/jtorral/rocky9-pg17-bundle/blob/main/genDeploy.md) script included in this repo.

To generate the run commands needed for your deployment.  It is advisable to use the genDeploy script. However, if you wish to generate your own docker run commands, you will need to follow steps below.

## Steps needed if not using genDeploy from above.

After building the image, a **custom network** named `pgnet`  or whatever name you decide upon is created to allow communication between the containers.

### Create the network

    docker network create pgnet


### Create the containers

The following demonstrates how to create three separate PostgreSQL containers (`pg1`, `pg2`, and `pg3`) and one Pgpool container (`pgpool`).

```
docker run -p 6431:5432 --env=PGPASSWORD=postgres -v pg1-pgdata:/pgdata --hostname pg1 --network=pgnet --name=pg1 -dt rocky9-pg17-bundle

docker run -p 6432:5432 --env=PGPASSWORD=postgres -v pg2-pgdata:/pgdata --hostname pg2 --network=pgnet --name=pg2 -dt rocky9-pg17-bundle

docker run -p 6433:5432 --env=PGPASSWORD=postgres -v pg3-pgdata:/pgdata --hostname pg3 --network=pgnet --name=pg3 -dt rocky9-pg17-bundle
```

**The above are simple examples. Again, it is adviseabl to use the genDeploy scripts for consitency and ease of management.**

Each `docker run` command uses specific flags:

-   `-p` Maps ports from the host to the container. For example, `-p 6431:5432` maps the host's port `6431` to the container's PostgreSQL port `5432`.

-   `--env=PGPASSWORD=postgres`  Sets the `PGPASSWORD` environment variable to `postgres` inside the container.

-   `-v`  Creates a **Docker volume** to persist the PostgreSQL data.

-   `--hostname` Assigns a hostname to the container.

-   `--network=pgnet`  Connects the container to the `pgnet` network.

-   `--name`  Assigns a name to the container for easy identification.

-   `-dt`  Runs the container in **detached mode** (`-d`) and allocates a pseudo-TTY (`-t`).


***Note***

By default, the containers do not automatically start the PostgreSQL service. To start the service, you need to execute a command within the container or modify your docker run command to run it automatically. Just simply add the following to the docker run command.

```
--env=PGSTART=1
```

For example ...

```
docker run -p 6431:5432 --env=PGPASSWORD=postgres --env=PGSTART=1 -v pg1-pgdata:/pgdata --hostname pg1 --network=pgnet --name=pg1 -dt rocky9-pg17-bundle
```



### 2. Starting PostgreSQL within a Container

By default, the containers do not automatically start the PostgreSQL service. To start the service, you need to execute a command within the container.

1.  Access the container's shell using `docker exec`

```
docker exec -it pg1 /bin/bash
```

This command provides an **interactive terminal** (`-i`) and allocates a pseudo-TTY (`-t`) to the `pg1` container.

2. Switch to the `postgres` user and start the PostgreSQL server

```
[root@pg1 /]# su - postgres

[postgres@pg1 data]$ pg_ctl start

waiting for server to start....2025-08-27 16:59:11.237 UTC [] [325]: [1-1] user=,db=,host= LOG: redirecting log output to logging collector process
2025-08-27 16:59:11.237 UTC [] [325]: [2-1] user=,db=,host= HINT: Future log output will appear in directory "log".
done
server started

[postgres@pg1 data]$ psql
psql (17.6)
Type "help" for help.
```

### 3. Accessing PostgreSQL

You can connect to the PostgreSQL instances from your local machine (outside the Docker container) using the `psql` command-line tool.

-   To connect, you need the **hostname** (`-h`), the **mapped port** (`-p`), the **username** (`-U`), and to be prompted for a password (`-W`).

-   For instance, to connect to the `pg1` container which is mapped to port `6431`

```
psql -h localhost -p 6431 -U postgres -W
```

For example ...

```
jtorral@jt-p16-fedora:/GitStuff/rocky9-pg17-bundle$ psql -h localhost -p 6431 -U postgres -W
Password:
psql (17.5, server 17.6)
Type "help" for help.

postgres=#
```
