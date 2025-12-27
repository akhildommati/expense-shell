#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +Y-%m-%d-%H-%M-%S )
LOG_FILE_NAME="$LOGS_FOLDER/"$LOG_FILE"-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
    echo -e "$2 ......$R FAILURE $N"
    exit 1
    else
    echo -e "$2 ......$G SUCCESS $N"
    fi  
}

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "ERROR : you must have sudo access to execute this script."
        exit 1
    fi  
}

echo "Script started executed at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disabling Nodejs Module"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling Nodejs 20 Module"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing Nodejs"

id expense &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then
    useradd expense &>>$LOG_FILE_NAME
    VALIDATE $? "Creating Expense User"
else
    echo -e "Expense User already......$Y exists $N"
fi

mkdir -p /app &>>$LOG_FILE_NAME
VALIDATE $? "Creating app Directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading Backend Zip File"

cd /app 
rm -rf /app/* &>>$LOG_FILE_NAME
VALIDATE $? "Cleaning up app Directory"

unzip /tmp/backend.zip -y &>>$LOG_FILE_NAME
VALIDATE $? "Unzipping Backend Files"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "Installing NPM Packages"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service &>>$LOG_FILE_NAME
VALIDATE $? "Copying Backend Service File"

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing Mysql Client"

mysql -h mysql.akhildommati.fun -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "Creating Expense Database and Tables"

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "Reloading Systemd Daemon"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabling Backend Service"

systemctl restart backend &>>$LOG_FILE_NAME
VALIDATE $? "restarting Backend Service"