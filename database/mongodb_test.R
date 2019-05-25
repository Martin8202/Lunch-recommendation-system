library(mongolite)

#do.call('rbind', lapply(1:length(m), function(x) unlist(m[,x]))))
#http://www.cnblogs.com/egger/p/3135847.html ####使用方法


Record <- mongo(db ='Tomahawk', collection ='Record','mongodb://123.51.165.169:47017/Tomahawk')
a <- Record$find('{}')

AnswerRank <- mongo(db ='Tomahawk', collection ='AnswerRank','mongodb://123.51.165.169:47017/Tomahawk')
b <- AnswerRank$find('{ "data": { "$exists": "true" }}')
food <- b[as.character(b$data)==date,]
food <- AnswerRank$find('{ "data": "',date,'"}')

Ipeenshop <- mongo(db ='Tomahawk', collection ='IpeenShop','mongodb://123.51.165.169:47017/Tomahawk')
d <- Ipeenshop$find('{}')

#restaurant_eat 製作
restaurant_match <- Ipeenshop$find(query = '{ "shopId": { "$exists": "true" }}',fields = '{"shopId":true}')


User <- mongo(db ='Tomahawk', collection ='User','mongodb://123.51.165.169:47017/Tomahawk')
e <- User$find('{}')
