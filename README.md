# Web Server Health Checker

## A bash script that

1. Monitors the disk space and triggers an email when disk utilization is above 80%.
1. Checks the status of Apache, MySQL, PHP and Shibboleth, and if inactive or dead, records the system load, restarts the inactive/dead service and triggers an email. Can also be configured to check other services such as Nginx, php-fpm etc.
1. Runs as a cron every minute (as root)

*Tested on Ubuntu and Debian.*

## Requirements:

1. Setup a /ping page on your webserver so there is a page on without any 301 or 302 redirects. For e.g. https://swaroop.com/ping, where /ping could be a blank /ping/index.php or /ping/index.html page.
1. Install Sendmail or Postfix to send notification generated during exceptions.

## Setup instuctions
1. Create a /root/.forward file with your email 
1. Copy _web_check.sh to /root/_CRONS
1. Create a directory /root/cron_logs to store log files for cron output
1. Create the following cron entry for root

```
## Checking how the web server is doing every 1 mins
* * * * * /root/_CRONS/_web_check.sh >> /root/cron_logs/out_web_check_$(date +\%Y.\%m.\%d).log
```

1. Create the following cron entry for root to clear out old log files

```
## Cron to clear out log files older than 60 days. Runs on 1st of the month at 1:00 am
0 1 1 * * /usr/bin/find /root/cron_logs/ -type f -mtime +60 -name '*.log' -execdir rm -- '{}' \;
```
