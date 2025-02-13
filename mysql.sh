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

dnf install mysql-server -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing mysql-server"

systemctl enable mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Enabling mysql-server"

systemctl start mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Starting mysql-server"
 
 mysql -h mysql.manjulafoods.online -u root -pExpenseApp@1 -e 'show databases;' &>>$LOG_FILE_NAME

 if [ $? -ne 0 ]
 then
 echo "Mysql Root password is not set" &>>$LOG_FILE_NAME
  mysql_secure_installation --set-root-pass ExpenseApp@1
  VALIDATE $? "Setting mysql root password"
  else
    echo -e "Mysql Root password is already set $Y SKIPPING $N" 
    fi

