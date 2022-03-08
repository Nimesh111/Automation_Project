s3_bucket="upgrad-nimesh"
myname="Nimesh"
timestamp=$(date '+%d%m%Y-%H%M%S')

echo "Start of Automation.sh File"
echo "==========================="

echo "=>  Upadting packages.."
sudo apt update -y
echo "Package update successfull."

echo "=> Checking if apache2 is installed"
check_package=$(dpkg-query -l | grep -c apache)
if [ "$check_package" ==  0 ]
then
	echo "Apache2 is not installed. Installing.."
	sudo apt install apache2
else
	echo "Apache2 is already installed."
fi

echo "=> Checking is apache2 service is active.."
apache2_start_script=$(systemctl show -p ActiveState --value apache2)
if [ "$apache2_start_script" == "active" ]
then
	echo "Apache2 service is already active."
else
	echo "Apache2 is inactive. Starting apache2.."
	sudo systemctl start apache2
	echo "Apache2 started."
fi

echo "=> Creating apache2 logs tar file.."
find /var/log/apache2/ -name "*.log" | sudo tar -cvf /tmp/${myname}-httpd-logs-${timestamp}.tar /var/log/apache2 -T -
echo "Logs with tar file created at /tmp/"

echo "=> Checking if awscli is installed.."
check_awscli=$(dpkg-query -l | grep -c awscli)
if [ "$check_awscli" ==  0 ]
then
	echo "AWS CLI is not installed. Installing.."
	sudo apt install awscli
else
	echo "AWS CLI is already installed."
fi

echo "=> Uploading tar file to s3 bucket.."
aws s3 cp /tmp/${myname}-httpd-logs-${timestamp}.tar s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar
echo "Upload successfull."

echo "=> Checking if inventory.html file exit at location /var/www/html/.."
file=/var/www/html/inventory.html
file_size=$(ls -lh | awk '{print $5}')
if [ -e "$file" ]
then
	echo "File exists."
	echo "Appending data.."
	echo "httpd-logs	$timestamp	tar	$file_size" >> /var/www/html/inventory.html
else 
	echo "File does not exist."
	echo "Creating invrntory.html file.."
	( echo '<html> <head><title>Logs</title></head><body><Table><tr><td><u>Logs Type</u>&emsp;</td> <td><u>Date Created</u>&emsp;</td> <td><u>Type</u>&emsp;</td> <td><u>Size</u>&emsp;</td> </tr> </Table></body></html>') > /var/www/html/inventory.html
	echo "File created successfully"
fi 

echo "=> Checking if CRON Job is scheduled.."
cron_job_file=/etc/cron.d/automation
if [ -e "$cron_job_file" ]
then
	echo "Cron Job is scheduled."
else
	echo "Cron Job is not scheduled."
	echo "Scheduling Cron Job.."
	echo "5 12 * * * root /root/Automation_Project/automation.sh" > /etc/cron.d/automation
	echo "Cron Job Scheduled successfully."
fi

echo "============================"
echo "End of automation.sh script"
