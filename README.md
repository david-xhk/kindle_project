# kindle_project

## Getting started

Here's what you need to do to get all the servers started.

1. Make a copy of `config_template` and name it `config`.

2. Define the following environment variables in `config`.

```bash
export DEV_ADDRESS=;          # IP address(es) of developer
export DEV_PASSWORD=;         # Password for developer
export DEV_KEY_FILE=;         # Name of developer key file

export FLASK_SOURCE=;         # Name of Flask source file

export MYSQL_BIND_ADDRESS=;   # Bind address of MySQL server
export MYSQL_DB=;             # Name of MySQL database
export MYSQL_TABLE=;          # Name of MySQL database table
export MYSQL_SOURCE=;         # Name of MySQL source file
export MYSQL_USER=;           # Name of MySQL user
export MYSQL_PASSWORD=;       # Password for MySQL user
export MYSQL_ROOT_PASSWORD=;  # Password for MySQL root

export MONGO_BIND_ADDRESS=;   # Bind address of MongoDB server
export MONGO_DB=;             # Name of MongoDB database
export MONGO_COLLECTION=;     # Name of MongoDB database collection
export MONGO_SOURCE=;         # Name of MongoDB source file
export MONGO_USER=;           # Name of MongoDB user
export MONGO_PASSWORD=;       # Password for MongoDB user
export MONGO_ROOT_PASSWORD=;  # Password for MongoDB root
```

3. Start the following EC2 instances configured with public access to the respective ports and SSH access using your predefined key file.

| Name              | HTTP (80) | MySQL (3306) | MongoDB (27017) | SSH (22) |
|-------------------|:---------:|:------------:|:---------------:|:--------:|
| Production server |     ✓     |              |                 |     ✓    |
| MySQL server      |           |       ✓      |                 |     ✓    |
| MongoDB server    |           |              |        ✓        |     ✓    |
| Flask server      |     ✓     |       ✓      |        ✓        |     ✓    |

4. Paste their respective IP addresses into the following lines in `config`.

```bash
export production_server=;    # IP address of production server
export mysql_server=;         # IP address of MySQL server
export mongodb_server=;       # IP address of MongoDB server
export flask_server=;         # IP address of Flask server

...
```

6. Run `./start.sh`.

Once `start.sh` finishes executing, all the servers should be up and running.
