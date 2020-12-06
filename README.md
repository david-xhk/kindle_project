# kindle_project

## Getting started

Here's what you need to do to get all the servers started.

1. Edit `defaults` and `credentials` with your preferred configurations.

2. Run `./setup.sh`. You can check `logs/` for the setup progress.

3. Once `./setup.sh` finishes running, you may start the analytics by running `./run_analytics`.

4.
```bash
export DEV_ADDRESS=;          # IP address(es) of developer
export DEV_PASSWORD=;         # Password for developer
export DEV_KEY_FILE=;         # Name of developer key file

export MYSQL_DB=;             # Name of MySQL database
export MYSQL_TABLE=;          # Name of MySQL database table
export MYSQL_SOURCE=;         # Name of MySQL source file
export MYSQL_USER=;           # Name of MySQL user
export MYSQL_PASSWORD=;       # Password for MySQL user
export MYSQL_ROOT_PASSWORD=;  # Password for MySQL root

export MONGO_DB=;             # Name of MongoDB database
export MONGO_COLLECTION=;     # Name of MongoDB database collection
export MONGO_SOURCE=;         # Name of MongoDB source file
export MONGO_USER=;           # Name of MongoDB user
export MONGO_PASSWORD=;       # Password for MongoDB user
export MONGO_ROOT_PASSWORD=;  # Password for MongoDB root
```

3. Move your predefined source files into `./production_server/root`.

4. Move your predefined key file into the project root directory.

5. Start the following EC2 instances configured with public access to the respective ports and SSH access using your predefined key file.

| Name              | HTTP (80) | MySQL (3306) | MongoDB (27017) | SSH (22) |
|-------------------|:---------:|:------------:|:---------------:|:--------:|
| Production server |     ✓     |              |                 |     ✓    |
| MySQL server      |           |       ✓      |                 |     ✓    |
| MongoDB server    |           |              |        ✓        |     ✓    |
| Flask server      |     ✓     |       ✓      |        ✓        |     ✓    |

6. Paste their respective IP addresses into the following lines in `config`.

```bash
export production_server=;    # IP address of production server
export mysql_server=;         # IP address of MySQL server
export mongodb_server=;       # IP address of MongoDB server
export flask_server=;         # IP address of Flask server
```

7. Run `./start.sh`.

Once `start.sh` finishes executing, all the servers should be up and running.
