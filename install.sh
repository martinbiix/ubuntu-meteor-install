#!/bin/sh

# This is the main script.  Run this one on a fresh ubuntu installation to get started!

confirm () {
  # call with a prompt string or use a default
  read -r -p "${1:-Are you sure? [y/N]} " response
  case $response in
    [yY][eE][sS]|[yY])
      true
      ;;
    *)
      false
      ;;
  esac
}

CWD=$(pwd)
echo ""
echo "----- METEOR + MONGODB + NGINX INSTALL SCRIPT -----"
echo ""
echo "This script will take your fresh new Ubuntu server and get it ready for a Meteor app deployment!"
echo "It will try to do all of the following, prompting you for any info it needs along the way:"
echo "  1. Install nginx and configure it for an SSL-enabled Meteor site. You provide the certificate and key files."
echo "  2. Install and configure a local MongoDB database, or configure the app for with your custom mongodb:// URL."
echo "  3. Install Node.js and your Meteor application bundle."
echo "  4. Configure Upstart to start and stop your new Meteor application service automatically."
echo "  5. Deploy your Meteor Application! Or if you're not ready to deploy, show you how to deploy in the future."
echo "  6. Provide you with scripts you can use to redeploy your app with future changes."
echo ""
echo "This script is based on instructions found online. If you're curious what it's doing, follow along at:" +
echo "  https://www.digitalocean.com/community/tutorials/how-to-deploy-a-meteor-js-application-on-ubuntu-14-04-with-nginx"
echo ""
echo "NOTE: For SSL Certificate configuration, the script will look for .pem and .key files with the"
echo "      same name as your application, and if found it will use those.  If not, you will be"
echo "      instructed on how to set up those files."
echo ""
echo "What is the name of your application (e.g. todos): "
read METEORAPPNAME
SITEAVAILABLEFILE="/etc/nginx/sites-available/$METEORAPPNAME"
UPSTARTFILE="/etc/init/$METEORAPPNAME.conf"
echo "What is the server name of your application (e.g. todos.net): "
read METEORSERVERNAME
echo ""
echo "*** Updating apt-get repositories..."
apt-get update
echo "*** Installing nginx web server..."
apt-get install nginx
echo "*** Creating SSL directory for nginx at /etc/nginx/ssl (chmod 0700)..."
mkdir /etc/nginx/ssl
chmod 0700 /etc/nginx/ssl
echo "*** Looking for your SSL certificate and key files..."
NOSSLPEM=0
NOSSLKEY=0
if test -f "./$METEORAPPNAME.pem"
then
  echo "$METEORAPPNAME.pem - SSL Certificate/CA Cert File Found!"
  cp -v $METEORAPPNAME.pem /etc/nginx/ssl/$METEORAPPNAME.pem
  chmod 0700 /etc/nginx/ssl/$METEORAPPNAME.pem
else
  NOSSLPEM=1
fi
if test -f "./$METEORAPPNAME.pem"
then
  echo "$METEORAPPNAME.key - SSL Certificate Key File Found!"
  cp -v $METEORAPPNAME.key /etc/nginx/ssl/$METEORAPPNAME.key
  chmod 0700 /etc/nginx/ssl/$METEORAPPNAME.key
else
  NOSSLKEY=1
fi

if [ $NOSSLPEM -eq 1 ] || [ $NOSSLKEY -eq 1 ]
then
  echo "NOTE: This script configures nginx for SSL, but does not provide the SSL certificate or key files."
  echo "      This configuration expects you to create the following two files:"
  echo "        - Your SSL certificate and CA certificate concatenated together at /etc/nginx/ssl/$METEORAPPNAME.pem"
  echo "        = Your SSL key at /etc/nginx/ssl/$METEORAPPNAME.key"
  echo "      Once those two files are in place, try to restart the app." #TODO??
  echo "      If you need help creating a certificate, see your CA or a guide like this for self-signed certs:"
  echo "      https://www.digitalocean.com/community/tutorials/how-to-create-a-ssl-certificate-on-nginx-for-ubuntu-12-04"
  echo ""
  echo "The rest of this script assumes you have created the above two SSL files in /etc/nginx/ssl yourself."
  confirm "Do you want to continue now? [y/N]" || exit 1
fi

echo ""
echo "*** Preparing nginx site configuration file at $SITEAVAILABLEFILE for app named '$METEORAPPNAME'..."
cp -v ./nginx-site-conf $SITEAVAILABLEFILE
sed -i "s/todos.net/$METEORSERVERNAME/g" $SITEAVAILABLEFILE
sed -i "s/todos/$METEORAPPNAME/g" $SITEAVAILABLEFILE
echo "*** Disabling the default nginx virtual host..."
rm -v /etc/nginx/sites-enabled/default
echo "*** Enabling our new nginx virtual host..."
ln -v -s $SITEAVAILABLEFILE /etc/nginx/sites-enabled/$METEORAPPNAME

testnginx () {
  echo "*** Testing nginx configuration and reloading nginx..."
  nginx -t
  nginx -s reload
  echo ""
  echo "Okay!  At this point nginx should be working and you should have gotten a 'test is successful' message."
  echo "If not, and there was some problem with the nginx test, it's probably because something is wrong with your SSL files."
  echo ""
  echo "Fun fact: If this nginx test was successful, you should now be able to see a 502 Bad Gateway error at $METEORSERVERNAME!" +
  echo "          That's a good thing, we haven't yet installed the Meteor server that will sit behind this gateway."
  echo ""
  confirm "The rest of this script assumes nginx is configured properly and tests successfully. Are you ready to continue now? [y/N]" || testnginx
}
testnginx

echo ""
MONGOURL="mongodb://localhost:27017/$METEORAPPNAME"
LOCALMONGO=1
getmongourl () {
  LOCALMONGO=0
  echo "Hosting your own MongoDB database? What is the mongodb:// URL?"
  read MONGOURL
}
confirm "Are you ok with using a local MongoDB database on this machine? [y/N]" || getmongourl
if [ $LOCALMONGO -eq 1 ]
then
  echo "*** Setting up a Local MongoDB Database..."
  apt-get install mongodb-server
  netstat -ln | grep -E '27017|28017'
  echo "*** Configuring cron for automatic nightly mongodb backups in /var/backups/mongodb/ ..."
  echo "@daily root mkdir -p /var/backups/mongodb; mongodump --db $METEORAPPNAME --out /var/backups/mongodb/$(date +'\%Y-\%m-\%d')" > /etc/cron.d/mongodb-backup
fi

echo ""
echo "*** Adding the PPA for newer versions of Node.js (you may be prompted to confirm)..."
add-apt-repository ppa:chris-lea/node.js
echo "*** Installing Node.js..."
apt-get update
apt-get install nodejs

echo ""
echo "*** Creating a new system user '$METEORAPPNAME' to run the app under. You'll be prompted for details, just leave them all at default."
adduser --disabled-login $METEORAPPNAME

echo ""
echo "*** Configuring Upstart for the new '$METEORAPPNAME' service."
cp -v ./upstart-conf $UPSTARTFILE
sed -i "s/todos/$METEORAPPNAME/g" $UPSTARTFILE
sed -i "s/mongourlreplaceme/$MONGOURL/g" $UPSTARTFILE
echo ""
echo "NOTE: If you need to use any custom meteor --settings, or an SMTP mail URL for sending email, this script doesn't support that."
echo "      You can modify the Upstart service configuration at $UPSTARTFILE if you need stuff like this."
echo ""
echo "NOTE: Any output from the Upstart meteor service trying to start can be found in /home/$METEORAPPNAME/$METEORAPPNAME.log."
echo "      This script does not set up any log rotation, so keep an eye on this file. If your app runs without errors, it shouldn't grow."
echo ""

echo "*** Installing g++ and make so we can build any npm dependencies your app may have..."
apt-get install g++ make
echo ""

echo "*** Deploying your Meteor application bundle..."
DEPLOYING=0
checkforbundle () {
  echo "*** Checking for bundle file..."
  if test -f "./$METEORAPPNAME.tar.gz"
  then
    DEPLOYING=1
    echo "Bundle found at $METEORAPPNAME.tar.gz!"
  else
    DEPLOYING=0
    echo "No application bundle file was found at $METEORAPPNAME.tar.gz."
    echo "Do you want to continue without deploying the application? You'll be shown how to do so in the future either way."
    echo "If you do want to deploy the application now, create a meteor app bundle in the same directory as this script:"
    echo "  - On your development machine, cd to the application directory."
    echo "  - Execute 'meteor bundle $METEORAPPNAME.tar.gz'."
    echo "  - Copy the $METEORAPPNAME.tar.gz file to this server using scp and place it in this directory."
    echo ""
    confirm "Continue without deploying? [y/N] (If you want to check again for a bundle file, type N)" || checkforbundle
  fi
}
checkforbundle

echo ""
if [ $DEPLOYING -eq 1 ]
then
  source ./deploy-bundle.sh
fi

echo "--- FUTURE DEPLOYMENTS ---"
echo "If you want to deploy your app again in the future from a new bundle file, you can easily do so."
echo "Just upload the new bundle file to the same directory as this script, then run ./deploy-bundle.sh."
