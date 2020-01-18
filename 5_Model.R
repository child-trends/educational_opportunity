################################################################
# Project: USALEEP                                             #
# Purpose: Regression analysis and confidence intervals        #
################################################################


#######################################
##            Libraries             ##
#######################################
library(lmtest)
library(sandwich)

#######################################
##            Data read in           ##
#######################################
# read in data created by data preparation scripts
hs <- read.csv("school_data.csv")
census <- read.csv("census_data.csv") 

###############################################################
##            LE ~ Educational Opportunity               ##
###############################################################

schoolmodel <- lm(life_expectancy_at_start.15.24 ~ EDUCATIONAL_OPP, data = hs)
summary(schoolmodel)
coeftest(schoolmodel, vcov = vcovHC(schoolmodel, type="HC1"))

censusmodel <- lm(life_expectancy_at_start.15.24 ~ EDUCATIONAL_OPP, data = census)
summary(censusmodel)
coeftest(censusmodel, vcov = vcovHC(censusmodel, type="HC1"))



###############################################################
##    LE ~ Educational Opportunity + Poverty           ##
###############################################################

schoolmodel2 <- lm(life_expectancy_at_start.15.24 ~ EDUCATIONAL_OPP+Percent_Under_Poverty_Level, data = hs)
summary(schoolmodel2)
coeftest(schoolmodel2, vcov = vcovHC(schoolmodel2, type="HC1"))

censusmodel2 <- lm(life_expectancy_at_start.15.24 ~ EDUCATIONAL_OPP+Percent_Under_Poverty_Level, data = census)
summary(censusmodel2)
coeftest(censusmodel2, vcov = vcovHC(censusmodel2, type="HC1"))


###############################################################
##    LE ~ Educational Opportunity + Race          ##
###############################################################

schoolmodel3 <- lm(life_expectancy_at_start.15.24 ~ EDUCATIONAL_OPP+Percent_Black+Percent_Hispanic+Percent_American_Indian+Pacific_Islander+Asian, data = hs)
summary(schoolmodel3)
coeftest(schoolmodel3, vcov = vcovHC(schoolmodel3, type="HC1"))


censusmodel3 <- lm(life_expectancy_at_start.15.24 ~ EDUCATIONAL_OPP+Percent_Black+Percent_Hispanic+Percent_American_Indian+Pacific_Islander+Asian+Two_Or_More, data = census)
summary(censusmodel3)
coeftest(censusmodel3, vcov = vcovHC(censusmodel3, type="HC1"))


###########################################################################
##   Final Model:  LE ~ Educational Opportunity + Race   + Poverty       ##
###########################################################################

final_model <- lm(life_expectancy_at_start.15.24 ~ EDUCATIONAL_OPP+Percent_Under_Poverty_Level+Percent_Black+Percent_Hispanic+Percent_American_Indian+Pacific_Islander+Asian, data = hs)
summary(final_model)
coeftest(final_model, vcov = vcovHC(final_model, type="HC1"))


censusmodel4 <- lm(life_expectancy_at_start.15.24 ~ EDUCATIONAL_OPP+Percent_Under_Poverty_Level+Percent_Black+Percent_Hispanic+Percent_American_Indian+Pacific_Islander+Asian+Two_Or_More, data = census)
summary(censusmodel4)
coeftest(censusmodel4, vcov = vcovHC(censusmodel4, type="HC1"))

###############################
##   Confidence Interval     ##
###############################

# See methods write up for description of mathematical justifications
# generate predicted values for CI 
x_new <- data.frame("EDUCATIONAL_OPP" = c(mean(hs$EDUCATIONAL_OPP[hs$EDUCATIONAL_OPP_CATEGORY==1 & !is.na(hs$EDUCATIONAL_OPP_CATEGORY)],na.rm=T),mean(hs$EDUCATIONAL_OPP[hs$EDUCATIONAL_OPP_CATEGORY==3 & !is.na(hs$EDUCATIONAL_OPP_CATEGORY)],na.rm=T),mean(hs$EDUCATIONAL_OPP[hs$EDUCATIONAL_OPP_CATEGORY==5 & !is.na(hs$EDUCATIONAL_OPP_CATEGORY)],na.rm=T)),lapply(names(model$coefficients)[3:10],FUN=function(x){rep(mean(hs[,x],na.rm=TRUE),3)}))
names(x_new) <- names(final_model$coefficients)[2:10]

# identify predicted values 
mean_y_var <- mean(hs$life_expectancy_at_start_se.15.24^2,na.rm=T)
X <- as.matrix(hs[complete.cases(hs[,names(x_new)]),names(x_new)]) # X is complete cases only adn only relevant vars
y <- hs[complete.cases(hs[,names(x_new)]),"life_expectancy_at_start.15.24_plus_15"]
y_hat <- predict(final_model,hs[complete.cases(hs[,names(x_new)]),names(x_new)])
p <- ncol(X)+ 1 # p is number of parameters + 1 for the intercept 
df <- nrow(X) - p -1

get_se_ci <- function(x_0){
  s_squared <- sum((y- y_hat)^2)/(nrow(X)-p)
  var_y_hat <-  s_squared*(1 + x_0%*% solve(t(X)%*%X)%*%t(x_0))
  
  total_se <- sqrt(var_y_hat + mean_y_var)
  return(total_se)
} 

