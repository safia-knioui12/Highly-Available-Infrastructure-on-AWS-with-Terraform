#!/bin/bash
set -e

# Update system
yum update -y

# Enable PostgreSQL (Amazon Linux Extras)
amazon-linux-extras enable postgresql14 -y

# Install PostgreSQL
yum install -y postgresql postgresql-server postgresql-contrib

# Initialize database
postgresql-setup initdb

# Enable and start service
systemctl enable postgresql
systemctl start postgresql

# Optional: allow password login (basic dev setup)
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/data/postgresql.conf
sed -i "s/#password_encryption = scram-sha-256/password_encryption = scram-sha-256/" /var/lib/pgsql/data/postgresql.conf

# Allow remote connections (DEV ONLY - tighten in prod)
echo "host all all 0.0.0.0/0 md5" >> /var/lib/pgsql/data/pg_hba.conf

# Restart PostgreSQL
systemctl restart postgresql

# Set password for postgres user (CHANGE THIS)
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'StrongPassword123';"