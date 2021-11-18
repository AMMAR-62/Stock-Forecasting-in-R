# server.R
# the shiny has two components server and ui.
# the server is open for connections and as the ui is updated it connects to server and transfers the changed data.

# the quantmod and forecast libraries are the machine learning libraries.
# quantmod - Quantitative financial modelling and trading framework for R, designed to assist the quantitative trade in the development, testing, and deployment of statistically based trading models.
# quantmod - provides for the yahoo finance data and the getSymbols function.
# forecast - provides methods and tools for displaying and analysing univariate time series forecasts including exponential smoothing via state space models and automatic ARIMA modelling.
# 
library(quantmod)
library(forecast)
library(caTools)

# sets locale for the system, equivalent to setting the language in HTML.
Sys.setlocale(category = "LC_ALL", locale = "English")

# constructs the server
shinyServer(function(input, output) {
  # this is a reactive expression in R.
  # a reactive expression in R uses widget input and returns a value.
  # it updates this value whenever the original widget changes.
  # this takes the data input from the yahoo website, the input symbol and mLearn, mPredict parameters are passed from the UIs.
  dataInput <- reactive({
    data <- as.data.frame(getSymbols(input$symb, src = "yahoo", 
      from = as.character(Sys.Date()-input$mLearn*30.5-input$mPredict*30.5),
      to = as.character(Sys.Date()),
      auto.assign = FALSE))
    # class(input$symb) // xts/zoo  - different than the usual dataframe, it has a data column and the date column
    # three components - coredata, index, xtsAttributes.
    # 1) Open, 2) High, 3) Low, 4) Close, 5) Volume, 6) Adjusted.

    lineardata <- data

    # converting the data into monthly series, this can be done into daily or yearly, as it is a univariate object.
    # 
    data <- to.monthly(data)
    
    # composite likelihood calculation for spatial ordinal data without replications.
    # ordinal data - categorical data with a set order or scale to it.
    # composite likelihood - different interval likelihood calculation.
    # likelihood - the join probability of the observed data as a function of chosen parameters.
    data <- Cl(data)
    
    # converting the data into time series object, it takes vector as the input.
    # the frequency is 12 for 1 monthly observation.
    ts1 <- ts(data, frequency = 12)

    # splitting the linear data into train and test sets.
    set.seed(2)
    split <- sample.split(lineardata, SplitRatio=0.7)
    train <- subset(lineardata, split="TRUE")
    test <- subset(lineardata, split="FALSE")
    
    # dividing into training and testing data sets.
    ts1Train <- window(ts1, start = 1, end = (input$mLearn)/12+1-0.01)
    ts1Test <- window(ts1, start = input$mLearn/12+1, end = length(ts1)/12+1-0.1)
    
    # this smoothens the model so that the prediction deviation are seen smoothly - the exponential smmoothing state space model function.
    # exponential smoothing is a time series forecasting method for univariate
    ets1 <- ets(ts1Train, model="MMM")
    
    # this predicts the high and low using the mPredict and mConfInt Variable, the confidence level is judged.
    fcast <- forecast(ets1, h = input$mPredict, level = input$confInt)
    

    # Create the linear mode
    Model <- lm(lineardata[,1]~., data = train)

    # prediction in linear model
    pred <- predict(Model, test)
    # this gives the error
    errIndex <- fcast$lower > ts1Test | fcast$upper < ts1Test 

    rmse <- sqrt(mean(pred-lineardata[,1])^2)
    
    return(list(ts = ts1, tsTrain = ts1Train, tsTest = ts1Test, ets = ets1, fcast = fcast, errIndex = errIndex, linearPred = pred, linearRMSE = rmse)) 
  })

  # here the stockPlot variable is created which is finally rendered on the UI 
  output$stockPlot <- renderPlot({
     
     stockData <- dataInput() # returns list with monthly stock data, train/test split, exp smoothing model and forecast 
     colInd <- rep("green", input$mPredict)
     colInd[stockData$errIndex] <- "red"
     
    #  this is the plot with the main heading, x and y labels and forecast data.
     plot(stockData$fcast, 
          main = paste0(input$mPredict, "M close price forecast for ", input$symb),
          xlab = "Years",
          ylab = "Stock price, USD")
     lines(stockData$tsTest, col="black")
     points(stockData$tsTest, col = colInd)
     
  })
  
  # this output the root mean square error and the error rate per data.
  output$stockText <- renderText({
     
     stockData <- dataInput()
     
     RMSE <- sqrt(mean((stockData$fcast$mean - stockData$tsTest)^2))
     errRate <- sum(stockData$errIndex) / length(stockData$errIndex)
     
     paste0("RMSE of prediction is ", round(RMSE,2), " and Error rate is ", round(errRate*100,2),"%")
  })
  
  output$linearPlot <- renderPlot({
    stockData <- dataInput()
    plot(stockData$linearPred, type="l", lty=1.8, col="blue", main = paste0(input$mPredict, "M close price forecast for ", input$symb),
          xlab = "Years",
          ylab = "Stock price, USD")
  })

  output$linearText <- renderText({
    stockData <- dataInput()
    paste0("RMSE of prediction is ", round(stockData$linearRMSE))
  })
  
})
