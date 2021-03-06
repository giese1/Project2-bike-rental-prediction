# Packages
library(tidyverse)
library(lubridate)
library(plotly)
library(sqldf)
library(corrplot)
library(rpart)
library(caret)
library(rpart.plot)
library(party)
library(randomForest)
library(e1071)
library(neuralnet)

# Loading dataset

bikes <- read.csv("SeoulBikeData.csv", header = TRUE, sep = ",")

str(bikes)
summary(bikes)

#### Descriptive analysis ####

# Unique variables of humidity

c(unique(bikes["Humidity..."]))

# Unique variables of hour

c(unique(bikes["Hour"]))

# Transforming factor date column into date

bikes$Date <- as.POSIXct(bikes$Date, format = "%d/%m/%Y")
bikes$Date

bikes$Date <- as.Date(bikes$Date)

# Bikes sold over time plot

a <- ggplot(data = bikes) +
  geom_line(aes(x = Date, y = Rented.Bike.Count), 
            color = "#09557f",
            alpha = 0.6,
            size = 0.6) +
  theme_minimal() +
  labs(x = "Date", 
       y = "Bikes" ,
       title = "Base Plot")

a <- ggplotly(a)
a


#### Exploratory analysis ####

# Bikes sold per season plot


b <- ggplot(data = bikes) +
  geom_line(aes(x = Date, y = Rented.Bike.Count, col = Seasons), 
            alpha = 0.6,
            size = 0.6) +
  scale_x_date(date_breaks = "1 month") +
  scale_color_manual(labels = c("Autumn", "Spring", "Summer", "Winter"),
                     values = c("red", "green", "yellow", "blue")) +
  theme_minimal() +
  labs(x = "Date", 
       y = "Bikes" ,
       title = "Bikes sold per seasons ")

b <- ggplotly(b)
b

# Bikes sold overtime in holidays and normal days plot

c <- ggplot(data = bikes) +
  geom_line(aes(x = Date, y = Rented.Bike.Count, col = Holiday), 
            alpha = 0.6,
            size = 0.6) +
  scale_x_date(date_breaks = "1 month") +
  theme_minimal() +
  labs(x = "Date", 
       y = "Bikes" ,
       title = "Bikes sold holiday and normal days")

c <- ggplotly(c)
c

# Rainfall and solar radiation in different seasons in the bike shops plot

d <- ggplot(data = bikes) +
  geom_line(aes(x = Date, y = Rainfall.mm., col = Seasons), 
            alpha = 0.6,
            size = 0.6) +
  geom_line(aes(x = Date, y = Solar.Radiation..MJ.m2.), 
            alpha = 0.6,
            size = 0.6, color = "orange") +
  scale_x_date(date_breaks = "1 month") +
  scale_color_manual(labels = c("Autumn", "Spring", "Summer", "Winter"),
                     values = c("red", "green", "yellow", "blue")) +
  theme_minimal() +
  labs(x = "Date", 
       y = "Rainfall mm and solar radiation" ,
       title = "Rainfall and solar radiation in different seasons in the bike shops")

d <- ggplotly(d)
d

# Temperature and wind speed over time and in different seasons plot

e <- ggplot(data = bikes) +
  geom_line(aes(x = Date, y = Temperature..C., col = Seasons), 
            alpha = 0.6,
            size = 0.6) +
  geom_line(aes(x = Date, y = Wind.speed..m.s.), 
            alpha = 0.6,
            size = 0.6, color = "grey") +
  scale_x_date(date_breaks = "1 month") +
  scale_color_manual(labels = c("Autumn", "Spring", "Summer", "Winter"),
                     values = c("red", "green", "yellow", "blue")) +
  theme_minimal() +
  labs(x = "Date", 
       y = "Temperature in C and wind speed" ,
       title = "Temperature and wind speed in different seasons in the bike shops")


e <- ggplotly(e)
e


#### Pre processing ####

# Attribute enginnering the seasons column

# transforming all seasons in categorical variables

all_seasons_col = 1 # Winter

all_seasons_col = 2 # Spring

all_seasons_col = 3 # Summer

all_seasons_col = 4 # Autumn

# sorting winter only column

winter_s <- sqldf(
  
  "SELECT * FROM bikes WHERE Seasons LIKE '%Winter' "
)

winter_s <- cbind(winter_s, all_seasons_col)

# sorting spring only column

Spring_s <- sqldf(
  
  "SELECT * FROM bikes WHERE Seasons LIKE '%Spring' "
)


Spring_s <- cbind(Spring_s, all_seasons_col)

# sorting autumn only column

Autumn_S <- sqldf(
  
  "SELECT * FROM bikes WHERE Seasons LIKE '%Autumn' "
)



Autumn_S <- cbind(Autumn_S, all_seasons_col)

# sorting summer only column

Summer_s <- sqldf(
  
  "SELECT * FROM bikes WHERE Seasons LIKE '%Summer' "
)

Summer_s <- cbind(Summer_s, all_seasons_col)



# merging all seasons in the same dataframe

all_seasons <- merge(winter_s, Spring_s, all = TRUE)

all_seasons2 <- merge(Autumn_S, Summer_s, all = TRUE)

all_seasons_final <- merge(all_seasons, all_seasons2, all = TRUE)

# variables correlations plot for feature selection

str(all_seasons_final)

all_seasons_final$Date <- NULL
all_seasons_final$Seasons<- NULL
all_seasons_final$Holiday <- NULL
all_seasons_final$Functioning.Day <- NULL

correlations <- cor(all_seasons_final,method="pearson")

corrplot(correlations, number.cex = .9, method = "circle", type = "full", tl.cex=0.8,tl.col = "black",
         title = "bikes")

# removing not important columns for machine learning

all_seasons_final$Functioning.Day <- NULL
all_seasons_final$Hour <- NULL
all_seasons_final$Dew.point.temperature..C. <- NULL


# converting some columns variables types

all_seasons_final$Visibility..10m. <- as.numeric(all_seasons_final$Visibility..10m.)

all_seasons_final$Humidity... <- as.numeric(all_seasons_final$Humidity...)

all_seasons_final$Rented.Bike.Count <- as.numeric(all_seasons_final$Rented.Bike.Count)



# separating data into train and test

indexes <- sample(1:nrow(all_seasons_final), size = 0.7 * nrow(all_seasons_final))
train.data.bikes <- all_seasons_final[indexes,]
test.data.bikes <- all_seasons_final[-indexes,]
class(train.data.bikes)
class(test.data.bikes)

str(train.data.bikes)


#### Machine learning ####

# Creating linear regression machine learning model 


modelo <- lm(Rented.Bike.Count ~. , data = train.data.bikes)


# prevision for the testing data

prevision1 <- predict(modelo, test.data.bikes)

summary(modelo)

# making plot of real and predictive data


print(data.frame(test.data.bikes$Rented.Bike.Count, prevision1))

x = 1:length(test.data.bikes$Rented.Bike.Count)

plot(x, test.data.bikes$Rented.Bike.Count, col = "red", type = "l", lwd=2,
     main = "Bikes selling real and predictive data")
lines(x, prevision2, col = "blue", lwd=2)
legend("topleft",  legend = c("real data", "predictive data"), 
       fill = c("red", "blue"), col = 2:3,  adj = c(0, 0.6))
grid()


# decision tree model

ma_model_tree <- rpart(Rented.Bike.Count ~., 
                     data = train.data.bikes)

rpart.plot(ma_model_tree)

pred_model <- predict(ma_model_tree, test.data.bikes)

printcp(ma_model_tree)

# making plot of real and predictive data


print(data.frame(test.data.bikes$Rented.Bike.Count, pred_model))

x = 1:length(test.data.bikes$Rented.Bike.Count)

plot(x, test.data.bikes$Rented.Bike.Count, col = "red", type = "l", lwd=2,
     main = "Bikes selling real and predictive data")
lines(x, pred_model, col = "blue", lwd=2)
legend("topleft",  legend = c("real data", "predictive data"), 
       fill = c("red", "blue"), col = 2:3,  adj = c(0, 0.6))
grid()


# Randomforest model

ma_model <- randomForest(Rented.Bike.Count ~., data = train.data.bikes)

print(ma_model)
plot(ma_model)

summary(ma_model)

pred_model <- predict(ma_model, test.data.bikes)

# making plot of real and predictive data


print(data.frame(test.data.bikes$Rented.Bike.Count, pred_model))

x = 1:length(test.data.bikes$Rented.Bike.Count)

plot(x, test.data.bikes$Rented.Bike.Count, col = "red", type = "l", lwd=2,
     main = "Bikes selling real and predictive data")
lines(x, pred_model, col = "blue", lwd=2)
legend("topleft",  legend = c("real data", "predictive data"), 
       fill = c("red", "blue"), col = 2:3,  adj = c(0, 0.6))
grid()


# knn control archive

ctrl <- trainControl(method = "repeatedcv", repeats = 3) 

# knn model
knn_v1 <- train(Rented.Bike.Count ~ ., 
                data = train.data.bikes, 
                method = "knn", 
                trControl = ctrl, 
                tuneLength = 20)
knn_v1

pred_model <- predict(knn_v1, test.data.bikes)

# making plot of real and predictive data


print(data.frame(test.data.bikes$Rented.Bike.Count, pred_model))

x = 1:length(test.data.bikes$Rented.Bike.Count)

plot(x, test.data.bikes$Rented.Bike.Count, col = "red", type = "l", lwd=2,
     main = "Bikes selling real and predictive data")
lines(x, pred_model, col = "blue", lwd=2)
legend("topleft",  legend = c("real data", "predictive data"), 
       fill = c("red", "blue"), col = 2:3,  adj = c(0, 0.6))
grid()