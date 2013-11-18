# Scaffold Size Distributions

## NG X of Scaffold Size

To create plots of  


```{r}
	library(ggplot2)
	library(ggthemes)
	
	##load data
	data <- read.csv("NGX_chalara.csv", header=FALSE)
	names(data) <- c("x", "y")
	
	ggplot(data, aes(x,y)) 
	+ geom_step(color="blue",size=1)
	+ scale_y_log10("Scaffold NG(X) Length",breaks=c(10000, 100000),labels=c("10000","100000"))
	+ scale_x_continuous("NG(X) %")
	+ theme_few()

```
