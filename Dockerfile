FROM rockylinux:9.3 AS base

# Install necessary packages and clean up in one layer
RUN dnf -y update && \
    dnf install -y wget telnet jq vim sudo gnupg openssh-server openssh-clients \
                   procps-ng net-tools iproute iputils less diffutils watchdog epel-release && \
    dnf clean all && rm -rf /var/cache/dnf

# Install libmemcached-awesome directly from the repository
RUN dnf install -y https://dl.rockylinux.org/pub/rocky/9/CRB/x86_64/os/Packages/l/libmemcached-awesome-1.1.0-12.el9.x86_64.rpm && \
    dnf --enablerepo=crb install -y libmemcached-awesome && \
    dnf clean all

# Install EnterpriseDB PostgreSQL Extended Repo and core packages
ARG MYTOKEN=""
RUN curl -1sSLf "https://downloads.enterprisedb.com/${MYTOKEN}/enterprise/setup.rpm.sh" | bash && \
    dnf -y install edb-postgresextended17-server edb-postgresextended17-contrib edb-efm50 repmgr17 pgbouncer && \
    dnf clean all 

# Install PostgreSQL repository
RUN dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    dnf clean all 

# Install additional PostgreSQL tools
RUN dnf install -y libssh2 pgbackrest patroni-etcd pg_top pg_activity haproxy && \
    dnf clean all 

# Install pgpool-II
RUN dnf install -y https://www.pgpool.net/yum/rpms/4.6/redhat/rhel-9-x86_64/pgpool-II-release-4.6-1.noarch.rpm && \
    dnf install -y pgpool-II-pg17 pgpool-II-pg17-extensions && \
    dnf clean all 

# Some permission fixes
RUN chown -R postgres:postgres /etc/pgbackrest.conf /etc/pgpool-II


# Create necessary directories
RUN mkdir -p /pgdata/17 /var/log/etcd /var/log/patroni /pgha/{config,certs,data/{etcd,postgres,pgbackrest}} && \
    chown -R postgres:postgres /pgdata /var/log/etcd /var/log/patroni /pgha

# Copy configuration files and scripts
COPY pg_custom.conf / 
COPY pg_hba.conf / 
COPY pg_hba_md5.conf / 
COPY pgsqlProfile / 
COPY id_rsa / 
COPY id_rsa.pub / 
COPY authorized_keys / 
COPY proxysql.cnf / 
COPY recovery_1st_stage / 
COPY follow_primary.sh / 
COPY pgpool_remote_start / 
COPY failover.sh / 
COPY etcdSetup / 
COPY patroniSetup / 
COPY createRoles / 
COPY stopPatroni / 
COPY startPatroni / 

# Set ownership and permissions for copied files
RUN chown postgres:postgres /recovery_1st_stage /follow_primary.sh /pgpool_remote_start /failover.sh /etcdSetup /patroniSetup /createRoles /stopPatroni /startPatroni && \
    chmod 755 /recovery_1st_stage /follow_primary.sh /pgpool_remote_start /failover.sh /etcdSetup /patroniSetup /createRoles /startPatroni /stopPatroni

# Expose ports
EXPOSE 22 80 443 5432 2379 2380 6032 6033 6132 6133 8432 5000 5001 8008 9999 9898 7000 

# Entrypoint
COPY entrypoint.sh / 
RUN chmod +x /entrypoint.sh 
ENTRYPOINT ["/entrypoint.sh"]
