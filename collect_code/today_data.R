#==================Part 3 預測結果==================================
library(xml2)
library(rvest)
library(httr)
library(rjson)
library(DBI)
library(RSQLite)

#-------------------today_result 空list----------------------------
today_result<-list()
saveRDS(today_result,"today_result.rds")

today_answer<-c()
saveRDS(today_answer,"today_answer")
#--------------------爬天氣-------------------
url = "http://www.cwb.gov.tw/V7/forecast/town368/GT/6300600.htm?_=1512632991830"


  a <- try(read_html(url,encoding = "UTF-8") %>%
    html_nodes('td:nth-child(4) , td:nth-child(5) , td:nth-child(2)') %>%
    html_text()%>%
    unlist()%>%
    strsplit(" "))
  
  if(class(a)=='try-error'){
    temperature<-0
    humidity<-0
    rainfall<-0
    print(paste("MY_WARNING:  ",war))
  }else{
    #------------------天氣清整------------------
    if(a[1]!= "NA"){
      temperature<-gsub("℃","",a[1])
      
      if(as.numeric(temperature)<19.7){
        temperature<-1#要轉factor?
      }else if(as.numeric(temperature)>28.9){
        temperature<-3
      }else{
        temperature<-2
      }
    }else{
      temperature<-0
    }
    
    if(a[2]!="NA"){
      humidity<-gsub("%","",a[2])
      
      if(as.numeric(humidity)<51.33){
        humidity<-1
      }else if(as.numeric(humidity)>75.67){
        humidity<-3
      }else{
        humidity<-2
      }
    }else{
      humidity<-0
    }
    
    if(a[3]!="NA"){
      rainfall<-gsub("mm","",a[3])
      
      if(as.numeric(rainfall)>0){
        rainfall<- 1
      }else{
        rainfall<- 0
      }
    }else{
      rainfall<-0
    }
  }








#-------------------日期清整---------------------------------------
week_match<-data.frame('week_name'=c("星期一","星期二","星期三","星期四","星期五","星期六","星期日"),'number'=c(1:7)) #日期比對表 Ubuntu 為週 windows為星期
week<-match(weekdays(Sys.Date()),week_match$week_name)
week<-as.character(week)

#-------------------整理今天預測資料-------------------------------
mydb <- dbConnect(RSQLite::SQLite(), "data")
restaurant_first<-data.frame(rep(0,length(dbReadTable(mydb,'record'))-5))

test_restaurant<-dbReadTable(mydb,'record')[(length(dbReadTable(mydb,'record')[,1])-4):length(dbReadTable(mydb,'record')[,1]),3:(length(dbReadTable(mydb,'record'))-3)] #找最後五筆
test_restaurant_name<-names(test_restaurant)
test_restaurant<-apply(test_restaurant,1,as.integer)  %>% t()%>%as.data.frame()
names(test_restaurant)<-test_restaurant_name

for(i in 1:(length(dbReadTable(mydb,'record')[1,])-5)){
  test<-test_restaurant[,i] #找最後五筆
    a = ifelse(test>=0&test<1,1,0)
    b = ifelse(test<0 | test>=1,1,0)
    if (sum(a) >=5){ #五天未出現
      restaurant_first[i,1] = restaurant_first[i,1]+0.5
    }else if(sum(b)>2){ #五天出現三次以上
      restaurant_first[i,1] = restaurant_first[i,1]-c(0.5)
    }
  
}



restaurant_first<-t(restaurant_first) %>%
  as.data.frame()

names(restaurant_first)<-paste('X',1:as.numeric(length(dbReadTable(mydb,'record'))-5),sep = "")
restaurant_first<-apply(restaurant_first,2,as.character) %>% as.data.frame() %>% t()
today_data<-data.frame('week' = week,restaurant_first,'humility'=as.character(humidity),'rainfall'=as.character(rainfall),'temperature'= as.character(temperature), stringsAsFactors = F)
#today_data<-data.frame('week' = week,restaurant_first,'humility'=humidity,'rainfall'=rainfall,'temperature'= temperature)
#儲存rds
saveRDS(today_data,"today_data.rds")
