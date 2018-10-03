#!/bin/bash

trap "exit;" SIGINT SIGTERM

# relocate to script root
pushd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" > /dev/null

mkdir -p work/conf/extract
mkdir -p work/conf/import

# get variable presets
if [[ -f variables.sh ]]; then
	source variables.sh
fi

# gather user input
if [[ $SF_SRC_SANDBOX = '' ]]; then
	echo "Enter the source sandbox name:"
	read -p "Source Sandbox: " SF_SRC_SANDBOX
	echo ""
else
	echo Source Sandbox: $SF_SRC_SANDBOX
fi

if [[ $SF_DEST_SANDBOX = '' ]]; then
	echo "Enter the destination sandbox name:"
	read -p "Dest Sandbox: " SF_DEST_SANDBOX
	echo ""
else
	echo Destination Sandbox: $SF_DEST_SANDBOX
fi

if [[ $SF_SRC_USER = '' ]]; then
	echo "Enter your salesforce username for" $SF_SRC_SANDBOX "(without sandbox postfix):"
	read -p "Username: " SF_SRC_USER
	echo ""
else
	echo Source Username: $SF_SRC_USER
fi

if [[ $SF_DEST_USER = '' ]]; then
	echo "Enter your salesforce username for" $SF_DEST_SANDBOX "(or press enter if the same):"
	read -p "Username: " SF_DEST_USER
	echo ""
else
	echo Dest Username: $SF_DEST_USER
fi

if [[ $SF_SRC_PASS = '' ]]; then
	echo "Enter your salesforce password for" $SF_SRC_SANDBOX":"
	read -s -p "Password: " SF_SRC_PASS
	echo ""
	echo ""
else
	echo "Source Password: (hidden)"
fi

if [[ $SF_DEST_PASS = '' ]]; then
	echo "Enter your salesforce password for" $SF_DEST_SANDBOX "(or press enter if the same):"
	read -s -p "Password: " SF_DEST_PASS
	echo ""
	echo ""
else
	echo "Dest Password: (hidden)"
fi

if [[ $SF_DEST_USER = '' ]]; then
	SF_DEST_USER=$SF_SRC_USER
fi

# generate encryption key
EPOCH=`date +%s`
java -cp ./lib/dataloader-38.0.1-uber.jar com.salesforce.dataloader.security.EncryptionUtil -g $EPOCH | awk '{print $9}' > work/key.txt

# encrypt passwords
SF_SRC_PASS_ENC=`java -cp ./lib/dataloader-38.0.1-uber.jar com.salesforce.dataloader.security.EncryptionUtil -e $SF_SRC_PASS ./work/key.txt | awk '{print $9}'`
if [[ $SF_DEST_PASS != '' ]]; then
	SF_DEST_PASS_ENC=`java -cp ./lib/dataloader-38.0.1-uber.jar com.salesforce.dataloader.security.EncryptionUtil -e $SF_DEST_PASS ./work/key.txt | awk '{print $9}'`
else
	SF_DEST_PASS_ENC=$SF_SRC_PASS_ENC
fi

SF_SRC_ENV=https://test.salesforce.com
SF_SRC_USERNAME=$SF_SRC_USER.$SF_SRC_SANDBOX
if [[ $SF_SRC_SANDBOX = '' ]]; then
	SF_SRC_USERNAME=$SF_SRC_USER
	SF_SRC_ENV=https://login.salesforce.com
fi

# generate configs
awk '{
	if(/^sfdc.endpoint=/)
		print "sfdc.endpoint="endpoint;
	else if(/^sfdc\.username=/) 
		print "sfdc.username="username;
	else if(/^sfdc\.password=/) 
		print "sfdc.password="password;
	else 
		print $0;
}' endpoint=$SF_SRC_ENV username=$SF_SRC_USERNAME password=$SF_SRC_PASS_ENC conf/config.properties.template > work/conf/extract/config.properties

SF_DEST_ENV=https://test.salesforce.com
SF_DEST_USERNAME=$SF_DEST_USER.$SF_DEST_SANDBOX
if [[ $SF_DEST_SANDBOX = '' ]]; then
	SF_DEST_USERNAME=$SF_DEST_USER
	SF_DEST_ENV=https://login.salesforce.com
fi

awk '{
	if(/^sfdc.endpoint=/)
		print "sfdc.endpoint="endpoint;
	else if(/^sfdc\.username=/) 
		print "sfdc.username="username;
	else if(/^sfdc\.password=/) 
		print "sfdc.password="password;
	else 
		print $0;
}' endpoint=$SF_DEST_ENV username=$SF_DEST_USERNAME password=$SF_DEST_PASS_ENC conf/config.properties.template > work/conf/import/config.properties

# copy log4j config
cp conf/log-conf.xml work/log-conf.xml