Installing Kong Gateway on Amazon Linux 2 with Terraform
===========================================================

This example stands up a simple Amazon Linux 2 instance, then provides a procedure to manually install postgres and Kong Gateway Enterprise

## Prerequisites
1. AWS Credentials (Access Key ID and Secret Access Key)
2. AWS Key Pair for SSH
3. Terraform CLI

## Procedure

1. Via the CLI, login to AWS using `aws configure`.
2. Open `tf/main.tf` and update the key_name to match your AWS keypair (SSH)
3. In the same file, update the Tags/Name to something unique that identifies you.
4. Via the CLI, run the following Terraform commands to standup Amazon Linux 2:

```bash
terraform init
terraform apply
```

5. Once terraform has stoodup the instance, SSH via the shell using the `public_ip` output:

```bash
ssh -i /path/to/<SSH keypair>.pem ec2-user@<public_ip>
```

6. Via the ec2 shell, execute the following to install postgres (instructions taken from [here](https://techviewleo.com/install-postgresql-12-on-amazon-linux/):

```bash
sudo yum -y update
sudo tee /etc/yum.repos.d/pgdg.repo<<EOF
[pgdg12]
name=PostgreSQL 12 for RHEL/CentOS 7 - x86_64
baseurl=https://download.postgresql.org/pub/repos/yum/12/redhat/rhel-7-x86_64
enabled=1
gpgcheck=0
EOF
sudo yum makecache
sudo yum install postgresql12 postgresql12-server
sudo /usr/pgsql-12/bin/postgresql-12-setup initdb
sudo systemctl enable --now postgresql-12
sudo su - postgres
psql -c "alter user postgres with password 'kong'"
exit
```

7. Update postgres to accept local MD5 connections, by update the `/var/lib/pgsql/12/data/pg_hba.conf` file:

```
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
```

8. Restart postgres to apply the changes (instructions are taken from [here](https://konghq.com/blog/kong-gateway-tutorial/)):

```bash
sudo su - postgres
/usr/pgsql-12/bin/pg_ctl reload
```

9. As per the standard Kong gateway installation [instructions](https://docs.konghq.com/gateway/2.7.x/install-and-run/amazon-linux/), create a kong username and password in postgres:

```bash
sudo su - postgres
psql -c "CREATE USER kong;"
psql -c "CREATE DATABASE kong OWNER kong;"
psql -c "ALTER USER kong WITH PASSWORD 'kong';"
exit
```

10. Via the regular shell, install Kong:

```bash
curl -Lo kong-enterprise-edition-2.7.0.0.amzn2.noarch.rpm "https://download.konghq.com/gateway-2.x-amazonlinux-2/Packages/k/kong-enterprise-edition-2.7.0.0.amzn2.noarch.rpm"
sudo yum install kong-enterprise-edition-2.7.0.0.amzn2.noarch.rpm
```

11.  scp over the `kong/kong.conf` file to EC2 and update the `admin_gui_url` value to match your `public_ip`:

```
admin_gui_url =http://public_ip:8002       # Kong Manager URL
```

12.  As per the Kong gateway instructions, setup the Kong database and start the gateway:

```bash
scp -i /path/to/<SSH keypair>.pem kong/kong.conf ec2-user@<public_ip>:~/kong.conf
sudo mv kong.conf /etc/kong/
export KONG_PASSWORD="kong"
sudo /usr/local/bin/kong migrations bootstrap -c /etc/kong/kong.conf
sudo /usr/local/bin/kong start -c /etc/kong/kong.conf
```

13. Test the admin API locally on ec2 using `curl`:

```bash
curl -i -X GET --url http://localhost:8001/services
```

14. Test the Management GUI via the browser: `http://<public_ip>:8002/overview`

15. Via the CLI, apply your Enterprise license:

```bash
curl -i -X POST http://<hostname>:8001/licenses \
  -d payload='{"license":{"payload":{"admin_seats":"1","customer":"Example Company, Inc","dataplanes":"1","license_creation_date":"2017-07-20","license_expiration_date":"2017-07-20","license_key":"00141000017ODj3AAG_a1V41000004wT0OEAU","product_subscription":"Konnect Enterprise","support_plan":"None"},"signature":"6985968131533a967fcc721244a979948b1066967f1e9cd65dbd8eeabe060fc32d894a2945f5e4a03c1cd2198c74e058ac63d28b045c2f1fcec95877bd790e1b","version":"1"}}'
```

16. Enable the DevPortal by updating `portal_gui_host` in `/etc/kong/kong.conf`:

```bash
portal = on
portal_gui_listen = 0.0.0.0:8003, 0.0.0.0:8446 ssl
portal_gui_host = 54.191.237.30:8003
```

17. Restart kong:

```bash
sudo /usr/local/bin/kong restart -c /etc/kong/kong.conf
```

The following links were useful during this installation:

- [Install postgres on Amazon Linux](https://techviewleo.com/install-postgresql-12-on-amazon-linux/)
- [Install Kong on Amazon Linux](https://docs.konghq.com/gateway/2.7.x/install-and-run/amazon-linux/)
- [Using EC2 Terraform module](https://aws.plainenglish.io/aws-ec2-terraform-module-utilizing-the-aws-ami-data-source-50d762b68ab)
- [Blog post for installing Kong Gateway on Amazon](https://konghq.com/blog/kong-gateway-tutorial/)