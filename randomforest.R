library(randomForest)
library(dplyr)
library(DBI)
library(RSQLite)
#setwd("C:\\Users\\user\\Desktop\\Martin\\R\\lunch\\預測餐廳模型\\shiny")
#-------餐廳match list更新--------------------------------------------
restaurant_match<-as.character(readRDS("restaurant_match.rds")$Store)
restaurant_list<- readRDS("restaurant_list.rds")
new_restaurant<- readRDS("new_restaurant.rds")

today_y<- readRDS("today_answer")[1,1]

  restaurant_match<-restaurant_match[-length(restaurant_match)]
  restaurant_match<-c(restaurant_match,new_restaurant,"其他")
  #製作餐廳列表,list格式
  restaurant_list = list()
  for(i in 1:(length(restaurant_match)-1)){
    restaurant_list[[restaurant_match[i]]] = restaurant_match[i]
  }
  restaurant_list[['其他']]='enable'
  saveRDS(restaurant_list,"restaurant_list.rds")
  restaurant_match<-data.frame('number' = c(1:(length(restaurant_match))),'Store' = restaurant_match)
  saveRDS(restaurant_match,"restaurant_match.rds")

new_restaurant<-c()
saveRDS(new_restaurant,"new_restaurant.rds")


#-------today data存入資料庫--------------------------------------------
mydb <- dbConnect(RSQLite::SQLite(), "data")
today_data<-readRDS("today_answer")
data<- dbReadTable(mydb,'record')
data<-rbind(data,today_data)
data<-apply(data,2,as.character)
data<-as.data.frame(data,stringsAsFactors = F)
dbRemoveTable(mydb,"record")

dbWriteTable(mydb,'record',data,append = T,row.names =F)
dbDisconnect(mydb)

#--------------測試資料及訓練資料------------------------------------
#樣本推估母體，使用Bootstrap方法

mydb <- dbConnect(RSQLite::SQLite(), "data")
train<- dbReadTable(mydb,'record')[1:round(length(dbReadTable(mydb,'record')[,1])*0.8),] #跑raindomforest前y改為factor
test <- dbReadTable(mydb,'record')[(round(length(dbReadTable(mydb,'record')[,1])*0.8) + 1): length(dbReadTable(mydb,'record')[,1]),2:length(dbReadTable(mydb,'record'))]
y_result <-dbReadTable(mydb,'record')[(round(length(dbReadTable(mydb,'record')[,1])*0.8) + 1): length(dbReadTable(mydb,'record')[,1]),1]

#train<-sample_n(data[1:round(length(dbReadTable(mydb,'record')[,1])*0.8),],round(length(dbReadTable(mydb,'record')[,1])*0.8)*10,replace = T)#只有80%資料增加
#test<-dbReadTable(mydb,'record')[(round(length(dbReadTable(mydb,'record')[,1])*0.8) + 1): length(dbReadTable(mydb,'record')[,1]),2:24]
#y_result<-dbReadTable(mydb,'record')[(round(length(dbReadTable(mydb,'record')[,1])*0.8) + 1): length(dbReadTable(mydb,'record')[,1]),1]



#==================Part 2 訓練模型==================================
library(randomForest)
t = 0  
f = 0
e = 0
count_f = 0
k=c()
max_f= 0
seed_f = 0
while((count_f<=5)){
  #-----------模型資料建置----------- 
  mydb <- dbConnect(RSQLite::SQLite(), "data")
  train$y <- as.character(train$y)
  train_predict_result <-list()
  f = 0
  e = 0
  t = t+1
  seed<-t  
  set.seed(seed)
  for (x in 1:length(train[,1])){
    
    train_train<-train[-c(x),]
    train_test<-train[x,2:length(train)]
    train_y_result<-train[x,1]
    #train_train$y<-match(train_train$y,restaurant_match$Store)
    train_train$y<-as.factor(train_train$y)
    train_output<- randomForest(y~.,data = train_train) 
    train_result <- predict(train_output,train_test,type = 'prob')#顯示機率
    
    #-----------測試結果------------
    d =c()
    
    a = train_result[1,][train_result[1,]!=0]
    a = min_rank(a*(-1))
    for(j in c(1:3)){
      b = which(a == j)
      if(length(d)<=3){
        d = c(d,names(b))
      }
    }
    
    e = e +sum(train_y_result %in% d)
  }
  v = sum(e)/(length(train[,1]))
  print(seed)
  print(v)
  #-----------判斷train資料是否符合test
  if(v>0.15){
    predict_result<-list()
    a = c()
    b = c()
    
    set.seed(seed)
    train$y<-as.factor(train$y)
    output<-randomForest(y~.,data = train)
    result <- predict(output,test,type = 'prob')#顯示機率
    for(i in 1:length(test[,1])){
      d = c()
      a = result[i,][result[i,]!=0]
      a = min_rank(a*(-1))
      for(j in c(1:3)){
        b = which(a == j)
        if(length(d)<3){
          d = c(d,names(b))
        }
      }
      predict_result[i]<-list(d)
      print(seed)
    }
    
    # ----------比對-------------------
    
    for(i in 1:(length(test[,1]))){ #20抓train比數#
      f = sum(y_result[i] %in% predict_result[[i]]) + f 
    }
    k = sum(f)/(length(test[,1]))
    print(k)
    if(k>max_f){
      max_f = k  
      seed_f =seed
      count_f = 0
      print(seed_f)
    }else{
      count_f = count_f + 1
      print(paste("count_f",count_f))}
  }
}
set.seed(seed_f)
mydb <- dbConnect(RSQLite::SQLite(), "data")
data<-dbReadTable(mydb,'record')
data$y<-as.factor(data$y)
output<- randomForest(y~.,data = data)
dbDisconnect(mydb)
saveRDS(output,"randomforest.rds")
