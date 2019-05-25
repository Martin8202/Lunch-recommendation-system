library(shiny)
library(DBI)
library(RSQLite)
library(utils)
library(DT)

ui = fluidPage(
  headerPanel("餐廳推薦"),
  
  tabsetPanel(
    
    tabPanel('餐廳選擇',h4(tableOutput("eText"))), #table顯示
    tabPanel('累積次數',DT::dataTableOutput('aaa'))
  ),
  actionButton(inputId ="evReactiveButton", label = "今日推薦"), #按鈕(對應變數,顯示文字)
  hr(),
  h3('用餐後請填寫用餐餐廳'),
  #判斷能否自行填寫的code
  tags$script(HTML('       Shiny.addCustomMessageHandler("jsCode",
                   function(message) {
                   eval(message.code);
                   }
  );
                   ')),
  selectizeInput('restaurant',label = h5("至下方列表搜尋或選取用餐餐廳，若列表中無今日用餐餐廳，請選取其他並輸入於下方空格中，填選後點擊「餐廳儲存」"),
                 readRDS("restaurant_list.rds"),
                 selected = 1,
                 #讓列表一開始呈現空白，可以直接搜尋
                 options = list(
                   placeholder = '搜尋或選取餐廳',
                   onInitialize = I('function() { this.setValue(""); }')
                 )),
  textInput("text", label = NULL, value = "請於列表選擇其它"),
  actionButton("update", "餐廳儲存"),
  
  
  
  br(),
  br(),
  verbatimTextOutput("test")
  
  
)


