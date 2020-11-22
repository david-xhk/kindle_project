# kindle_project

## Starting up

Here's what you need to do to get all the servers started.

1. Start the following EC2 instances with access to the respective ports.

| Name              | SSH (22) | HTTP (80) | MySQL (3306) | MongoDB (27017) |
|-------------------|:--------:|:---------:|:------------:|:---------------:|
| Production server |     ✓    |     ✓     |              |                 |
| MySQL server      |     ✓    |           |       ✓      |                 |
| MongoDB server    |     ✓    |           |              |        ✓        |
| Flask server      |     ✓    |     ✓     |       ✓      |        ✓        |

2. Paste their respective IP addresses into the first 4 lines of the `config` file.

```bash
export production_server=____________;           # IP address of production server
export mysql_server=____________;                # IP address of MySQL server
export mongodb_server=____________;              # IP address of MongoDB server
export flask_server=____________;                # IP address of Flask server

...
```

3. Run `./start.sh`.

Once `start.sh` finishes executing, all the servers should be up and running.

## Configuration

The following environment variables need to be defined in `config`.

```bash
export production_server=;           # IP address of production server
export mysql_server=;                # IP address of MySQL server
export mongodb_server=;              # IP address of MongoDB server
export flask_server=;                # IP address of Flask server

export PROD_IP=$production_server;
export FLASK_IP=$flask_app;
export DEV_IP=;                      # IP address(es) of developer
export DEV_PASSWORD=;                # Password for developer

export MYSQL_HOST=$mysql_server;
export MYSQL_BIND_ADDR=;             # Bind address of MySQL server
export MYSQL_PORT=3306;
export MYSQL_DB=;                    # Name of MySQL database
export MYSQL_USER=;                  # Name of MySQL user
export MYSQL_USER_ADDR=$FLASK_IP;
export MYSQL_PASSWORD=;              # Password for MySQL user
export MYSQL_ROOT_PASS=;             # Password for MySQL root

export MONGO_HOST=$mongodb_server;
export MONGO_BIND_ADDR=;             # Bind address of MongoDB server
export MONGO_PORT=27017;
export MONGO_DB=;                    # Name of MongoDB database
export MONGO_USER=;                  # Name of MongoDB user
export MONGO_PASSWORD=;              # Password for MongoDB user
export MONGO_ROOT_PASS=;             # Password for MongoDB root

export CONFIG_DONE=1;
```
