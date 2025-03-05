##### Análisis exploratorio de datos Adventureworks #####
## Análisis descriptivo de las variables, modelos de clasificación (regresión logística y árbol de decisión), técnicas de aprendizaje no supervisado (clusterización) y modelos de predicción (series temporales).

# DATASET = DataSet_SQL_Analisis_Masivo_de_Datos
install.packages(c("caret", "rpart", "factoextra", "forecast", "caTools"))
library(caret)
library(rpart)
library(factoextra)
library(forecast)
library(caTools)

##### PARTE 1: Análisis descriptivo de las variables #####

copia <- DataSet_SQL_Analisis_Masivo_de_Datos

dim(copia)
str(copia)
summary(copia)
var(copia)
sd(copia$BikePurchase)
sd(copia$TotalAmount)
sd(copia$TotalChildren)
sd(copia$Age)
cor(copia$TotalAmount,copia$BikePurchase)
cor(copia$TotalAmount, copia$TotalChildren)
cor(copia$TotalAmount,copia$Age)
cov(copia$TotalAmount,copia$BikePurchase)
cov(copia$TotalAmount, copia$TotalChildren)
cov(copia$TotalAmount,copia$Age)
boxplot(copia$BikePurchase)
boxplot(copia$TotalAmount)
boxplot(copia$TotalChildren)
boxplot(copia$Age)


##### PARTE 2: Modelo de regresión logística #####

regresionlogistica <- glm(BikePurchase~TotalAmount+Group+Age+MaritalStatus+YearlyIncome+Gender+TotalChildren+Education+Occupation+HomeOwnerFlag+NumberCarsOwned, data = copia, family = "binomial")
summary(regresionlogistica)
prediccionregresionlogistica <- predict(regresionlogistica, type = "response")
prediccionregresionlogisticacodificada <- ifelse(prediccionregresionlogistica>0.5,1,0)
confusionMatrix(as.factor(copia$BikePurchase), as.factor(prediccionregresionlogisticacodificada))

##### PARTE 3: Modelo de árbol #####
modeloarbol <- rpart(BikePurchase~TotalAmount+Group+Age+MaritalStatus+YearlyIncome+Gender+TotalChildren+Education+Occupation+HomeOwnerFlag+NumberCarsOwned, data = copia, method = "class")
prediccionmodeloarbol <- predict(modeloarbol, type = "class")
confusionMatrix(as.factor(copia$BikePurchase), as.factor(prediccionmodeloarbol))

##### PARTE 4: Aprendizaje no supervisado. Clusterización #####
archivonumerico <- copia[, sapply(copia, is.numeric)]
fviz_nbclust(archivonumerico,kmeans)
kmeans(archivonumerico,4)

##### PARTE 5: Modelo de predicción #####
año <- 2011
ts <- ts(copia$Sales...2, start=c(año,1), frequency=365)
modelots <- auto.arima(ts)
prediccionmodelots <- forecast (modelots, 365)
plot(prediccionmodelots)














