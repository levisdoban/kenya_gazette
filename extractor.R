setwd("C:/Users/user/Google Drive/Data_Science/gazette")
source("functions.R")

libs = c("RCurl", "XML", "stringr", "data.table", "httr")
prepareLibs(libs)


url <- "http://kenyalaw.org/kenya_gazette/"
webpage <- getURL(url,.opts = list(ssl.verifypeer = FALSE))


doc = htmlParse(webpage, asText=TRUE)
links <- xpathSApply(doc, "//@href")
links = links[grep("month", links)]
linksdt = data.table(links)

editions_urls = data.frame()

for(i in 1:dim(linksdt)[1]){
  
  ul1 = linksdt[i,links]
  
  html <- getURL(ul1,.opts = list(ssl.verifypeer = FALSE))
  tables<-readHTMLTable(html)
  
  tables = tables[unlist(lapply(tables,is.data.frame))]
  nms = lapply(tables,names)
  gg = lapply(nms,is.element,'Date')
  gg2 = lapply(gg, any)
  ftables = tables[unlist(gg2)]
  ftables = do.call(rbind, ftables)
  
  doc2 = htmlParse(html, asText=TRUE)
  pageurls <- xpathSApply(doc2, "//@href")
  pageurls = pageurls[grep("volume", pageurls)]
  
  ftables = cbind(ftables, pageurls)
  editions_urls = rbind(editions_urls,ftables)
  
}

saveRDS(editions_urls, "all_editions.RDS")

#NOw TO EXTRACT EACH OF THE PAGES AND SAVE AS DOCUMENT 

if(!dir.exists("editions")) dir.create("editions")

for(i in 1:dim(editions_urls)[1]){
editions_urls = data.table(editions_urls)

url1 = as.character(editions_urls[i,pageurls])
pg_date =gsub(",","",gsub(" ","",as.character(editions_urls[i,Date])))
htm2 <- getURL(url1,.opts = list(ssl.verifypeer = FALSE))
doc2 = htmlParse(htm2, asText=TRUE)

fff = xpathSApply(doc2, "//div/@id")  
fff = fff[grep("GAZETTE NOTICE NO", fff)]

if(length(fff) > 0){
fff = data.frame(fff) 
for(j in 1:dim(fff)[1]){
gznt = as.character(fff[j,1])
gt = paste0("//*[@id='",gznt,"']")

views=xpathSApply (doc2,gt,xmlValue)
fname = paste0("./editions/",pg_date, "_", gsub("[.]","",gsub(" ","",gznt)), ".txt")

write(views, fname)
}
}

}