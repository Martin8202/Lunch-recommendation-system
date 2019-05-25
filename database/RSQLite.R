#-----------------資料庫儲存------------------------------------------
library(shiny)
library(DBI)
library(RSQLite)
library(readxl)
library(dplyr)
#資料庫建立
#data<-read.csv("D:\\Documents\\Martin\\Martin\\R\\lunch\\預測餐廳模型\\ori_data\\new\\week_and_restaurant.csv")


climate<- read.csv("D:\\Documents\\Martin\\Martin\\R\\lunch\\預測餐廳模型\\ori_data\\climate.csv")
week<- as.character(as.character(climate[,1]))

time_period<-as.character(rep(1,length(climate[,1])))
data<-data.frame('time_period'=time_period,'week'=week,climate[,2:4],stringsAsFactors = F)

setwd("D:\\Documents\\Martin\\Martin\\R\\lunch\\預測餐廳模型\\shiny") #設定位置
mydb <- dbConnect(RSQLite::SQLite(), "data")


dbRemoveTable(mydb,"record")
dbWriteTable(mydb,'record',data) #沒有結果y
dbDisconnect(mydb)
