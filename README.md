<div align="center">

![PostgreSQL HA Cluster](assets/banner.jpeg)

# PostgreSQL High Availability with Patroni & etcd

### Ansible Automation for Production-Ready Clusters

[![Ansible Lint](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/ansible-lint.yml/badge.svg)](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/ansible-lint.yml)
[![CI Pipeline](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/ci.yml/badge.svg)](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/ci.yml)
[![Documentation](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/docs-check.yml/badge.svg)](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/docs-check.yml)
[![Security Scan](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/security.yml/badge.svg)](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/security.yml)
[![Release](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/release.yml/badge.svg)](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18.1-blue.svg)](https://www.postgresql.org/)
[![Patroni](https://img.shields.io/badge/Patroni-4.1.0-green.svg)](https://patroni.readthedocs.io/)

🇻🇳 [Phiên bản tiếng Việt](README-vi.md)

</div>

Ansible playbooks to automate the installation and configuration of a PostgreSQL High Availability cluster using Patroni and etcd.

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Requirements](#-requirements)
- [Quick Start](#-quick-start)
- [Configuration](#-configuration)
- [Deployment](#-deployment)
- [Application Connection](#-application-connection)
- [Cluster Management](#-cluster-management)
- [Monitoring](#-monitoring)
- [Troubleshooting](#-troubleshooting)
- [Documentation](#-documentation)
- [References](#-references)

## 🚀 Features

- ✅ **High Availability**: Automatic failover with Patroni (30-45 second failover time)
- ✅ **Distributed Configuration**: etcd cluster for consensus and leader election
- ✅ **Streaming Replication**: PostgreSQL 18.1 with async/sync replication support
- ✅ **Connection Pooling**: PgBouncer with 13x multiplexing (3000 client → 225 backend connections)
- ✅ **Multi-host Support**: JDBC/psycopg2/pg connection strings (no HAProxy needed)
- ✅ **Environment-based Config**: All settings externalized to `.env` file
- ✅ **Auto Recovery**: pg_rewind for failed primary reintegration
- ✅ **Production Ready**: Optimized for 16GB RAM, SSD, multi-core systems
- ✅ **Callback Scripts**: Event-driven monitoring and alerting

## 🏗️ Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                      Application Layer                         │
│  (Spring Boot / Python / Node.js / Java / .NET / etc.)         │
└──────────────┬──────────────┬──────────────┬───────────────────┘
               │              │              │
          Port 6432      Port 6432      Port 6432
               │              │              │
┌──────────────▼──────┐ ┌─────▼──────┐ ┌────▼───────────────────┐
│   PgBouncer (Node1) │ │ PgBouncer  │ │  PgBouncer (Node3)     │
│   Connection Pool   │ │   (Node2)  │ │  Connection Pool       │
│   Max: 1000 clients │ │            │ │  Max: 1000 clients     │
└──────────┬──────────┘ └─────┬──────┘ └────┬───────────────────┘
           │                  │              │
      Port 5432          Port 5432      Port 5432
           │                  │              │
┌──────────▼──────────┐ ┌─────▼──────┐ ┌────▼───────────────────┐
│  PostgreSQL 18.1    │ │ PostgreSQL │ │  PostgreSQL 18.1       │
│  Primary (Leader)   │ │  Replica   │ │  Replica               │
│  Read/Write         │ │  Read Only │ │  Read Only             │
└──────────┬──────────┘ └─────┬──────┘ └────┬───────────────────┘
           │                  │              │
      Port 8008          Port 8008      Port 8008
           │                  │              │
┌──────────▼──────────┐ ┌─────▼──────┐ ┌────▼───────────────────┐
│   Patroni 4.1.0     │ │  Patroni   │ │  Patroni 4.1.0         │
│   HA Manager        │ │ HA Manager │ │  HA Manager            │
└──────────┬──────────┘ └─────┬──────┘ └────┬───────────────────┘
           │                  │              │
      Port 2379          Port 2379      Port 2379
           │                  │              │
┌──────────▼──────────────────▼──────────────▼───────────────────┐
│                etcd 3.5.25 Cluster                             │
│          Distributed Configuration & Leader Election           │
│   Node1 (etcd1)  │  Node2 (etcd2)  │  Node3 (etcd3)            │
└────────────────────────────────────────────────────────────────┘

Network: 10.0.0.0/24
  - pg-node1: 10.0.0.11
  - pg-node2: 10.0.0.12
  - pg-node3: 10.0.0.13
```

### Component Versions

| Component | Version | Status |
|-----------|---------|--------|
| PostgreSQL | 18.1 | ✅ Production |
| Patroni | 4.1.0 | ✅ Production |
| etcd | 3.5.25 | ✅ Production |
| PgBouncer | 1.25.0 | ✅ Production |

## 📦 Requirements

### Hardware (per node)

**Current Deployment**:

- CPU: ~5 cores (16 cores total across cluster)
- RAM: 16 GB (48 GB total)
- Disk: 200 GB SSD (600 GB total)
- Network: 1 Gbps on 10.0.0.0/24

**Minimum (Lab/Dev)**:

- CPU: 2 cores
- RAM: 4 GB
- Disk: 20 GB (OS) + 20 GB (PostgreSQL data)
- Network: 1 Gbps

**Recommended (Production)**:

- CPU: 4-8 cores
- RAM: 16-32 GB
- Disk: 50 GB SSD (OS) + 100+ GB NVMe SSD (Data)
- Network: 10 Gbps

### Software

**Control Node (Ansible)**:

- Ansible >= 2.12
- Python >= 3.9

**Target Nodes**:

- Ubuntu 22.04 LTS / Debian 12 / Rocky Linux 9
- SSH access with root or sudo privileges
- Python 3.x installed

### Network Ports

| Service | Port | Protocol | Access | Purpose |
|---------|------|----------|--------|---------|
| **PgBouncer** | **6432** | **TCP** | **Application** | **Connection pooling (PRIMARY ACCESS)** |
| PostgreSQL | 5432 | TCP | Internal | Direct DB connections (admin/maintenance) |
| Patroni REST API | 8008 | TCP | Internal | Health checks, cluster management |
| etcd client | 2379 | TCP | Internal | Client-to-etcd communication |
| etcd peer | 2380 | TCP | Internal | etcd cluster replication |
| SSH | 22 | TCP | Admin | Remote administration |

**⚠️ Important**: Applications should connect to **PgBouncer (port 6432)**, not directly to PostgreSQL (port 5432).

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/xdev-asia-labs/postgres-patroni-etcd-install.git
cd postgres-patroni-etcd-install
```

### 2. Configure Environment Variables

**All cluster configuration is centralized in the `.env` file** (70+ variables).

```bash
# Copy example template
cp .env.example .env

# Edit with your settings
nano .env  # or vim, vi, code, etc.
```

**Critical settings to update:**

```bash
# Node IP Addresses
NODE1_IP=10.0.0.11
NODE2_IP=10.0.0.12
NODE3_IP=10.0.0.13

# PostgreSQL Passwords (REQUIRED - change these!)
POSTGRESQL_SUPERUSER_PASSWORD=your_strong_password_here
POSTGRESQL_REPLICATION_PASSWORD=your_strong_password_here
POSTGRESQL_ADMIN_PASSWORD=your_strong_password_here

# Patroni REST API Password
PATRONI_RESTAPI_PASSWORD=your_admin_password_here

# Performance tuning (adjust for your hardware)
POSTGRESQL_SHARED_BUFFERS=4GB        # 25% of RAM
POSTGRESQL_EFFECTIVE_CACHE_SIZE=12GB  # 75% of RAM
POSTGRESQL_MAX_CONNECTIONS=100
PGBOUNCER_MAX_CLIENT_CONN=1000
```

### 3. Configure Inventory

Edit `inventory/hosts.yml`:

```yaml
all:
  children:
    postgres:
      hosts:
        pg-node1:
          ansible_host: 10.0.0.11
          patroni_name: node1
          etcd_name: etcd1
        pg-node2:
          ansible_host: 10.0.0.12
          patroni_name: node2
          etcd_name: etcd2
        pg-node3:
          ansible_host: 10.0.0.13
          patroni_name: node3
          etcd_name: etcd3
```

### 4. Deploy Cluster

**Load environment variables and deploy:**

```bash
# Load .env variables (REQUIRED before ansible)
set -a && source .env && set +a

# Deploy full cluster
ansible-playbook playbooks/site.yml -i inventory/hosts.yml

# Or deploy specific components
ansible-playbook playbooks/site.yml -i inventory/hosts.yml --tags postgresql
ansible-playbook playbooks/site.yml -i inventory/hosts.yml --tags etcd
ansible-playbook playbooks/site.yml -i inventory/hosts.yml --tags patroni
ansible-playbook playbooks/site.yml -i inventory/hosts.yml --tags pgbouncer
```

### 5. Verify Deployment

```bash
# Check Patroni cluster status
ssh root@${NODE1_IP} "patronictl -c /etc/patroni/patroni.yml list"

# Expected output:
# + Cluster: postgres (7441307089994301601) ----+---------+----+-----------+
# | Member   | Host          | Role    | State   | TL | Lag in MB |
# +----------+---------------+---------+---------+----+-----------+
# | pg-node1 | 10.0.0.11 | Leader  | running |  2 |           |
# | pg-node2 | 10.0.0.12 | Replica | running |  2 |         0 |
# | pg-node3 | 10.0.0.13 | Replica | running |  2 |         0 |
# +----------+---------------+---------+---------+----+-----------+

# Check etcd cluster health
ETCDCTL_API=3 etcdctl --endpoints=http://${NODE1_IP}:2379,http://${NODE2_IP}:2379,http://${NODE3_IP}:2379 endpoint health

# Test PgBouncer connection
PGPASSWORD="${POSTGRESQL_SUPERUSER_PASSWORD}" psql -p 6432 -U postgres -h ${NODE1_IP} -c 'SELECT version();' postgres
```

## ⚙️ Configuration

### Environment Variables (.env)

All cluster settings are managed through `.env`.

**Variable Categories (70+ total):**

1. **Network Configuration** (8 vars): IPs, hostnames, network/netmask
2. **PostgreSQL Settings** (35+ vars): Version, ports, passwords, performance tuning
3. **etcd Configuration** (10 vars): Version, ports, cluster settings
4. **Patroni Settings** (16 vars): HA configuration, DCS settings, REST API
5. **PgBouncer Configuration** (18 vars): Pooling limits, timeouts, logging
6. **System Settings** (10 vars): Firewall, NTP, logging

**Loading Environment Variables:**

```bash
# REQUIRED before running Ansible
set -a && source .env && set +a

# Verify loaded
echo "Node IPs: ${NODE1_IP}, ${NODE2_IP}, ${NODE3_IP}"
echo "PostgreSQL Version: ${POSTGRESQL_VERSION}"
```

### Performance Tuning

Adjust based on your hardware in `.env`:

```bash
# For 16GB RAM (current deployment)
POSTGRESQL_SHARED_BUFFERS=4GB
POSTGRESQL_EFFECTIVE_CACHE_SIZE=12GB
POSTGRESQL_WORK_MEM=40MB
POSTGRESQL_MAINTENANCE_WORK_MEM=1GB

# For 32GB RAM
POSTGRESQL_SHARED_BUFFERS=8GB
POSTGRESQL_EFFECTIVE_CACHE_SIZE=24GB
POSTGRESQL_WORK_MEM=80MB
POSTGRESQL_MAINTENANCE_WORK_MEM=2GB

# For 64GB RAM
POSTGRESQL_SHARED_BUFFERS=16GB
POSTGRESQL_EFFECTIVE_CACHE_SIZE=48GB
POSTGRESQL_WORK_MEM=160MB
POSTGRESQL_MAINTENANCE_WORK_MEM=4GB
```

## 🔌 Application Connection

**⚠️ IMPORTANT**: Connect to **PgBouncer (port 6432)**, NOT PostgreSQL (port 5432).

### Connection Benefits

- **Connection Pooling**: 3000 client → 225 backend connections (13x multiplexing)
- **Automatic Failover**: Multi-host JDBC/psycopg2/pg support
- **Load Distribution**: Spread load across all 3 nodes
- **Resource Efficiency**: Reduced backend connection overhead

### Connection Strings

#### Java / Spring Boot

```yaml
# application.yml
spring:
  datasource:
    url: jdbc:postgresql://10.0.0.11:6432,10.0.0.12:6432,10.0.0.13:6432/postgres?targetServerType=primary&loadBalanceHosts=true
    username: postgres
    password: ${POSTGRESQL_SUPERUSER_PASSWORD}
    hikari:
      maximum-pool-size: 20       # Application pool (NOT database connections)
      minimum-idle: 5
      connection-timeout: 30000
```

#### Python (psycopg2)

```python
import psycopg2
import os

conn = psycopg2.connect(
    host="10.0.0.11,10.0.0.12,10.0.0.13",
    port=6432,
    database="postgres",
    user="postgres",
    password=os.getenv('POSTGRESQL_SUPERUSER_PASSWORD'),
    target_session_attrs="read-write"
)
```

#### Node.js (pg)

```javascript
const { Pool } = require('pg');

const pool = new Pool({
  host: '10.0.0.11',          // Or use multi-host
  port: 6432,
  database: 'postgres',
  user: 'postgres',
  password: process.env.POSTGRESQL_SUPERUSER_PASSWORD,
  max: 20,                        // Application pool size
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

#### .NET (Npgsql)

```csharp
var connectionString = "Host=10.0.0.11,10.0.0.12,10.0.0.13;" +
                       "Port=6432;" +
                       "Database=postgres;" +
                       "Username=postgres;" +
                       "Password=your_password;" +
                       "Target Session Attributes=read-write;" +
                       "Load Balance Hosts=true;" +
                       "Maximum Pool Size=20;";
```

#### Go (pgx)

```go
connString := "postgres://postgres:password@10.0.0.11:6432,10.0.0.12:6432,10.0.0.13:6432/postgres?target_session_attrs=read-write"
pool, err := pgxpool.Connect(context.Background(), connString)
```

### Direct PostgreSQL (Admin/Maintenance Only)

For administrative tasks or tools that don't support pooling:

```bash
# Single node connection (port 5432)
psql -h 10.0.0.11 -p 5432 -U postgres -d postgres

# JDBC with primary targeting
jdbc:postgresql://10.0.0.11:5432,10.0.0.12:5432,10.0.0.13:5432/postgres?targetServerType=primary
```

## 🔧 Cluster Management

### Patroni Commands

All commands executed on any cluster node:

```bash
# Check cluster status
patronictl -c /etc/patroni/patroni.yml list

# Switchover (planned leader change)
patronictl -c /etc/patroni/patroni.yml switchover --master pg-node1 --candidate pg-node2

# Failover (force new leader)
patronictl -c /etc/patroni/patroni.yml failover --force

# Restart node
patronictl -c /etc/patroni/patroni.yml restart postgres pg-node2

# Reload configuration
patronictl -c /etc/patroni/patroni.yml reload postgres pg-node2

# Reinitialize failed node
patronictl -c /etc/patroni/patroni.yml reinit postgres pg-node2
```

### Planned Switchover

Use Ansible playbook for coordinated switchover:

```bash
# Load environment
set -a && source .env && set +a

# Execute switchover
ansible-playbook playbooks/switchover.yml -i inventory/hosts.yml
```

### Failover Testing

```bash
# Stop Patroni on current leader
ssh root@${NODE1_IP} "systemctl stop patroni"

# Wait 30-45 seconds for automatic failover
sleep 40

# Check new cluster state
ssh root@${NODE2_IP} "patronictl -c /etc/patroni/patroni.yml list"

# Restart failed node (auto-joins as replica)
ssh root@${NODE1_IP} "systemctl start patroni"
```

### Rolling Updates

```bash
# Load environment
set -a && source .env && set +a

# Execute rolling update
ansible-playbook playbooks/rolling-update.yml -i inventory/hosts.yml
```

### Add New Replica

```bash
# Update inventory/hosts.yml first with new node

# Load environment
set -a && source .env && set +a

# Deploy to new node
ansible-playbook playbooks/add-replica.yml -i inventory/hosts.yml
```

## 📊 Monitoring

### Health Check Endpoints

#### Patroni REST API

```bash
# Check node health (returns 200 if healthy)
curl http://10.0.0.11:8008/health
curl http://10.0.0.12:8008/health
curl http://10.0.0.13:8008/health

# Check if node is primary (returns 200 only on leader)
curl http://10.0.0.11:8008/primary

# Check if node is replica (returns 200 only on replicas)
curl http://10.0.0.12:8008/replica
curl http://10.0.0.13:8008/replica

# Get cluster state (JSON)
curl http://10.0.0.11:8008/patroni
```

#### etcd Cluster Health

```bash
# Check all endpoints
ETCDCTL_API=3 etcdctl --endpoints=http://10.0.0.11:2379,http://10.0.0.12:2379,http://10.0.0.13:2379 endpoint health

# Check cluster status
ETCDCTL_API=3 etcdctl --endpoints=http://10.0.0.11:2379 endpoint status --write-out=table

# List etcd members
ETCDCTL_API=3 etcdctl --endpoints=http://10.0.0.11:2379 member list
```

### PgBouncer Statistics

```bash
# Connect to PgBouncer admin console
PGPASSWORD="${POSTGRESQL_SUPERUSER_PASSWORD}" psql -p 6432 -U postgres -h 10.0.0.11 pgbouncer

# Admin commands:
SHOW POOLS;           # View connection pools
SHOW CLIENTS;         # View client connections
SHOW SERVERS;         # View server connections
SHOW DATABASES;       # View configured databases
SHOW STATS;           # View statistics
SHOW CONFIG;          # View configuration
```

### PostgreSQL Monitoring Queries

```sql
-- Check active connections
SELECT count(*) FROM pg_stat_activity;

-- Connections by database
SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;

-- Replication status (on primary)
SELECT * FROM pg_stat_replication;

-- Replication lag (on primary)
SELECT 
  client_addr,
  state,
  pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes
FROM pg_stat_replication;

-- Database sizes
SELECT 
  pg_database.datname,
  pg_size_pretty(pg_database_size(pg_database.datname)) AS size
FROM pg_database
ORDER BY pg_database_size(pg_database.datname) DESC;
```

### Log Files

```bash
# Patroni logs
ssh root@10.0.0.11 "journalctl -u patroni -f"

# etcd logs
ssh root@10.0.0.11 "journalctl -u etcd -f"

# PostgreSQL logs
ssh root@10.0.0.11 "tail -f /var/lib/postgresql/18/data/log/postgresql-*.log"

# PgBouncer logs
ssh root@10.0.0.11 "tail -f /var/log/pgbouncer/pgbouncer.log"
```

### Service Status

```bash
# Check all services on a node
ssh root@10.0.0.11 "
  systemctl status postgresql@18-main
  systemctl status patroni
  systemctl status etcd
  systemctl status pgbouncer
"
```

See **[CLUSTER_CONFIG.md](CLUSTER_CONFIG.md)** for more monitoring queries and commands.

## 🛡️ Security Best Practices

### 1. Password Management

```bash
# Generate strong passwords
openssl rand -base64 32
pwgen -s 32 1

# Update .env with strong passwords
POSTGRESQL_SUPERUSER_PASSWORD=$(openssl rand -base64 32)
POSTGRESQL_REPLICATION_PASSWORD=$(openssl rand -base64 32)
POSTGRESQL_ADMIN_PASSWORD=$(openssl rand -base64 32)
PATRONI_RESTAPI_PASSWORD=$(openssl rand -base64 32)

# Secure .env file permissions
chmod 600 .env
chown $USER:$USER .env
```

### 2. File Security

```bash
# Never commit .env to git (already in .gitignore)
git ls-files --cached .env  # Should return nothing

# Use different passwords per environment
# .env.dev, .env.staging, .env.prod with different passwords

# Rotate passwords regularly (quarterly recommended)
```

### 3. Network Security

```bash
# Firewall rules (automatically configured by Ansible)
# - Port 6432 (PgBouncer): Application servers only
# - Port 5432 (PostgreSQL): Internal cluster only
# - Port 8008 (Patroni): Internal monitoring only
# - Port 2379-2380 (etcd): Internal cluster only

# Manual UFW configuration if needed:
ufw allow from 10.0.0.0/24 to any port 5432
ufw allow from <app_server_ip> to any port 6432
```

### 4. Enable Authentication (Production)

Update `.env` for production:

```bash
# Enable Patroni REST API authentication
PATRONI_RESTAPI_AUTH_ENABLED=true
PATRONI_RESTAPI_USERNAME=admin
PATRONI_RESTAPI_PASSWORD=strong_password_here

# Enable etcd authentication (optional)
ETCD_AUTH_ENABLED=true
ETCD_ROOT_PASSWORD=strong_password_here
```

### 5. SSL/TLS (Optional)

```bash
# Enable PostgreSQL SSL
POSTGRESQL_SSL_ENABLED=true
POSTGRESQL_SSL_CERT_FILE=/path/to/server.crt
POSTGRESQL_SSL_KEY_FILE=/path/to/server.key
POSTGRESQL_SSL_CA_FILE=/path/to/ca.crt
```

## 🐛 Troubleshooting

### Issue: Environment variables not loading

**Symptom**: Ansible uses default values instead of .env values

**Solution**:

```bash
# Make sure to load before running ansible
set -a && source .env && set +a

# Verify variables are loaded
echo $NODE1_IP
echo $POSTGRESQL_VERSION

# Then run ansible
ansible-playbook playbooks/site.yml -i inventory/hosts.yml
```

### Issue: Patroni fails to start

**Symptom**: `systemctl status patroni` shows failed

**Solution**:

```bash
# Check logs
ssh root@10.0.0.11 "journalctl -u patroni -n 100"

# Validate config
ssh root@10.0.0.11 "python3 -c \"import yaml; yaml.safe_load(open('/etc/patroni/patroni.yml'))\""

# Check etcd connectivity
ETCDCTL_API=3 etcdctl --endpoints=http://10.0.0.11:2379 endpoint health

# Verify PostgreSQL is stopped (Patroni manages it)
ssh root@10.0.0.11 "systemctl stop postgresql@18-main"
ssh root@10.0.0.11 "systemctl disable postgresql@18-main"
```

### Issue: etcd cluster unhealthy

**Symptom**: etcd endpoint health check fails

**Solution**:

```bash
# Check etcd status on all nodes
ETCDCTL_API=3 etcdctl --endpoints=http://10.0.0.11:2379,http://10.0.0.12:2379,http://10.0.0.13:2379 endpoint health

# Check individual node status
ssh root@10.0.0.11 "systemctl status etcd"
ssh root@10.0.0.11 "journalctl -u etcd -n 50"

# Restart etcd if needed
ssh root@10.0.0.11 "systemctl restart etcd"

# Check cluster members
ETCDCTL_API=3 etcdctl --endpoints=http://10.0.0.11:2379 member list
```

### Issue: High replication lag

**Symptom**: Lag in MB > 0 in `patronictl list`

**Solution**:

```bash
# Check replication status
ssh root@10.0.0.11 "psql -U postgres -c 'SELECT * FROM pg_stat_replication;'"

# Check network latency
ping -c 10 10.0.0.12

# Check WAL retention
ssh root@10.0.0.11 "psql -U postgres -c 'SHOW wal_keep_size;'"

# Force checkpoint to reduce lag
ssh root@10.0.0.11 "psql -U postgres -c 'CHECKPOINT;'"

# Check disk I/O
ssh root@10.0.0.12 "iostat -x 2 5"
```

### Issue: PgBouncer connection refused

**Symptom**: Applications cannot connect to port 6432

**Solution**:

```bash
# Check PgBouncer status
ssh root@10.0.0.11 "systemctl status pgbouncer"

# Check logs
ssh root@10.0.0.11 "journalctl -u pgbouncer -f"

# Verify port is listening
ssh root@10.0.0.11 "ss -tlnp | grep 6432"

# Test local connection
ssh root@10.0.0.11 "PGPASSWORD='${POSTGRESQL_SUPERUSER_PASSWORD}' psql -p 6432 -U postgres -h localhost postgres"

# Check authentication
ssh root@10.0.0.11 "cat /etc/pgbouncer/userlist.txt"
```

### Issue: Split brain after network partition

**Symptom**: Multiple nodes claim to be primary

**Solution**:

```bash
# Check which node holds leader key in etcd
ETCDCTL_API=3 etcdctl --endpoints=http://10.0.0.11:2379 get /service/postgres/leader

# Check Patroni status on all nodes
ssh root@10.0.0.11 "patronictl -c /etc/patroni/patroni.yml list"

# If needed, force failover to correct primary
ssh root@10.0.0.11 "patronictl -c /etc/patroni/patroni.yml failover --force"

# Reinitialize out-of-sync replica
ssh root@10.0.0.11 "patronictl -c /etc/patroni/patroni.yml reinit postgres pg-node2"
```

### Issue: Deployment fails with apt lock

**Symptom**: "Could not get lock /var/lib/dpkg/lock"

**Solution**:

```bash
# Check for running apt processes
ssh root@10.0.0.11 "ps aux | grep -i apt"

# Kill unattended-upgrades if blocking
ssh root@10.0.0.11 "systemctl stop unattended-upgrades"
ssh root@10.0.0.11 "killall apt apt-get"

# Remove locks
ssh root@10.0.0.11 "rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock*"

# Re-run Ansible
set -a && source .env && set +a
ansible-playbook playbooks/site.yml -i inventory/hosts.yml
```

## 📚 Documentation

This project includes comprehensive documentation:

- **[README.md](README.md)** - Complete documentation (English)
- **[README-vi.md](README-vi.md)** - Complete documentation (Vietnamese)
- **[.env.example](.env.example)** - Configuration template

## 🎯 Key Features Summary

### High Availability

- **Automatic Failover**: 30-45 second failover time with Patroni
- **Zero Data Loss**: Synchronous replication support (optional)
- **Auto Recovery**: pg_rewind for failed primary reintegration
- **Health Monitoring**: REST API endpoints for load balancers

### Performance

- **Connection Pooling**: PgBouncer with 13x multiplexing (3000 → 225 connections)
- **SSD Optimized**: `random_page_cost=1.1`, `effective_io_concurrency=200`
- **Parallel Queries**: Match CPU cores for optimal performance
- **Memory Tuning**: Optimized for 16GB RAM (scalable to 64GB+)

### Operational Excellence

- **Single Source of Truth**: All 70+ config variables in `.env`
- **Multi-Environment**: Easy switching between dev/staging/prod
- **Version Control Friendly**: `.env` gitignored, `.env.example` committed
- **Comprehensive Docs**: 45KB+ documentation covering all aspects

### Production Ready

- **Battle Tested**: PostgreSQL 18.1, Patroni 4.1.0, etcd 3.5.25
- **Security Focused**: MD5 auth, firewall rules, password management
- **Monitoring Ready**: Prometheus-compatible metrics, health endpoints
- **Backup Support**: Ready for pgBackRest, Barman, or WAL-G integration

## 🚀 Performance Characteristics

### Current Deployment (16GB RAM per node)

```yaml
Hardware:
  CPU: ~5 cores per node (16 cores total)
  RAM: 16 GB per node (48 GB total)
  Disk: 200 GB SSD per node (600 GB total)
  Network: 1 Gbps on 10.0.0.0/24

Connection Capacity:
  Client Connections: 3,000 max (1,000 per node)
  Backend Connections: 225 typical, 300 max
  Multiplexing Efficiency: 13x

Expected Performance:
  Read Queries: 50,000-100,000 QPS (distributed)
  Write Queries: 10,000-20,000 QPS (primary only)
  Mixed Workload: 30,000-50,000 QPS
  Query Latency: <5ms (simple), varies (complex)
  Failover Time: 30-45 seconds typical
```

## 📋 Deployment Checklist

- [ ] Clone repository
- [ ] Copy `.env.example` to `.env`
- [ ] Update passwords in `.env` (CRITICAL)
- [ ] Update node IPs in `.env`
- [ ] Adjust performance settings for hardware
- [ ] Configure `inventory/hosts.yml`
- [ ] Load environment: `set -a && source .env && set +a`
- [ ] Deploy cluster: `ansible-playbook playbooks/site.yml -i inventory/hosts.yml`
- [ ] Verify Patroni cluster: `patronictl list`
- [ ] Verify etcd health: `etcdctl endpoint health`
- [ ] Test PgBouncer connection: `psql -p 6432`
- [ ] Update application connection strings (port 6432)
- [ ] Test application connectivity
- [ ] Setup monitoring/alerting
- [ ] Schedule backups
- [ ] Document runbooks

## 🔗 External References

- [PostgreSQL 18 Documentation](https://www.postgresql.org/docs/18/)
- [Patroni Documentation](https://patroni.readthedocs.io/)
- [etcd Documentation](https://etcd.io/docs/)
- [PgBouncer Documentation](https://www.pgbouncer.org/)
- [Ansible Documentation](https://docs.ansible.com/)

## 📝 License

MIT License - See [LICENSE](LICENSE) file for details.

## 👥 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a Pull Request

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/issues)
- **Discussions**: [GitHub Discussions](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/discussions)

---

**Maintained by**: [xdev.asia](https://xdev.asia)  
**Last Updated**: November 25, 2025  
**Cluster Status**: ✅ Fully Operational
