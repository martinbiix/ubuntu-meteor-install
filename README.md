# ubuntu-meteor-install
A quick-and-dirty simple script that will set up nginx, mongodb and upstart, and deploy your Meteor app bundle for you.

I couldn't find a good one, so I made one.  This is 100% based on the instructions found online at:
https://www.digitalocean.com/community/tutorials/how-to-deploy-a-meteor-js-application-on-ubuntu-14-04-with-nginx

To get started, simply clone this repo onto a server with a fresh installation of Ubuntu, then run the `install.sh` script.
The script will prompt you for anything it needs, and if you want to have an easier time, you can prepare the
following three files ahead of time:

  * yourapp.tar.gz - This is a Meteor application bundle, created with the `meteor bundle` command, that you want to deploy.
  * yourapp.pem - This is your SSL Certificate file, concatenated with your CA Certificate.
  * yourapp.key - This is your SSL Certificate key.

If you place these files in the ubuntu-meteor-install directory before running `install.sh`,
it will automagically configure SSL for you and deploy your app bundle!  If you don't, it'll ask you to go get them.
