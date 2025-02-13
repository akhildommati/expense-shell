#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%d-%m-%Y-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
then
echo -e "$2...... $R FAILURE $N"
exit 1
else 
echo  -e "$2...... $G SUCCESS  $N"
fi
}

CHECK_ROOT(){
if [ $USERID -ne 0 ]
then
echo "ERROR ::You need to have root privileges to run this script"
exit 1 # other than zero
fi
}

mkdir -p $LOGS_FOLDER

echo "Script started executing at : $TIMESTAMP" &>>$LOG_FILE

CHECK_ROOT

dnf install nginx -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing nginx"

systemctl enable nginx &>>$LOG_FILE_NAME
VALIDATE $? "Enabling nginx"

systemctl start nginx &>>$LOG_FILE_NAME
VALIDATE $? "Starting nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE_NAME
VALIDATE $? "Removing default nginx content"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading frontend code"

cd /usr/share/nginx/html &>>$LOG_FILE_NAME
VALIDATE $? "Changing directory to nginx html"

unzip /tmp/frontend.zip &>>$LOG_FILE_NAME
VALIDATE $? "Extracting frontend code"

systemctl restart nginx &>>$LOG_FILE_NAME
VALIDATE $? "Restarting nginx"

