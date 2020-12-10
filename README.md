# Kindle eBooks

## Getting started

Here's what you need to do to get all the servers started.

1. Edit `defaults` and `credentials` with your preferred configurations.

2. Please ensure that the predefined source files `kindle_metadata.json` and `kindle_reviews.csv` are present in the folders `mongodb_server/` and `mysql_server/` respectively.

3. Run `./setup.sh`. You can check `logs/` for the setup progress.

4. Once `./setup.sh` finishes running, you may start the analytics by running `./run_analytics.sh`.

5. You can shut down all servers by running `./teardown.sh`.

You might run into issues with `screen` during setup. If so, try the following.

```bash
./teardown.sh
sudo /etc/init.d/screen-cleanup start
./setup.sh
```

## Slides

You can see the slides for this project at this link: https://docs.google.com/presentation/d/1rwL_yJcdZnlBZjpljL5R7RQgMPV0eXpDRMn6fmgbjCY/edit?usp=sharing
