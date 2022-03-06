s3_bucket="upgrad-nimesh"
myname="Nimesh"
timestamp=$(date '+%d%m%Y-%H%M%S')

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
echo "End of automation.sh script"
