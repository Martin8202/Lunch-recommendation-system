
setwd('/srv/shiny-server/shiny')
server=shinyServer(function(input, output,session) {
  d = c()
  #讀取餐廳match列表
  restaurant_match<-readRDS("restaurant_match.rds")$Store
  restaurant_match<-data.frame('number' = c(1:length(restaurant_match)),'Store' = restaurant_match)
  restaurant_match$Store<-as.character(restaurant_match$Store)
  library(DBI)
  library(RSQLite)
  library(randomForest)
  library(dplyr)
  #點選其它才能填寫
  observe({
    if(input$restaurant != "enable") {
      observeEvent(input$restaurant,{
        updateTextInput(session, "text", value = "請於列表選擇其它")
      })
      session$sendCustomMessage(type="jsCode",
                                list(code= "$('#text').prop('disabled',true)"))
    } else {
      observeEvent(input$restaurant,{
        updateTextInput(session, "text", value = "")
      })
      session$sendCustomMessage(type="jsCode",
                                list(code= "$('#text').prop('disabled',false)"))
      
    }
    
  })
  
  
  #-------------------------預測-------------------------------
  
  etext <- function() { #(觸發條件,{執行程式})
    input$evReactiveButton    
    d = c()
    model<-readRDS("randomforest.rds")
    today_data<-readRDS("today_data.rds")
    today_outcome<- predict(model,today_data,type = 'prob')
    
    a = today_outcome[1,][today_outcome>=0.01] #小於0.012的機率列入隨機名單中
    a_prob = a
    #------------判斷未出現過的餐廳
    n = c(1:(length(restaurant_match[,1])-1))
    #m為機率為0的餐廳
    m=c()
    for(i in c(1:length(n))){
      x = (n[i]==names(a))
      if(sum(x)==0){
        m = c(m,n[i])
      }
    }
    
    #兩個相同排名相同
    a = min_rank(a*(-1))
    for(j in c(1:2)){
      b = which(a == j)
      if(length(d)<2){
        d = c(d,names(b))
      }
    }
    
    restaurant_rating_and_distance<-readRDS("restaurant_other.rds")
    today_result<-readRDS("today_result.rds")
    #---------------------判斷前兩筆依樣顯示最終結果-----------------------
    if(all(sort(try(today_result[[length(today_result)]][1:(length(today_result[[length(today_result)]])-1)],silent = T))==sort(d))){
      b = d
      while(all(sort(d)==sort(b))){
        b = sample(names(a),size = 2,prob = as.character(a_prob))
      }
      d = c(b,sample(m,1))
      today_result[length(today_result) + 1 ] = list(d)
      saveRDS(today_result,file ="today_result.rds" )
    }else{
      d = c(d,sample(m,1))
      today_result[length(today_result) + 1 ] = list(d)
      
      saveRDS(today_result,file ="today_result.rds" )
      f = length(today_result)
      for (i in 1:length(today_result[[f]])){
        if(as.numeric(today_result[[f]][i])<=(length(today_data)-4)){
          if(today_data[(match(today_result[[f]][i],restaurant_match$number)+1)] <=0.5){
            x <- (match(today_result[[f]][i],restaurant_match$number)+1)
            today_data[x]<- as.numeric(today_data[x]) + 1  
          }
        }
      }
      saveRDS(today_data,file ="today_data.rds" )
    }
    
    
    today_restaurant=c()
    for (i in 1:(length(d))){
      today_restaurant<-c(today_restaurant,restaurant_match[d[i],2])
    }
    saveRDS(today_restaurant,file ="today_restaurant.rds" )
    rating = c()
    distance = c()
    for(i in 1:length(d)){
      
      rating = c(rating,as.character(restaurant_rating_and_distance[d[i],3]))
      distance = c(distance,as.character(restaurant_rating_and_distance[d[i],6]))
    }
    
    today_answer = t(data.frame(rating, distance))
    today_answer = cbind(c('餐廳評價(滿分5.0)','行走距離(公尺)'),today_answer)
    colnames(today_answer) = c(" ",today_restaurant)
    
    
    
    print(today_answer)
  }
  
  output$eText <- renderTable({ #執行文字
    etext()
  })
  
  #-----------------------餐廳記數表------------------------------
  
  numeric_table<-function(){
    input$evReactiveButton    
    today_table<-data.frame('餐廳名稱'=restaurant_match[1:length(restaurant_match$Store)-1,2],'出現次數'= as.numeric(rep(0,length(restaurant_match$Store)-1)))
    today_table$出現次數<-as.integer(today_table$出現次數)
    today_result<- readRDS("today_result.rds")
    for(i in 1:length(today_result)){
      for(j in 1:length(today_result[[i]])){
        a = restaurant_match[today_result[[i]][j],2]
        if(is.na(match(a,today_table[,1]))){
          today_table =rbind(today_table,c(a,1))
          today_table$出現次數<-as.integer(today_table$出現次數)
        }else{
          today_table[match(a,today_table[,1]),2] <- today_table[match(a,today_table[,1]),2] + 1
        }
      }
    }
    today_table = today_table[today_table$出現次數!=0,]
    today_table<-today_table[order(today_table$出現次數, decreasing = T), ]
    today_table$出現次數<-as.character(today_table$出現次數)
    row.names(today_table)<-c(1:length(today_table[,1]))
    print(today_table)
  }
  
  output$aaa <- DT::renderDataTable(
    DT::datatable(
      numeric_table(), options = list(
        lengthMenu = list(c(5, 10, -1), c('5', '10', 'All')),
        pageLength = 5
      )
    )
  )
  
  
  #-----------------------今天餐廳更新----------------------------------
  datasetInput <- eventReactive(input$update, {
    #---------if(input$text == "") 判斷是否為空格---------------  
    if(input$restaurant == "enable"){
      if(input$text == ""){
        e = paste(Sys.time(),weekdays(Sys.Date()),'內容不可為空白')
      }else{
        a = input$text
        restaurant_match<-as.character(readRDS("restaurant_match.rds")$Store)
        
        if(is.na(match(as.character(a),restaurant_match))){
          restaurant_match<-restaurant_match[-length(restaurant_match)]
          restaurant_match<-c(restaurant_match,a,"其它")
          #製作餐廳列表,list格式
          restaurant_list = list()
          for(i in 1:(length(restaurant_match)-1)){
            restaurant_list[[restaurant_match[i]]] = restaurant_match[i]
          }
          restaurant_list[['其它']]='enable'
          saveRDS(restaurant_list,"restaurant_list.rds")
          restaurant_match<-data.frame('number' = c(1:(length(restaurant_match))),'Store' = restaurant_match)
          saveRDS(restaurant_match,"restaurant_match.rds")
          
          today_data<-readRDS("today_data.rds")
          
          react_answer<-as.integer(length(restaurant_match$Store)-1)
          rownames(today_data)<-as.character(react_answer)
          today_data<-data.frame('y' = react_answer,today_data)
          saveRDS(today_data,"today_answer")
          e = paste(Sys.time(),weekdays(Sys.Date()),input$text,'餐廳已更新並儲存完成','\n\n謝謝您的填寫')
          e
        }else{
          a = input$text
          today_data<-readRDS("today_data.rds")
          react_answer<-match(as.character(a),restaurant_match)
          
          rownames(today_data)<-react_answer
          today_data<-data.frame('y' = react_answer,today_data)
          saveRDS(today_data,"today_answer")
e = paste(Sys.time(),weekdays(Sys.Date()),input$text,'儲存完成，今日餐廳已存在列表中，','\n下次請至列表中點選餐廳並儲存')
e
        }
      }
    }else{
      today_data<-readRDS("today_data.rds")
      a = input$restaurant
      if(a ==""){
        e = paste(Sys.time(),weekdays(Sys.Date()),'列表不可為空白')
      }else{
        react_answer<-match(as.character(a),restaurant_match$Store)
        today_data<-readRDS("today_data.rds")
        row.names(today_data)<-react_answer
        today_data<-data.frame('y' = react_answer,today_data)
        saveRDS(today_data,"today_answer")
e = paste(Sys.time(),weekdays(Sys.Date()),input$restaurant,'儲存完成','\n\n謝謝您的填寫')

        
      }
      e
    }
    
  })
  
  
  
  output$test <- renderText({ #執行文字
    datasetInput()
  })
  
})

