server=shinyServer(function(input, output,session) {
  d = c()
  restaurant_match<-readRDS("restaurant_match.rds")$Store
  restaurant_match<-data.frame('number' = c(1:length(restaurant_match)),'Store' = restaurant_match)
  restaurant_match$Store<-as.character(restaurant_match$Store)
  library(DBI)
  library(RSQLite)
  library(randomForest)
  library(dplyr)
  observeEvent(input$write,{
    updateTextInput(session, "text", value = "")
  })
  #讀取餐廳列表
  #-------------------------預測-------------------------------
  etext <- eventReactive(input$evReactiveButton, { #(觸發條件,{執行程式})
    model<-readRDS("randomforest.rds")
    today_data<-readRDS("today_data.rds")
    today_outcome<- predict(model,today_data,type = 'prob')
    #------------顯示列表----------------
    a = today_outcome[1,][today_outcome!=0]
    a = min_rank(a*(-1))
    for(j in c(1:3)){
      b = which(a == j)
      if(length(d)<3){
        d = c(d,names(b))
      }
    }
    
    
    today_answer=list()
    for (i in 1:length(a)){
      today_answer[i]<-restaurant_match[names(a)[i],2]
    }
    today_result<-readRDS("today_result.rds")
    today_result[length(today_result) + 1 ] = list(d)
    saveRDS(today_result,file ="today_result.rds" )
    for (j in 1:length(today_result)){
      for (i in 1:length(today_result[[j]])){
        if(as.numeric(today_result[[j]][i])<=23){
          if(today_data[(match(today_result[[j]][i],restaurant_match$number)+1)] <=0.5){
            today_data[(match(today_result[[j]][i],restaurant_match$number)+1)]<- today_data[(match(today_result[[j]][i],restaurant_match$number)+1)] + 1 
          }
        }
      }
    }
    saveRDS(today_data,file ="today_data.rds" )
    today_answer
    paste(today_answer,collapse  = "\n")
  })
  
  output$eText <- renderText({ #執行文字
    etext()
  })
  #-----------------------今天餐廳更新-列表----------------------------------
  datasetInput <- eventReactive(input$update, {
    
    if(input$text == "請先確認餐廳列表"){
      today_data<-readRDS("today_data.rds")
      a = input$restaurant
      react_answer<-match(as.character(a),restaurant_match$Store)
      row.names(today_data)<-react_answer
      today_data<-data.frame('y' = react_answer,today_data)
      
      mydb <- dbConnect(RSQLite::SQLite(), "data")
      b = dim(dbReadTable(mydb,'record'))[1]
      dbWriteTable(mydb,'record',today_data,append = T,row.names = F)
      d = dim(dbReadTable(mydb,'record'))[1]
      dbDisconnect(mydb)
      if(d-b == 1){
        e = paste(Sys.time(),weekdays(Sys.Date()),input$restaurant,'儲存完成')
      }else{
        e = paste(Sys.time(),weekdays(Sys.Date()),input$restaurant,'儲存失敗')}
      e
    }else{
      a = input$text
      restaurant_match<-as.character(readRDS("restaurant_match.rds")$Store)
      if(is.na(match(as.character(a),restaurant_match))){
        restaurant_match<-c(restaurant_match,a)
        restaurant_match<-data.frame('number' = c(1:(length(restaurant_match))),'Store' = restaurant_match)
        saveRDS(restaurant_match,"restaurant_match.rds")
      
        today_data<-readRDS("today_data.rds")
        
        react_answer<-as.integer(length(restaurant_match$Store))
        rownames(today_data)<-as.character(react_answer)
        today_data<-data.frame('y' = react_answer,today_data)
        
        
        
        mydb <- dbConnect(RSQLite::SQLite(), "data")
        b = dim(dbReadTable(mydb,'record'))[1]
        dbWriteTable(mydb,'record',today_data,append = T,row.names =F)
        d = dim(dbReadTable(mydb,'record'))[1]
        dbDisconnect(mydb)
        if(d-b == 1){
          e = paste(Sys.time(),weekdays(Sys.Date()),input$text,'餐廳更新完成')
        }else{
          e = paste(Sys.time(),weekdays(Sys.Date()),input$text,'餐廳更新失敗')}
        e
        
      }else{
        e = paste(Sys.time(),weekdays(Sys.Date()),input$text,'已存在列表中')
      }
      
    }
  })
  
   
  
  output$test <- renderText({ #執行文字
    datasetInput()
  })
  
})
