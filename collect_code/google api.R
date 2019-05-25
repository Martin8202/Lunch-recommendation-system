
### 1. 以餐廳名稱取得評分與經緯度
library(RCurl)
library(RJSONIO)
library(plyr)
library(DBI)
library(RSQLite)
#setwd("C:/Users/user/Desktop/Martin/R/lunch/預測餐廳模型/shiny/")

#距離API https://developers.google.com/maps/documentation/javascript/distancematrix?hl=zh-tw
#search API https://developers.google.com/places/web-service/search?hl=zh-tw
#url = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=明吉%20MINJI%20CUISINE&language=zh-TW&key=AIzaSyAgQL3Le7a5nk2_kkRmTV_Cuw3FDJt4LxQ"
#url = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=103台北市大同區承德路一段38號%20肯德基&language=zh-TW&key=AIzaSyAgQL3Le7a5nk2_kkRmTV_Cuw3FDJt4LxQ"
#url = iconv(url,"big5","utf8")
#a = fromJSON(getURL(url),simplify = FALSE)

restaurant = as.character(readRDS("restaurant_match.rds")$Store[1:length(readRDS("restaurant_match.rds")$Store)-1])

mydb <- dbConnect(RSQLite::SQLite(), "data")
restaurant_number = as.integer(dbReadTable(mydb,'record')[length(dbReadTable(mydb,'record')[,1]),1])

if(restaurant_number == (length(restaurant))){
  name = c()
  rating = c()
  lat = c()
  lng = c()
  for(i in 1:length(restaurant)){
    d = gsub(" ", "%20",restaurant[i])
    a = paste("https://maps.googleapis.com/maps/api/place/textsearch/json?query=" ,d,"&language=zh-TW&key=AIzaSyDaa-JL4vLY8Wq6fYNurKOuSNUlZ17z4eg&location=25.052279,121.5166588&radius=800",sep = "")
    b = fromJSON(getURL(a),simplify = FALSE)
    if(is.null(b$results)){
      name = c(name,restaurant[i])
      rating = c(rating,"無資料")
      lat = c(lat,"")
      lng = c(lng,"")
    }else{
      name = c(name,b$results[[1]]$name)
      lat = c(lat,b$results[[1]]$geometry$location$lat)
      lng = c(lng,b$results[[1]]$geometry$location$lng)
      if(is.null(b$results[[1]]$rating)){
        rating = c(rating,"無資料")
      }else{
        rating = c(rating,b$results[[1]]$rating)
      }
    print(i)
  }
  
  
  name[1] = "古早味麵店_人工改"
  rating[1] = "無資料"
  lat[1] = "25.0516205"
  lng[1] = "121.5168466"
  
  ###計算距離
  
  distance_key = "AIzaSyCWorVBMgjF7vjLhsaW2ewkZTNprgE4yX4"
  distance_url <- function(lat_1, lng_1, lat_2, lng_2, key, return.call = "json") {
    root <- 'https://maps.googleapis.com/maps/api/distancematrix/'
    u <- paste(root, return.call, "?origins=", lat_1, ",", lng_1, "&destinations=",
               lat_2, ",", lng_2, "&mode=walking&key=", key, sep = "")
    #return(URLencode(u))
    u
  }
  
  distance=c()
  for (i in 1:length(name)){
    lat_2 = lat[i]
    lng_2 = lng[i]
    a = distance_url(25.052279, 121.517206, lat_2, lng_2, distance_key)
    a = fromJSON(getURL(a),simplify = FALSE)
    a = a$rows[[1]]$elements[[1]]$distance$value 
    distance = c(distance,a)
    print(i)
  }
  
  data = data.frame( 'ori_name'=restaurant,'name'=name,'rating' = rating,'lat' =lat, 'lng'=lng,'distance' =distance,stringsAsFactors = F)
  saveRDS(data,"restaurant_other.rds")
  #write.xlsx(data,"C:/Users/user/Desktop/Martin/R/lunch/預測餐廳模型/ori_data/rating_and_distance.xlsx",row.names = FALSE)
  
}


