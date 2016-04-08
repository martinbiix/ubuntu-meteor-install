#!/bin/sh

# This script just unpacks and deploys your new app bundle file for you.
# It expects that you have already run the ubuntu-meteor-install.sh script once on this server.

CWD=$(pwd)
if [ -z ${METEORAPPNAME+x} ]
then
  echo "What is the name of your application (e.g. todos): "
  read METEORAPPNAME
  SITEAVAILABLEFILE="/etc/nginx/sites-available/$METEORAPPNAME"
  UPSTARTFILE="/etc/init/$METEORAPPNAME.conf"
fi
if [ -z ${METEORSERVERNAME+x} ]
then
  echo "What is the server name of your application (e.g. todos.net): "
  read METEORSERVERNAME
fi
echo ""
echo "*** Stopping your current application if it exists..."
stop $METEORAPPNAME
echo ""
echo "*** Unpacking your application bundle to /hdome/$METEORAPPNAME/bundle..."
cp -v ./$METEORAPPNAME.tar.gz /home/$METEORAPPNAME
cd /home/$METEORAPPNAME
tar -zxf $METEORAPPNAME.tar.gz
echo ""
echo "*** Installing your application's npm dependencies..."
cd /home/$METEORAPPNAME/bundle/programs/server
npm install
chown $METEORAPPNAME:$METEORAPPNAME /home/$METEORAPPNAME -R
echo ""
echo "*** OK, everything else is done, let's try and start the application... ***"
echo ""
start $METEORAPPNAME
echo ""
echo "*** Checking that all deployed services are running..."
status $METEORAPPNAME
service nginx status
status mongodb
echo ""
echo "----------------------------------------------------------------------------------------------"
echo "If everything worked, your app should now be serving requests at https://$METEORSERVERNAME!"
echo "----------------------------------------------------------------------------------------------"
echo ""
echo "Deployment Troubleshooting:"
echo "  - Check /home/$METEORAPPNAME/$METEORAPPNAME.log if your application starts and dies; it should throw an appropriate error message."
echo "  - Check /var/log/nginx/error.log if you see an HTTP error instead of your application."
echo "  - Check /var/log/mongodb/mongodb.log if you think there might a problem with the database."
echo ""
cd $CWD
