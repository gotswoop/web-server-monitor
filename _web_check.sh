#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

#
# This script checks the disk usage on the server and also 
# checks if specific processes are inactive. If they are not active,
# they are restarted and a notification is sent to the email in the /root/.forward file
# For Apache, it also checks if it can load https://<this_website>/ping. 
# So please make sure a /ping page is setup
# You can setup additional processes checks below. Look for "Step XX"
# 
# Swaroop Samek 2016
#

# Setting web page to check. for e.g. https://swaroop.com/ping/
webpage_to_check="https://$HOSTNAME/ping/"

# Setting the threshold (%) for disk usage check
disk_usage_limit=80

# Fetch hostname of this server
host=$(echo $(hostname) | awk '{print toupper($0)}')

# Fetch date
dt=$(date '+%Y-%m-%d %H:%M:%S');

# Fetch load average
load_avg=`uptime | awk -F'[a-z]:' '{ print $2}'`

# Fetch From addresss
from='From: root@'$(echo $(hostname))

# Fetch To address
if [ -f /root/.forward ]; then
    to=$(cat /root/.forward | xargs)
fi
[ -z "$to" ] && to="email@example.com"

# Step 0 - Checking disk storage and notifying if above disk_usage_limit
df -H | grep -vE '^Filesystem|udev|tmpfs|cdrom' | awk '{ print $2 " " $5 " " $1 }' | while read output;
do
  spaceUsed=$(echo $output | awk '{ print $2}' | cut -d'%' -f1  )
  spaceTotal=$(echo $output | awk '{ print $1}')
  partition=$(echo $output | awk '{ print $3 }' )
  if [ $spaceUsed -ge $disk_usage_limit ]; then
    msg="$dt: $host:$partition at $spaceUsed% of $spaceTotal capacity"
    echo $msg | mail -a "$from" -s "[CRITICAL]: $host:$partition at $spaceUsed% of $spaceTotal capacity (Low Disk Space)" $to
    echo $msg
  fi
done

# Checking if MySQL is installed
package_installed=`type mysqld >/dev/null 2>&1 && echo 1 || echo 0`
if [ $package_installed -eq 1 ]
then
	# Step 1 - Checking MySQL process
	res=`/bin/systemctl status mysql.service | grep 'Active: ' | awk {'print $2 " " $3'}`
	if [ "$res" != "active (running)" ]
	then
		# Restarting MySQL
		/bin/systemctl stop mysql.service
		/bin/systemctl start mysql.service
		msg="$dt: MySQL process on $host was down '$res' and was automatically restarted. Load average: $load_avg"
		echo $msg | mail -a "$from" -s "MySQL restarted on $host" $to
		echo $msg
	fi
fi

# Checking if Apache 2 is installed
package_installed=`type apache2 >/dev/null 2>&1 && echo 1 || echo 0`
if [ "$package_installed" -eq 1 ]
then

	# Step 2 - Checking Apache process
	res=`/bin/systemctl status apache2.service | grep 'Active: ' | awk {'print $2 " " $3'}`
	if [ "$res" != "active (running)" ]
	then
		# Restarting Apache2
		/bin/systemctl stop apache2.service
		/usr/bin/killall -q apache2
		/bin/systemctl start apache2.service
		msg="$dt: Apache process on $host was down '$res' and was automatically restarted. Load average: $load_avg"
		echo $msg | mail -a "$from" -s "Apache restarted on $host" $to
		echo $msg
	fi

	# Step 3 - Checking web page loading
	res=`curl -s -I $webpage_to_check | grep HTTP/1.1 | awk {'print $2'}`
	if [ "$res" != "200" ]
	then
		# Restarting Apache2
		/bin/systemctl stop apache2.service
		/usr/bin/killall -q apache2
		/bin/systemctl start apache2.service
		msg="$dt: Unable to load $webpage_to_check. Apache process on $host was automatically restarted. Load average: $load_avg"
		echo $msg | mail -a "$from" -s "Apache restarted on $host" $to
		echo $msg
	fi
fi

# Checking if Shibboleth is installed
package_installed=`type shibd >/dev/null 2>&1 && echo 1 || echo 0`
if [ $package_installed -eq 1 ]
then
	# Step 4 - Checking Shibd process
	res=`/bin/systemctl status shibd.service | grep 'Active: ' | awk {'print $2 " " $3'}`
	if [ "$res" != "active (running)" ]
	then
		# Restarting 
		/bin/systemctl stop shibd.service
		/bin/systemctl start shibd.service
		msg="$dt: Shibd process on $host was down '$res' and was automatically restarted. Load average: $load_avg"
		echo $msg | mail -a "$from" -s "Shibd restarted on $host" $to
		echo $msg
	fi
fi
