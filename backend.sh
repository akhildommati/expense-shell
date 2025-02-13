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

echo "Script started executing at : $TIMESTAMP" &>>$LOG_FILE

CHECK_ROOT

dnf module disable nodejs -y  &>>$LOG_FILE_NAME
VALIDATE $? "Disabling nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling nodejs"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing nodejs"

useradd expense &>>$LOG_FILE_NAME
VALIDATE $? "Adding user expense"

mkdir /app &>>$LOG_FILE_NAME
VALIDATE $? "Creating directory /app"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading backend code"

cd /app

unzip /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "Extracting backend code"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "Installing nodejs dependencies"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

#prepare mysql schema

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing mysql"

mysql -h mysql.manjulafoods.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "Creating mysql schema"

systemctl daemon-reload   &>>$LOG_FILE_NAME
VALIDATE $? "Reloading systemd"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabling backend"

systemctl start backend &>>$LOG_FILE_NAME
VALIDATE $? "Starting backend"