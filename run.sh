
date >>/Users/brandon/Desktop/cronlog.txt

git pull origin master

./build.sh
.build/debug/transport-canary

# Running this twice because we don't always connect to openvpn successfully
#.build/debug/transport-canary

#Send any reports to our server.
#Note: if you do not have the proper keys you will not be able to do this.
rsync -r /Library/OperatorReports/ root@198.211.106.85:Reports/
