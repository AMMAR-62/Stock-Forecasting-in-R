# shiny is used to build the UI.
library(shiny)

# this is the ui part of the shiny hence the function shinyUI is used.
shinyUI(fluidPage(
  # title for the page - like a navbar.
  titlePanel("Stock Price Predictions"),
  
  # this will stay at the side.
  sidebarLayout(

    sidebarPanel(
      helpText("Select a stock to examine. 
        Information will be collected from yahoo finance. ", 
              #  a("Stock symbols lookup", href = "http://finance.yahoo.com/lookup")
        ),

      # textinput - this will pass to the server in the backend.
      textInput("symb", "Symbol", "SPY"),
#       selectInput("symb", "Symbol",choices=stockSymbols(
#   exchange = c("AMEX", "NASDAQ", "NYSE", "ARCA", "BATS", "IEX"),
#   sort.by = c("Exchange", "Symbol"),
#   quiet = FALSE
# ), selected = "SPY"),

      # this is the line break.
      br(),
      
      # this declares the mLearn Variable which has the label "Learning Depth (months)"
      # the min and max value of the slider is specified and the initial value of the slider is given as 3 years.
      sliderInput("mLearn", h4("Learning depth (months)"),
                  min = 30, max = 60, value = 36),
      
      # this is the break line.
      br(),      

      # this is the mPredict variable which has the label "Prediction horizon(months)"
      # the min and mx value of the slider is specified and the initial value of the slider is 1 year.
      sliderInput("mPredict", h4("Prediction horizon (months)"),
                  min = 1, max = 24, value = 12),
      
      # this is the break line.
      br(),      
      
      # this is the confidence interval specifically to show the possible deviation from the predicted mean.
      sliderInput("confInt", h4("Confidence interval (%)"),
                  min = 1, max = 99, value = 95),
      
      # this is the break line.
      br(),
      
      # this is the submit button, which is used to refresh the page, and send the data to server.
      submitButton("Update Plot", icon("refresh"))
      
    ),
    
    # this is the middle panel
    mainPanel(
      # paragraph gives an introduction about the app.
      # RMSE - (root mean square error)
       p("Basic idea of this application is to develop prediction of chosen 
         stock price for the selected number of months preceding the date of 
         use. This period is used to test accuracy of prediction. The user 
         is allowed to chose the length of learning horizon (which is certain 
         amount of months preceding the test period) and width of prediction 
         confidence interval. The accuracy of prediction can be analyzed on 
         the plot provided as well as based on RMSE and error rate (the share 
         of data points in test period which are out of prediction confidence 
         interval). The app is based on the time series analysis method 
         (exponential smoothing) which is part of ", 
        #  emphasis tag
       em("forecast"), 
       "R package. 
         One can further use this application to try develop stock investment 
         strategies."), 
       
       p(strong("NOTE:"), "Please note that changes to user 
         controls will only affect the outcomes after Update Plot button is pushed."),
       
      #  the stockPlot is plotted here.
       plotOutput("stockPlot"),
      #  the stocktext which shows the RMSE error is also shown.
       textOutput("stockText"),
       plotOutput("linearPlot"),
      #  the stocktext which shows the RMSE error is also shown.
       textOutput("linearText")
    )
  )
))