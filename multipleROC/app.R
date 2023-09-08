#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(multipleROC)
data(radial,package="moonBook")



# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("ROC courve by multipleROC package"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
             selectInput("dep","Dependent Variable",choices=colnames(radial),selected="male"),
             selectInput("pred","Predictors:",choices=colnames(radial),multiple=TRUE)

        ),

        # Show a plot of the generated distribution
        mainPanel(
             verbatimTextOutput("text1"),
           plotOutput("plot1")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output,session) {
    observe({
         choices1=setdiff(colnames(radial),input$dep)
         updateSelectInput(session,"pred",choices=choices1)

    })



     output$text1=renderPrint({
          if(length(input$pred)>0){
          equation=paste(input$dep,"~",paste0(input$pred,collapse="+"))
             cat(equation)
          } else{
               cat("Please select one or more predictor variable(s)")
          }
     })
    output$plot1 <- renderPlot({
         if(length(input$pred)>0){
         equation=paste(input$dep,"~",paste0(input$pred,collapse="+"))
         multipleROC(as.formula(equation),data=radial,plot=TRUE)
         }
    })
}

# Run the application
shinyApp(ui = ui, server = server)
