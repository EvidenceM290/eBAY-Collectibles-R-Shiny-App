# Load required libraries
library(shiny)
library(shinythemes)
library(DT)
library(shinyjs)
library(RMariaDB)
library(digest)
library(ggplot2)
library(plotly)
library(prophet)
library(reticulate)




#---------------------------------------------------------------------------------------------------------------------------------

# Create virtual environment
virtualenv_create("sqlchat")

# Install Python packages
virtualenv_install("sqlchat", packages = c(
  "langchain",
  "langchain-community",
  "langchain-openai",
  "langgraph",
  "faiss-cpu",
  "Ipykernel",
  "mysql-connector-python"
))

use_virtualenv("sqlchat", required = TRUE)
#---------------------------------------------------------------------------------------------------------------------------------
# Load Python functions for AI-powered SQL
tryCatch({
  py_run_string("
import os
from langchain_community.utilities import SQLDatabase
from langchain_openai import ChatOpenAI
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Set API key and initialize LLM
api_key = 'x9C5lx5SgaQ0dtBMA'  # Replace with your OpenAI API key
llm = ChatOpenAI(model='gpt-4', api_key=api_key)

# Define the function to generate SQL
def generate_sql(question):
    schema = '''Users Table:
- UserID: INT, Primary Key
- Username: VARCHAR(50)
- Email: VARCHAR(100), Unique
- PasswordHash: VARCHAR(255)
- UserType: ENUM('buyer', 'seller')
- Rating: DECIMAL(3, 2)
- RegistrationDate: DATETIME

Items Table:
- ItemID: INT, Primary Key
- ItemName: VARCHAR(100)
- Category: ENUM('Video Games', 'Trading Cards', 'Comics', 'Funko Pops', 'LEGO Sets', 'Coins', 'Sports Cards')
- Description: TEXT
- ItemCondition: ENUM('New', 'Used', 'Mint', 'Good')
- Price: DECIMAL(10, 2)
- ListDate: DATETIME
- VerificationStatus: ENUM('pending', 'verified', 'rejected')

Transactions Table:
- TransactionID: INT, Primary Key
- SellerID: INT (Foreign Key to Users.UserID)
- BuyerID: INT (Foreign Key to Users.UserID)
- ItemID: INT (Foreign Key to Items.ItemID)
- TransactionDate: DATETIME
- Price: DECIMAL(10, 2)

MarketData Table:
- MarketDataID: INT, Primary Key
- ItemID: INT (Foreign Key to Items.ItemID)
- PriceDate: DATE
- Price: DECIMAL(10, 2)

Verification Table:
- VerificationID: INT, Primary Key
- ItemID: INT (Foreign Key to Items.ItemID)
- VerificationStatus: ENUM('pending', 'verified', 'rejected')
- VerificationDate: DATETIME
- VerifiedBy: VARCHAR(100)

Reviews Table:
- ReviewID: INT, Primary Key
- ReviewerID: INT
- RevieweeID: INT
- Rating: DECIMAL(3, 2)
- ReviewText: TEXT
- ReviewDate: DATETIME

Collections Table:
- CollectionID: INT, Primary Key
- UserID: INT (Foreign Key to Users.UserID)
- CollectionName: VARCHAR(100)
- CreationDate: DATETIME

CollectionItems Table:
- CollectionItemID: INT, Primary Key
- CollectionID: INT (Foreign Key to Collections.CollectionID)
- ItemID: INT (Foreign Key to Items.ItemID)
- AddedDate: DATETIME
'''
    template = f\"\"\"Based on the schema below, write a SQL query that would answer the user's question:
{schema}

Write only the SQL query and nothing else. Do not wrap the SQL query in any other text, not even backticks.

For example:
Question: What are the 5 most expensive items in the database?
SQL Query: SELECT ItemName, Price FROM Items ORDER BY Price DESC LIMIT 5;

Question: Which buyers have purchased more than 10 items?
SQL Query: SELECT BuyerID, COUNT(*) AS PurchaseCount FROM Transactions GROUP BY BuyerID HAVING PurchaseCount > 10;


Question: {question}
SQL Query:\"\"\"
    response = llm.invoke(template)  # Generate SQL query
    return response.content.strip()
")
}, error = function(e) {
  stop("Python initialization failed: ", e$message)
})


#---------------------------------------------------------------------------------------------------
# Define UI
ui <- navbarPage(
  title = tags$div(
    style = "display: flex; align-items: center; font-size: 24px; font-weight: bold;",
    tags$span(style = "color: #e53238;", "e"),
    tags$span(style = "color: #0064d2;", "B"),
    tags$span(style = "color: #f5af02;", "a"),
    tags$span(style = "color: #86b817;", "y"),
    tags$span(" Collectibles", style = "color: #333;")
  ),
  theme = shinytheme("flatly"),
  id = "main_navbar",
  
  # Add dynamic user actions (My Account and Logout)
  header = tags$div(
    uiOutput("user_actions"),
    style = "position: absolute; top: 10px; right: 20px; z-index: 1000;"
  ),
  
  # Styling for the navbar
  tags$head(
    tags$style(HTML("
      .navbar-default {
        background-color: white !important;
        border-bottom: 2px solid #ddd !important;
      }
      .navbar-default .navbar-nav > li > a {
        color: #555 !important;
      }
      .navbar-default .navbar-nav > li > a:hover {
        background-color: #f5f5f5 !important;
        color: #000 !important;
      }
      .navbar-default .navbar-brand {
        color: #555 !important;
      }
      .navbar-default .navbar-brand:hover {
        color: #000 !important;
      }
      .navbar-default .navbar-nav > .active > a, 
      .navbar-default .navbar-nav > .active > a:focus, 
      .navbar-default .navbar-nav > .active > a:hover {
        background-color: #ebebeb !important;
        color: #000 !important;
      }
      
      .btn-primary {
        background-color: #3665f3 !important;
        border-color: #3665f3 !important;
        color: white !important;
      }
      .btn-primary:hover {
        background-color: #382aef !important;
        border-color: #382aef !important;
        color: white !important;
      }
      
      .btn-danger {
        background-color: #d9534f !important; /* Bootstrap's red button color */
        border-color: #d43f3a !important;
        color: white !important;
      }
      .btn-danger:hover, .btn-danger:focus, .btn-danger:active {
        background-color: #c9302c !important; /* Darker red for hover/active state */
        border-color: #ac2925 !important;
        color: white !important;
      }
    "))
  ),
  
  # Add dynamic user actions (My Account and Logout)
  tags$div(
    uiOutput("user_actions"),
    style = "position: absolute; top: 10px; right: 20px; z-index: 1000;"
  ),
  
  # Add CSS styles here
  tags$style(HTML("
.profile-card {
  background: linear-gradient(to bottom right, #f2f2f2, #ffffff);
  border-radius: 12px;
  padding: 25px;
  max-width: 450px;
  margin: auto;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
  border: 1px solid #ddd;
}

.profile-header {
  text-align: center;
  margin-bottom: 20px;
}

.profile-header img {
  border-radius: 50%;
  height: 90px;
  width: 90px;
  object-fit: cover;
  border: 4px solid #007BFF; /* eBay blue */
}

.profile-info p {
  margin: 0;
  display: flex;
  justify-content: space-between;
  font-family: 'Roboto', sans-serif;
  font-size: 16px;
  color: #333;
}

.profile-info .label {
  font-weight: bold;
  color: #555;
  margin-right: 10px;
  min-width: 150px;
  text-align: right;
}

.profile-info .value {
  font-weight: normal;
  color: #333;
  margin-left: 10px;
  text-align: left;
  flex-grow: 1;
}

.profile-info h4 {
  margin: 0;
  color: #007BFF; /* eBay blue */
}

.profile-info .label {
  font-weight: bold;
  color: #555;
  margin-right: 5px;
}

.profile-info p {
  margin: 0 0 8px;
}

.action-buttons {
  margin-top: 15px;
  display: flex;
  justify-content: center;
  gap: 10px;
}

.action-buttons button {
  background-color: #007BFF; /* eBay blue */
  color: #fff;
  border: none;
  padding: 10px 20px;
  border-radius: 5px;
  font-size: 14px;
  font-weight: bold;
  cursor: pointer;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  transition: background-color 0.3s ease;
}

.action-buttons button:hover {
  background-color: #0056b3; /* Darker blue */
}


  ")),
  
#-------------------------------------------------------------------------------------------------------  
# Main Tabs
tabPanel("Analytics Dashboard",
         fluidPage(
           h3("Prices for Video Games, Cards, Comics & More"),
           h4("Price Guides, Collection Trackers & Tools for Collectors"),
           fluidRow(
             column(6, 
                    tags$div(
                      textInput("item_selector", NULL, 
                                placeholder = "Search by Product, for specific trends"),
                      style = "width: 400px;"
                    ),
                    uiOutput("suggestion_box"),
                    textOutput("current_price"),
                    actionButton("estimate_price", "Predict Price", class = "btn-primary"),
                    textOutput("price_estimate"),
                    tags$div(style = "margin-top: 20px;",
                             tags$small(
                               tags$em("Disclaimer: Future prices are based on trends. Buyers and Sellers assume their own risk.")
                             ))
             ),
             column(8,
                    plotlyOutput("price_trends")
             )
           )
         )),
#-------------------------------------------------------------------------------------------------------    
#Manage Listings Tab
tabPanel("Manage Listings",
         fluidPage(
           h3("Manage Listings"),
           
           # Add JavaScript for handling delete button clicks
           tags$script(HTML("
             $(document).on('click', '.delete-btn', function() {
               var itemId = $(this).data('id');
               Shiny.setInputValue('delete_item', itemId, {priority: 'event'});
             });
           ")),
           
           # Main Layout: Two Columns
           fluidRow(
             # Add Item Section
             column(4,
                    h4("Sell an Item"),
                    textInput("item_name", "Item Name:", placeholder = "Enter item name"),
                    textAreaInput("item_description", "Description:", placeholder = "Enter item description", rows = 3),
                    numericInput("item_price", "Price:", value = 0, min = 0, step = 0.01),
                    selectInput("item_condition", "Condition:", c("New", "Used", "Refurbished")),
                    selectInput("item_category", "Category:", c("Video Games", "Trading Cards", "Comics", "Funko Pops", "LEGO Sets", "Coins", "Sports Cards")),
                    actionButton("add_item_button", "List Item", class = "btn-primary")
             ),
             
             # Listings and Purchases Section
             column(8,
                    fluidRow(
                      column(12,
                             h4("Your Listings"),
                             DTOutput("listings_table")
                      )
                    ),
                    fluidRow(
                      column(12,
                             h4("Your Purchases"),
                             DTOutput("purchases_table")
                      )
                    )
             )
           )
         ))

,

#-------------------------------------------------------------------------------------------------------     
# Personal Collection Tab
tabPanel("Personal Collection",
         fluidPage(
           h3("Personal Collection"),
           fluidRow(
             column(4,
                    tags$div(
                      textInput("search_collection", "Search by Collection Name:", placeholder = "Enter collection name"),
                      style = "width: 400px; margin-bottom: 10px;"
                    ),
                    tags$div(
                      textInput("search_category", "Search by Category:", placeholder = "Enter category"),
                      style = "width: 400px; margin-bottom: 10px;"
                    ),
                    tags$div(
                      textInput("search_item", "Search by Item Name:", placeholder = "Enter item name"),
                      style = "width: 400px; margin-bottom: 10px;"
                    ),
                    h4("Create a New Collection"),
                    textInput("new_collection_name", "Collection Name:", placeholder = "Enter a new collection name"),
                    actionButton("create_collection_button", "Create Collection", class = "btn-primary"),
                    tags$hr(style = "margin-top: 20px;"
                    ),                    
                    h4("Quick Add Item to Collection"),
                    textInput("quick_add_item", "Search for an Item:", placeholder = "Type to search..."),
                    uiOutput("quick_add_suggestions"),
                    selectInput("quick_add_collection", "Select a Collection:", choices = NULL),
                    actionButton("add_to_collection", "Add to Collection", class = "btn-primary"),
                    
                    tags$div(
                      h4("Delete a Collection"),
                      selectInput("delete_collection", "Select a Collection:", choices = NULL),
                      actionButton("delete_collection_button", "Delete Collection", class = "btn-danger"),
                      tags$hr(style = "margin-top: 20px;")
                    ),
                    
             ),
             column(8,
                    fluidRow(
                      column(12,
                             h4("Cumulative Value Trend Line"),
                             plotlyOutput("collection_trend_plot")
                      )
                    ),
                    h4("Total Collection Value: $"),
                    textOutput("total_value"),
                    DTOutput("collection_table")
             )
           )
         )
),
#-------------------------------------------------------------------------------------------------------    

#Market Overview Tab
tabPanel("Market Overview",
         fluidPage(
           h3("Market Overview"),
           p("See market trends and item pricing data."),
           tags$script(HTML("
  $(document).on('click', '.add-to-collection-btn', function() {
    var itemId = $(this).data('id');
    Shiny.setInputValue('selected_item', itemId, {priority: 'event'});
  });
")),
           
           DTOutput("market_data")
         )),
#-------------------------------------------------------------------------------------------------------------------------------------   

#eBay Lot Bot
tabPanel(
  "eBay Lot Bot",
  fluidPage(
    sidebarLayout(
      sidebarPanel(
        textInput("chat_question", "What do you want to know ?:", placeholder = "e.g., Show the top 5 most expensive items."),
        actionButton("generate_chat_sql", "Generate SQL Query", class = "btn-primary"),
        div(class = "output-box", verbatimTextOutput("chat_generated_sql")),
        verbatimTextOutput("no_data_message")
      ),
      mainPanel(
        h3("Query Results"),
        DTOutput("chat_query_results")
      )
    )
  )
),

#---------------------------------------------------------------------------------------------------------------------------------

# Login Tab
  tabPanel("Login", value = "login",
           fluidPage(
             h3("Log In"),
             fluidRow(
               column(6,
                      textInput("login_email", "Email:", placeholder = "Your email address"),
                      passwordInput("login_password", "Password:", placeholder = "Your password"),
                      actionButton("login_button", "Log In", class = "btn-primary"),
                      tags$a("Forgot my password?", href = "#", style = "color: blue; margin-top: 10px; display: block;")
               )
             )
           )),

#-------------------------------------------------------------------------------------------------------      
  # Create Account Tab
  tabPanel("Create Account", value = "create_account",
           fluidPage(
             h3("Create A Free Account Today"),
             h4("Track your collection value, ad-free browsing & more"),
             fluidRow(
               column(6,
                      textInput("signup_username", "Username:", placeholder = "Your Username"),
                      textInput("signup_email", "Email:", placeholder = "Your email address"),
                      passwordInput("signup_password", "Password:", placeholder = "6+ character password"),
                      actionButton("signup_button", "Create Account", class = "btn-primary", 
                                   style = "margin-top: 10px; background-color: orange; color: white; font-weight: bold;"),
                      tags$div(style = "margin-top: 10px;",
                               actionLink("go_to_login", "Already have an account? Log in", 
                                          style = "color: blue; cursor: pointer; text-decoration: underline;"))
               )
             )
           )),

#-------------------------------------------------------------------------------------------------------      
  # My Account Tab
tabPanel("My Account", value = "my_account",
         fluidPage(
           h3("My Account Details", style = "text-align: center; color: #007BFF;"),
           div(class = "profile-card",
               div(class = "profile-header",
                   img(src = "https://via.placeholder.com/90", alt = "Profile Picture"),
                   h4(textOutput("profile_username"))
               ),
               div(class = "profile-info",
                   fluidRow(
                     column(6, p(class = "label", "Email:")),
                     column(6, p(class = "value", textOutput("profile_email")))
                   ),
                   fluidRow(
                     column(6, p(class = "label", "User Type:")),
                     column(6, p(class = "value", textOutput("profile_user_type")))
                   ),
                   fluidRow(
                     column(6, p(class = "label", "Rating:")),
                     column(6, p(class = "value", textOutput("profile_rating")))
                   ),
                   fluidRow(
                     column(6, p(class = "label", "Registration Date:")),
                     column(6, p(class = "value", textOutput("profile_registration_date")))
                   )
               ),
               div(class = "action-buttons", style = "margin-top: 20px; text-align: center;",
                   actionButton("edit_account", "Edit Profile", class = "btn-primary", style = "margin-right: 10px;"),
                   actionButton("log_out", "Log Out", class = "btn-danger")
               )
           )
         ))




)


#-------------------------------------------------------------------------------------------------------------------------------------    
# Define Server Logic
server <- function(input, output, session) {
  useShinyjs()
  
  # Database connection
  connect_to_db <- function() {
    tryCatch({
      conn <- dbConnect(RMariaDB::MariaDB(),
                        host = "ryanadjapong.clogay4kuwnd.us-east-2.rds.amazonaws.com",
                        port = 3306,
                        dbname = "eBayCollectibles",
                        user = "DrRyan",
                        password = "NAnakwame1986")
      if (!dbIsValid(conn)) stop("Invalid database connection.")
      conn
    }, error = function(e) {
      stop(paste("Database connection error:", e$message))
    })
  }
 
#-------------------------------------------------------------------------------------------------------------------------------------
  # Mock user data (to be replaced with actual data from database)
  user_data <- reactiveValues(
    username = "",
    email = "",
    user_type = "",
    rating = "",
    registration_date = ""
  )
  
  
  
  # Output current profile details
  output$profile_username <- renderText({ user_data$username })
  output$profile_email <- renderText({ user_data$email })
  output$profile_user_type <- renderText({ user_data$user_type })
  output$profile_rating <- renderText({ user_data$rating })
  output$profile_registration_date <- renderText({ user_data$registration_date })
  
  # Edit profile modal
  observeEvent(input$edit_account, {
    showModal(modalDialog(
      title = "Edit Profile",
      textInput("edit_username", "Username:", value = user_data$username),
      textInput("edit_email", "Email:", value = user_data$email),
      textInput("edit_user_type", "User Type:", value = user_data$user_type),
      numericInput("edit_rating", "Rating:", value = as.numeric(user_data$rating), min = 0, max = 5, step = 0.1),
      dateInput("edit_registration_date", "Registration Date:", value = user_data$registration_date),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("save_profile", "Save", class = "btn-primary")
      )
    ))
  })
  
  # Save edited profile details
  observeEvent(input$save_profile, {
    conn <- connect_to_db()
    tryCatch({
      # Ensure reactive values are updated before saving
      user_data$username <- input$edit_username
      user_data$email <- input$edit_email
      user_data$user_type <- input$edit_user_type
      user_data$rating <- as.character(input$edit_rating)
      user_data$registration_date <- as.character(input$edit_registration_date)
      
      query <- "UPDATE Users 
              SET Username = ?, Email = ?, UserType = ?, Rating = ?, RegistrationDate = ? 
              WHERE Email = ?"
      dbExecute(conn, query, params = list(
        user_data$username,
        user_data$email,
        user_data$user_type,
        user_data$rating,
        user_data$registration_date,
        user_data$email
      ))
      showNotification("Profile updated successfully!", type = "message")
    }, error = function(e) {
      message("Error updating profile: ", e$message)
      showNotification(paste("Failed to update profile:", e$message), type = "error")
    }, finally = {
      dbDisconnect(conn)
    })
    
    removeModal()
  })
  
  
  #-------------------------------------------------------------------------------------------------------------------------------------  
  # Generate SQL and fetch results for the LLM
  observeEvent(input$generate_chat_sql, {
    tryCatch({
      # Get user question
      question <- input$chat_question
      print(paste("User Question:", question))
      
      # Generate SQL using Python function
      py_run_string(paste0("query = generate_sql('", question, "')"))
      generated_sql <- py$`query`
      print(paste("Generated SQL Query:", generated_sql))
      
      # Connect to database and fetch results
      db <- connect_to_db()
      on.exit(dbDisconnect(db))
      data <- dbGetQuery(db, generated_sql)
      
      # Check if the query returned empty results
      if (nrow(data) == 0) {
        output$chat_generated_sql <- renderText({ generated_sql })
        output$no_data_message <- renderText({ "No data found matching the query." })
        output$chat_query_results <- renderDT(data.frame(Error = "No data to display."))
      } else {
        # Display generated SQL and results
        output$chat_generated_sql <- renderText({ generated_sql })
        output$no_data_message <- renderText({ "" })  # Clear no-data message
        output$chat_query_results <- renderDT({
          datatable(data, options = list(pageLength = 5, scrollX = TRUE))
        })
      }
    }, error = function(e) {
      # Handle errors gracefully
      print("Error during SQL query execution.")
      output$chat_generated_sql <- renderText({ "Error generating SQL or executing query." })
      output$no_data_message <- renderText({ "An error occurred while processing your query." })
      output$chat_query_results <- renderDT(data.frame(Error = "No data to display."))
    })
  })
  
  #---------------------------------------------------------------------------------------------------------------------------------
  
  
  # Reactive value to store user login state
  user <- reactiveVal(NULL)
  
  # Navigate to Login tab when actionLink is clicked
  observeEvent(input$go_to_login, {
    updateNavbarPage(session, "main_navbar", selected = "login")
  })
  
  
  # Login UI
  output$login_ui <- renderUI({
    if (is.null(user())) {
      fluidRow(
        column(4,
               textInput("login_email", "Email:", placeholder = "Enter your email"),
               passwordInput("login_password", "Password:", placeholder = "Enter your password"),
               actionButton("login_button", "Login", class = "btn-primary")
        )
      )
    } else {
      fluidRow(
        h4(paste("Welcome,", user()$Username, "(", user()$UserType, ")")),
        actionButton("logout_button", "Logout", class = "btn-danger")
      )
    }
  })
  
  # Signup UI
  output$signup_ui <- renderUI({
    if (is.null(user())) {
      fluidRow(
        column(4,
               textInput("signup_username", "Username:", placeholder = "Choose a username"),
               textInput("signup_email", "Email:", placeholder = "Enter your email"),
               passwordInput("signup_password", "Password:", placeholder = "Choose a password"),
               selectInput("signup_user_type", "Account Type:", choices = c("admin", "seller", "buyer")),
               actionButton("signup_button", "Sign Up", class = "btn-primary")
        )
      )
    }
  })
  
#-------------------------------------------------------------------------------------------------------------------------------------   
  # Login functionality
  observeEvent(input$login_button, {
    req(input$login_email, input$login_password)
    
    db <- connect_to_db()
    on.exit({
      if (dbIsValid(db)) dbDisconnect(db)
    })
    
    query <- "SELECT UserID, Username, Email FROM Users WHERE Email = ? AND PasswordHash = ?"
    hashed_password <- digest(input$login_password, algo = "sha256")
    
    tryCatch({
      user_data <- dbGetQuery(db, query, params = list(input$login_email, hashed_password))
      
      if (nrow(user_data) > 0) {
        # Populate the user object with all necessary details
        user(list(
          UserID = user_data$UserID[1],
          email = user_data$Email[1],
          name = user_data$Username[1]
        ))
        
        updateNavbarPage(session, "main_navbar", selected = "Analytics Dashboard")
        showNotification("Login successful!", type = "message")
      } else {
        showNotification("Invalid email or password. Please try again.", type = "error")
      }
    }, error = function(e) {
      print(paste("Database query error:", e$message))
      showNotification("Error during login. Please try again later.", type = "error")
    })
  })
  
  
  # Logout functionality
  observeEvent(input$logout, {
    user(NULL)
    updateNavbarPage(session, "main_navbar", selected = "login")
    showNotification("You have logged out.", type = "message")
  })
  
#------------------------------------------------------------------------------------------------------------------------------------- 
  # Populate "My Account" tab
  tabPanel("My Account", value = "my_account",
           fluidPage(
             tags$style(HTML("
             .profile-card {
               background: #f9f9f9;
               border-radius: 10px;
               padding: 20px;
               max-width: 400px;
               margin: auto;
               box-shadow: 0px 4px 6px rgba(0, 0, 0, 0.1);
             }
             .profile-header {
               text-align: center;
               margin-bottom: 20px;
             }
             .profile-header img {
               border-radius: 50%;
               height: 80px;
               width: 80px;
               object-fit: cover;
               border: 3px solid #007BFF;
             }
             .profile-info {
               font-family: Arial, sans-serif;
               font-size: 16px;
               line-height: 1.6;
             }
             .profile-info h4 {
               margin: 0;
               color: #007BFF;
             }
             .profile-info .label {
               font-weight: bold;
               color: #555;
             }
           ")),
             div(class = "profile-card",
                 div(class = "profile-header",
                     img(src = "https://via.placeholder.com/80", alt = "Profile Picture"),
                     h4(textOutput("profile_username"))
                 ),
                 div(class = "profile-info",
                     p(span(class = "label", "Email: "), textOutput("profile_email")),
                     p(span(class = "label", "User Type: "), textOutput("profile_user_type")),
                     p(span(class = "label", "Rating: "), textOutput("profile_rating")),
                     p(span(class = "label", "Registration Date: "), textOutput("profile_registration_date"))
                 )
             )
           ))
  
  
  # Signup functionality
  observeEvent(input$signup_button, {
    req(input$signup_username, input$signup_email, input$signup_password)
    
    db <- connect_to_db()
    if (is.null(db)) return()
    on.exit(dbDisconnect(db))
    
    query <- "INSERT INTO Users (Username, Email, PasswordHash) VALUES (?, ?, ?)"
    hashed_password <- digest(input$signup_password, algo = "sha256")
    
    tryCatch({
      dbExecute(db, query, params = list(input$signup_username, input$signup_email, hashed_password))
      showNotification("Account created successfully!", type = "message")
    }, error = function(e) {
      showNotification("Error creating account: Email may already be in use.", type = "error")
      updateNavbarPage(session, "main_navbar", selected = "login")
    })
  })
  
  #-------------------------------------------------------------------------------------------------------------------------------------   
  # Reactive value to store user login state
  #Render dynamic user actions (Logout and My Account)
  output$user_actions <- renderUI({
    if (is.null(user())) {
      tagList(
        actionLink("go_to_login", "Login", style = "margin-right: 15px; font-weight: bold; color: blue;"),
        tags$a("Create Account", href = "#create_account", style = "font-weight: bold; color: orange;")
      )
    } else {
      tagList(
        tags$span(paste("Welcome,", user()$name), style = "margin-right: 15px; color: black;"),
        tags$a("My Account", href = "#my_account", style = "margin-right: 15px; font-weight: bold; color: blue;"),
        actionLink("logout", "Logout", style = "font-weight: bold; color: red; cursor: pointer;")
      )
    }
  })
  
  #------------------------------------------------------------------------------------------------------------------------------------- 
  # Reactive value to store user login state
  #Render dynamic user actions (Logout and My Account)
  output$user_actions <- renderUI({
    if (is.null(user())) {
      tagList(
        actionLink("go_to_login", "Login", style = "margin-right: 15px; font-weight: bold; color: blue;"),
        tags$a("Create Account", href = "#create_account", style = "font-weight: bold; color: orange;")
      )
    } else {
      tagList(
        tags$span(paste("Welcome,", user()$name), style = "margin-right: 15px; color: black;"),
        tags$a("My Account", href = "#my_account", style = "margin-right: 15px; font-weight: bold; color: blue;"),
        actionLink("logout", "Logout", style = "font-weight: bold; color: red; cursor: pointer;")
      )
    }
  })
  
  #------------------------------------------------------------------------------------------------------------------------------------- 
  #Navigate to Login tab when "Log In" actionLink is clicked
  observeEvent(input$go_to_login, {
    updateNavbarPage(session, "main_navbar", selected = "login")
  })
  
  #------------------------------------------------------------------------------------------------------------------------------------- 
  # Reactive value to store user login state
  user <- reactiveVal(NULL)
  
  # Helper function to check if the user is authorized
  is_logged_in <- reactive({
    !is.null(user())
  })
  
  # Dynamically show/hide tabs based on login state
  observe({
    if (is_logged_in()) {
      # Tabs for logged-in users
      showTab(inputId = "main_navbar", target = "Market Overview")
      showTab(inputId = "main_navbar", target = "Analytics Dashboard")  # General trends
      showTab(inputId = "main_navbar", target = "Personal Collection")  # User-specific trends
      hideTab(inputId = "main_navbar", target = "login")
      hideTab(inputId = "main_navbar", target = "create_account")
      showTab(inputId = "main_navbar", target = "Manage Listings")
      showTab(inputId = "main_navbar", target = "my_account")
    } else {
      
      # Tabs for general (non-logged-in) users
      showTab(inputId = "main_navbar", target = "Market Overview")
      showTab(inputId = "main_navbar", target = "Analytics Dashboard")
      showTab(inputId = "main_navbar", target = "Login/Sign Up")
      hideTab(inputId = "main_navbar", target = "Manage Listings")
      hideTab(inputId = "main_navbar", target = "Personal Collection")
      hideTab(inputId = "main_navbar", target = "my_account")
    }
  })
  
  #-------------------------------------------------------------------------------------------------------------------------------------  
  # Logout functionality
  observeEvent(input$logout_button, {
    user(NULL)
    showNotification("You have logged out.", type = "message")
  })
  
  #------------------------------------------------------------------------------------------------------------------------------------- 
  # Analytics Dashboard General Trends
  general_trends <- reactive({
    db <- connect_to_db()
    on.exit(dbDisconnect(db))
    
    query <- "SELECT ListDate, AVG(Price) as AvgPrice FROM Items GROUP BY ListDate ORDER BY ListDate"
    dbGetQuery(db, query)
  })
  
  # Render General Trends by Default
  output$price_trends <- renderPlotly({
    data <- general_trends()
    data$ListDate <- as.Date(data$ListDate)
    
    plot <- ggplot(data, aes(x = ListDate, y = AvgPrice)) +
      geom_line(color = "#0064D2", size = 0.5) +
      geom_point(color = "#E53238", size = 2) +
      labs(title = "General Price Trends",
           x = "Date", y = "Average Price ($)") +
      theme_minimal()
    
    ggplotly(plot) %>% layout(hovermode = "x unified")
  })
  
  # Dynamic Suggestions
  output$suggestion_box <- renderUI({
    req(input$item_selector)
    
    db <- connect_to_db()
    on.exit(dbDisconnect(db))
    
    query <- "SELECT DISTINCT ItemName FROM Items WHERE ItemName LIKE ? ORDER BY ItemName LIMIT 5"
    suggestions <- dbGetQuery(db, query, params = list(paste0("%", input$item_selector, "%")))
    
    if (nrow(suggestions) > 0) {
      tagList(
        tags$ul(
          lapply(suggestions$ItemName, function(item) {
            tags$li(item, style = "cursor: pointer;", onclick = sprintf("$('#item_selector').val('%s').trigger('input');", item))
          }),
          style = "list-style-type: none; padding-left: 0; margin-top: 10px;"
        )
      )
    } else {
      NULL
    }
  })
  
  # Search Functionality
  observeEvent(input$item_selector, {
    if (input$item_selector == "") {
      # Render General Trends if Search Bar is Empty
      data <- general_trends()
      data$ListDate <- as.Date(data$ListDate)
      
      plot <- ggplot(data, aes(x = ListDate, y = AvgPrice)) +
        geom_line(color = "#0064D2", size = 0.5) +
        geom_point(color = "#E53238", size = 0.2) +
        labs(title = "General Price Trends",
             x = "Date", y = "Average Price ($)") +
        theme_minimal()
      
      output$price_trends <- renderPlotly({
        ggplotly(plot) %>% layout(hovermode = "x unified")
      })
      output$current_price <- renderText("")
      return()
    }
    
    db <- connect_to_db()
    on.exit(dbDisconnect(db))
    
    query <- "SELECT ListDate, Price FROM Items WHERE ItemName = ? ORDER BY ListDate"
    data <- dbGetQuery(db, query, params = list(input$item_selector))
    data$ListDate <- as.Date(data$ListDate)
    
    if (nrow(data) > 0) {
      output$current_price <- renderText({
        paste("Current Price: $", round(data$Price[nrow(data)], 2))
      })
      
      plot <- ggplot(data, aes(x = ListDate, y = Price)) +
        geom_line(color = "#0064D2", size = 0.5) +
        geom_point(color = "#E53238", size = 0.2) +
        labs(title = paste("Price Trends for", input$item_selector),
             x = "Date", y = "Price ($)") +
        theme_minimal()
      
      output$price_trends <- renderPlotly({
        ggplotly(plot) %>% layout(hovermode = "x unified")
      })
    } else {
      output$current_price <- renderText("Current Price: No data available.")
    }
  })
  
  # Prediction with Prophet
  observeEvent(input$estimate_price, {
    withProgress(message = "Predicting future prices...", value = 0, {
      req(input$item_selector)
      
      db <- connect_to_db()
      on.exit(dbDisconnect(db))
      
      query <- "SELECT ListDate, Price FROM Items WHERE ItemName = ? ORDER BY ListDate"
      data <- dbGetQuery(db, query, params = list(input$item_selector))
      data$ListDate <- as.Date(data$ListDate)
      
      if (nrow(data) > 1) {
        incProgress(0.3, detail = "Preparing data...")
        
        # Aggregate to monthly averages
        data$Month <- format(data$ListDate, "%Y-%m")
        monthly_data <- aggregate(Price ~ Month, data, mean)
        monthly_data$ListDate <- as.Date(paste0(monthly_data$Month, "-01"))
        prophet_data <- data.frame(ds = monthly_data$ListDate, y = monthly_data$Price)
        
        model <- prophet(prophet_data)
        
        incProgress(0.3, detail = "Forecasting...")
        future <- make_future_dataframe(model, periods = 365 * 2, freq = "day")
        forecast <- predict(model, future)
        
        forecast_df <- forecast[c("ds", "yhat")]
        colnames(forecast_df) <- c("ListDate", "Price")
        
        output$price_estimate <- renderText({
          paste("Predicted Future Price: $", round(forecast_df$Price[nrow(forecast_df)], 2))
        })
        
        plot <- ggplot() +
          geom_line(data = data, aes(x = ListDate, y = Price), color = "#0064D2", size = 0.5) +
          geom_point(data = data, aes(x = ListDate, y = Price), color = "#E53238", size = 0.2) +
          geom_line(data = forecast_df, aes(x = as.Date(ListDate), y = Price), color = "#F5AF02", linetype = "dashed", size = 0.5) +
          labs(title = paste("Price Trends and 2-Year Forecast for", input$item_selector),
               x = "Date", y = "Price ($)") +
          theme_minimal()
        
        incProgress(0.4, detail = "Rendering graph...")
        
        output$price_trends <- renderPlotly({
          ggplotly(plot) %>% layout(hovermode = "x unified")
        })
      } else {
        output$price_estimate <- renderText("Not enough data to predict future prices.")
      }
    })
  })
  
  #-------------------------------------------------------------------------------------------------------------------------------------
  ### Manage Listings Section ###
  # Add a new item to the listings
  observeEvent(input$add_item_button, {
    req(input$item_name, input$item_description, input$item_price, input$item_condition, input$item_category)
    
    if (input$item_price <= 0) {
      showNotification("Price must be a positive number.", type = "error")
      return()
    }
    
    db <- connect_to_db()
    on.exit({
      if (dbIsValid(db)) dbDisconnect(db)
    })
    
    tryCatch({
      # Insert the new item into the Items table
      query_insert_item <- "
  INSERT INTO Items (ItemName, Description, Price, ItemCondition, Category, ListDate) 
  VALUES (?, ?, ?, ?, ?, NOW())"
      dbExecute(db, query_insert_item, params = list(
        input$item_name,
        input$item_description,
        input$item_price,
        input$item_condition,
        input$item_category
      ))
      
      # Retrieve the last inserted ItemID
      item_id <- dbGetQuery(db, "SELECT LAST_INSERT_ID() AS ItemID")$ItemID[1]
      
      # Insert a new transaction into the Transactions table
      query_insert_transaction <- "
  INSERT INTO Transactions (SellerID, ItemID, TransactionDate, Price) 
  VALUES (?, ?, NOW(), ?)"
      dbExecute(db, query_insert_transaction, params = list(
        user()$UserID,  # SellerID is the current logged-in user's UserID
        item_id,        # Use the ItemID from the previously inserted item
        input$item_price
      ))
      
      # Insert the initial verification status as 'PENDING' into the Verification table
      query_insert_verification <- "
  INSERT INTO Verification (ItemID, VerificationStatus) 
  VALUES (?, 'PENDING')"
      dbExecute(db, query_insert_verification, params = list(item_id))
      
      showNotification("Item and transaction added successfully!", type = "message")
      
      # Refresh Listings Table
      refresh_listings_table()
    }, error = function(e) {
      showNotification("Error adding item/transaction: Please try again.", type = "error")
      print(paste("Error:", e$message))  # Debugging log
    })
  })
  
  # Helper Function to Refresh Listings Table
  refresh_listings_table <- function() {
    db <- connect_to_db()
    on.exit({
      if (dbIsValid(db)) dbDisconnect(db)
    })
    
    query <- "
SELECT 
  i.ItemID AS 'Item ID',
  i.ItemName AS 'Item',
  v.VerificationStatus AS 'Verification Status',
  i.Price AS 'Price',
  t.TransactionDate AS 'Transaction Date'
FROM Transactions t
LEFT JOIN Items i ON t.ItemID = i.ItemID
LEFT JOIN Verification v ON i.ItemID = v.ItemID
WHERE t.SellerID = ?"
    
    listings <- dbGetQuery(db, query, params = list(user()$UserID))
    
    # Format the date column to M/d/yy format
    if (!is.null(listings$`Transaction Date`)) {
      listings$`Transaction Date` <- format(as.Date(listings$`Transaction Date`), "%m/%d/%y")
    }
    
    # Add a delete button for each row
    if ("Item ID" %in% colnames(listings)) {
      listings$Delete <- sprintf(
        '<button class="btn btn-danger btn-sm delete-btn" data-id="%s">Delete</button>',
        listings$`Item ID`
      )
    } else {
      stop("Item ID column is missing from listings data.")
    }
    
    # Render the table
    output$listings_table <- renderDT({
      datatable(
        listings[, -1],  # Exclude 'Item ID' column
        escape = FALSE,  # Allow HTML rendering for the buttons
        options = list(scrollX = TRUE),
        selection = "none"
      )
    })
  }
  
  # Helper Function to Refresh Purchases Table
  refresh_purchases_table <- function() {
    db <- connect_to_db()
    on.exit({
      if (dbIsValid(db)) dbDisconnect(db)
    })
    
    query <- "
SELECT 
  i.ItemID AS 'Item ID', 
  i.ItemName AS 'Item',
  v.VerificationStatus AS 'Verification Status',
  i.Price AS 'Price',
  t.TransactionDate AS 'Transaction Date'
FROM Transactions t
LEFT JOIN Items i ON t.ItemID = i.ItemID
LEFT JOIN Verification v ON i.ItemID = v.ItemID
WHERE t.BuyerID = ?"
    
    purchases <- dbGetQuery(db, query, params = list(user()$UserID))
    
    # Format the date column to M/d/yy format
    if (!is.null(purchases$`Transaction Date`)) {
      purchases$`Transaction Date` <- format(as.Date(purchases$`Transaction Date`), "%m/%d/%y")
    }
    
    # Add a delete button for each row
    if ("Item ID" %in% colnames(purchases)) {
      purchases$Delete <- sprintf(
        '<button class="btn btn-danger btn-sm delete-btn" data-id="%s">Delete</button>',
        purchases$`Item ID`
      )
    } else {
      stop("Item ID column is missing from purchases data.")
    }
    
    # Render the table
    output$purchases_table <- renderDT({
      datatable(
        purchases[, -1],  # Exclude 'Item ID' column
        escape = FALSE,  # Allow HTML rendering for the buttons
        options = list(scrollX = TRUE),
        selection = "none"
      )
    })
  }
  
  # Delete an item from the listings or purchases
  observeEvent(input$delete_item, {
    req(input$delete_item)  # Ensure an item ID is provided
    
    db <- connect_to_db()
    on.exit({
      if (dbIsValid(db)) dbDisconnect(db)
    })
    
    tryCatch({
      # Delete dependent rows in Transactions and Verification first
      dbExecute(db, "DELETE FROM Transactions WHERE ItemID = ?", params = list(input$delete_item))
      dbExecute(db, "DELETE FROM Verification WHERE ItemID = ?", params = list(input$delete_item))
      
      # Delete the item itself
      dbExecute(db, "DELETE FROM Items WHERE ItemID = ?", params = list(input$delete_item))
      
      # Notify the user
      showNotification("Item deleted successfully!", type = "message")
      
      # Refresh the tables
      refresh_listings_table()
      refresh_purchases_table()
    }, error = function(e) {
      showNotification("Failed to delete the item. Please try again.", type = "error")
      print(paste("Error:", e$message))  # Debugging log
    })
  })
  
  # Trigger Refresh for Listings and Purchases
  observe({
    req(user())
    refresh_listings_table()
    refresh_purchases_table()
  })
  
  #-------------------------------------------------------------------------------------------------------------------------------------
  
  ### Personal Collection ###
  
  # Prepare data for the trend line with cumulative sum
  collection_trend_data <- reactive({
    req(user())
    refresh_trigger()  # Trigger refresh when the collection updates
    
    data <- filtered_data()
    
    if (nrow(data) > 0) {
      # Use Added Date for aggregation
      data$AddedDate <- as.Date(data$`Added Date`)
      daily_data <- aggregate(Price ~ AddedDate, data, sum)
      daily_data <- daily_data[order(daily_data$AddedDate), ]  # Ensure data is sorted by date
      daily_data$CumulativeSum <- cumsum(daily_data$Price)  # Calculate cumulative sum
      return(daily_data)
    }
    return(data.frame(AddedDate = as.Date(character()), Price = numeric(), CumulativeSum = numeric()))
  })
  
  # Render trend line for personal collection with cumulative sum
  output$collection_trend_plot <- renderPlotly({
    trend_data <- collection_trend_data()
    
    if (nrow(trend_data) > 0) {
      plot <- ggplot(trend_data, aes(x = AddedDate, y = CumulativeSum)) +
        geom_line(color = "#0064D2", size = 1) +
        geom_point(color = "#E53238", size = 2) +
        labs(title = "Cumulative Value of Personal Collection Over Time",
             x = "Date", y = "Cumulative Total Value ($)") +
        theme_minimal()
      
      ggplotly(plot) %>% layout(hovermode = "x unified")
    } else {
      plot <- ggplot() +
        labs(title = "No Data Available for Trend Analysis",
             x = "", y = "") +
        theme_void()
      
      ggplotly(plot)
    }
  })
  
  
  # Reactive trigger for table refresh
  refresh_trigger <- reactiveVal(0)
  
  # Reactive data for filtered collections
  filtered_data <- reactive({
    refresh_trigger()  # Depend on the trigger to refresh the data
    req(user())
    
    db <- connect_to_db()
    on.exit({
      if (dbIsValid(db)) dbDisconnect(db)
    })
    
    query <- "
    SELECT 
        c.CollectionName AS 'Collection Name', 
        i.ItemName AS 'Item', 
        i.ItemCondition AS 'Item Condition',
        i.Category AS 'Category', 
        i.Price AS 'Price', 
        ci.AddedDate AS 'Added Date'
    FROM 
        Collections c
    JOIN 
        CollectionItems ci ON c.CollectionID = ci.CollectionID
    JOIN 
        Items i ON ci.ItemID = i.ItemID
    WHERE 
        c.UserID = ?"
    
    tryCatch({
      full_data <- dbGetQuery(db, query, params = list(user()$UserID))
      
      # Apply filters
      if (!is.null(input$search_collection) && input$search_collection != "") {
        full_data <- full_data[grepl(input$search_collection, full_data$`Collection Name`, ignore.case = TRUE), ]
      }
      if (!is.null(input$search_category) && input$search_category != "") {
        full_data <- full_data[grepl(input$search_category, full_data$Category, ignore.case = TRUE), ]
      }
      if (!is.null(input$search_item) && input$search_item != "") {
        full_data <- full_data[grepl(input$search_item, full_data$Item, ignore.case = TRUE), ]
      }
      
      # Format the 'Added Date' column
      if ("Added Date" %in% colnames(full_data)) {
        full_data$`Added Date` <- format(as.Date(full_data$`Added Date`), "%m/%d/%Y")
      }
      
      return(full_data)
    }, error = function(e) {
      print(paste("SQL query error:", e$message))
      return(data.frame())
    })
  })
  
  # Render filtered table
  output$collection_table <- renderDT({
    data <- filtered_data()
    if (nrow(data) == 0) {
      data <- data.frame(
        `Collection Name` = NA,
        `Item` = NA,
        `Item Condition` = NA,
        `Category` = NA,
        `Price` = NA,
        `Added Date` = NA
      )
    }
    datatable(
      data,
      options = list(scrollX = TRUE),
      caption = ifelse(nrow(filtered_data()) > 0, " ")
    )
  })
  
  # Update total value
  output$total_value <- renderText({
    total_value <- sum(filtered_data()$Price, na.rm = TRUE)
    paste0("$", format(total_value, big.mark = ","))
  })
  
  
  # Suggestion box logic for Quick Add item search
  observe({
    req(input$quick_add_item)  # Ensure the input is not NULL or empty
    
    db <- connect_to_db()
    on.exit({
      if (dbIsValid(db)) dbDisconnect(db)
    })
    
    query <- "SELECT DISTINCT ItemName FROM Items WHERE ItemName LIKE ? ORDER BY ItemName LIMIT 5"
    suggestions <- dbGetQuery(db, query, params = list(paste0("%", input$quick_add_item, "%")))
    
    # Dynamically render the suggestion box
    output$quick_add_suggestions <- renderUI({
      if (nrow(suggestions) > 0) {
        tagList(
          tags$ul(
            lapply(suggestions$ItemName, function(item) {
              tags$li(item, style = "cursor: pointer;", onclick = sprintf("$('#quick_add_item').val('%s').trigger('input');", item))
            }),
            style = "list-style-type: none; padding-left: 0; margin-top: 10px;"
          )
        )
      } else {
        NULL
      }
    })
  })
  
  # Reactive value for triggering dropdown and table updates
  refresh_trigger <- reactiveVal(0)
  
  # Handle the creation of a new collection
  observeEvent(input$create_collection_button, {
    req(user())  # Ensure the user is logged in
    req(input$new_collection_name)  # Ensure a collection name is provided
    
    db <- connect_to_db()
    on.exit({
      if (dbIsValid(db)) dbDisconnect(db)
    })
    
    tryCatch({
      # Insert the new collection into the database
      query <- "INSERT INTO Collections (UserID, CollectionName, CreationDate) VALUES (?, ?, NOW())"
      dbExecute(db, query, params = list(user()$UserID, input$new_collection_name))
      
      showNotification("New collection created successfully!", type = "message")
      
      # Clear the input field
      updateTextInput(session, "new_collection_name", value = "")
      
      # Re-fetch the updated list of collections and refresh the dropdowns
      collections <- dbGetQuery(db, "SELECT CollectionID, CollectionName FROM Collections WHERE UserID = ? ORDER BY CollectionName", 
                                params = list(user()$UserID))
      
      # Update all relevant dropdowns
      updateSelectInput(session, "quick_add_collection", 
                        choices = setNames(collections$CollectionID, collections$CollectionName))
      updateSelectInput(session, "delete_collection", 
                        choices = setNames(collections$CollectionID, collections$CollectionName))
      
      # Trigger UI updates
      refresh_trigger(refresh_trigger() + 1)
    }, error = function(e) {
      print(paste("Error creating collection:", e$message))
      showNotification("Failed to create a new collection. Please try again.", type = "error")
    })
  })
  
  
  # Populate collections dropdown for Delete Collection
  observe({
    req(user())  # Ensure the user is logged in
    
    db <- connect_to_db()
    on.exit({
      if (dbIsValid(db)) dbDisconnect(db)
    })
    
    query <- "SELECT CollectionID, CollectionName FROM Collections WHERE UserID = ? ORDER BY CollectionName"
    collections <- dbGetQuery(db, query, params = list(user()$UserID))
    
    # Update the delete collections dropdown
    updateSelectInput(session, "delete_collection", 
                      choices = setNames(collections$CollectionID, collections$CollectionName))
  })
  
  # Handle Delete Collection Button Click
  observeEvent(input$delete_collection_button, {
    req(user(), input$delete_collection)  # Ensure the user and selection are valid
    
    db <- connect_to_db()
    on.exit({
      if (dbIsValid(db)) dbDisconnect(db)
    })
    
    tryCatch({
      # First, delete associated items from CollectionItems
      dbExecute(db, "DELETE FROM CollectionItems WHERE CollectionID = ?", params = list(input$delete_collection))
      
      # Then, delete the collection itself
      dbExecute(db, "DELETE FROM Collections WHERE CollectionID = ? AND UserID = ?", 
                params = list(input$delete_collection, user()$UserID))
      
      showNotification("Collection deleted successfully!", type = "message")
      
      # Re-fetch updated collections and refresh the dropdowns
      collections <- dbGetQuery(db, "SELECT CollectionID, CollectionName FROM Collections WHERE UserID = ? ORDER BY CollectionName", 
                                params = list(user()$UserID))
      
      # Update the delete collections dropdown
      updateSelectInput(session, "delete_collection", 
                        choices = setNames(collections$CollectionID, collections$CollectionName))
      
      # Update the quick add collections dropdown
      updateSelectInput(session, "quick_add_collection", 
                        choices = setNames(collections$CollectionID, collections$CollectionName))
      
      # Trigger table and UI updates
      refresh_trigger(refresh_trigger() + 1)
    }, error = function(e) {
      print(paste("SQL Error:", e$message))
      showNotification("Failed to delete collection. Please try again.", type = "error")
    })
  })
  
  
  # Populate collections dropdown for Quick Add
  observe({
    req(user())  # Ensure the user is logged in
    
    db <- connect_to_db()
    on.exit({
      if (dbIsValid(db)) dbDisconnect(db)
    })
    
    query <- "SELECT CollectionID, CollectionName FROM Collections WHERE UserID = ? ORDER BY CollectionName"
    collections <- dbGetQuery(db, query, params = list(user()$UserID))
    
    # Update the collections dropdown
    updateSelectInput(session, "quick_add_collection", 
                      choices = setNames(collections$CollectionID, collections$CollectionName))
  })
  
  # Add item to collection
  observeEvent(input$add_to_collection, {
    req(user(), input$quick_add_item, input$quick_add_collection)  # Ensure all inputs are valid
    
    db <- connect_to_db()
    on.exit({
      if (dbIsValid(db)) dbDisconnect(db)
    })
    
    query <- "
    INSERT INTO CollectionItems (CollectionID, ItemID, AddedDate) 
    SELECT ?, ItemID, NOW() FROM Items WHERE ItemName = ? LIMIT 1"
    
    tryCatch({
      dbExecute(db, query, params = list(input$quick_add_collection, input$quick_add_item))
      showNotification("Item added to the collection successfully!", type = "message")
      
      # Increment the refresh trigger to update the table
      refresh_trigger(refresh_trigger() + 1)
    }, error = function(e) {
      print(paste("Error adding item to collection:", e$message))
      showNotification("Failed to add item to the collection.", type = "error")
    })
    
    
    # Reactive value for triggering dropdown and table updates
    refresh_trigger <- reactiveVal(0)
    
    # Populate collections dropdown for Quick Add
    observe({
      req(user())  # Ensure the user is logged in
      
      db <- connect_to_db()
      on.exit({
        if (dbIsValid(db)) dbDisconnect(db)
      })
      
      query <- "SELECT CollectionID, CollectionName FROM Collections WHERE UserID = ? ORDER BY CollectionName"
      collections <- dbGetQuery(db, query, params = list(user()$UserID))
      
      # Update the collections dropdown
      updateSelectInput(session, "quick_add_collection", 
                        choices = setNames(collections$CollectionID, collections$CollectionName))
    })
    
  })
  
  
  
  
  
  #------------------------------------------------------------------------------------------------------------------------------------- 
  # Market Data
  # Render market data with a button for adding to collections
  output$market_data <- renderDT({
    db <- connect_to_db()
    on.exit({
      if (dbIsValid(db)) dbDisconnect(db)
    })
    
    query <- "SELECT ItemID, 'Item', Category, Price, ListDate AS 'List Date' FROM Items"
    data <- dbGetQuery(db, query)
    
    # Format List Date column to "%m/%d/%Y"
    if (!is.null(data$`List Date`)) {
      data$`List Date` <- format(as.Date(data$`List Date`), "%m/%d/%Y")
    }
    
    # Add a button to each row for adding to a collection
    data$Action <- sprintf(
      '<button class="btn btn-primary btn-sm add-to-collection-btn" data-id="%s">Add to Collection</button>',
      data$ItemID
    )
    
    datatable(data, escape = FALSE, options = list(scrollX = TRUE))
  })
  
  # Observe button clicks and open a modal dialog
  observeEvent(input$selected_item, {
    req(input$selected_item)
    
    # Fetch the item details from the database
    db <- connect_to_db()
    on.exit({
      if (dbIsValid(db)) dbDisconnect(db)
    })
    
    query <- "SELECT ItemName, Category, Price FROM Items WHERE ItemID = ?"
    item <- dbGetQuery(db, query, params = list(input$selected_item))
    
    # Render the modal dialog
    showModal(modalDialog(
      title = "Add Item to Collection",
      tags$h4(paste("Item Name:", item$ItemName)),
      tags$h5(paste("Category:", item$Category)),
      tags$h5(paste("Price:", item$Price)),
      tags$hr(),
      
      selectInput("existing_collection", "Select Existing Collection:", choices = NULL),
      textInput("new_collection_name", "Or Create New Collection:", placeholder = "Enter new collection name"),
      
      footer = tagList(
        actionButton("confirm_add_to_collection", "Add to Collection", class = "btn-primary"),
        modalButton("Cancel")
      )
    ))
    
    # Populate the dropdown with existing collections
    query <- "SELECT CollectionID, CollectionName FROM Collections WHERE UserID = ? ORDER BY CollectionName"
    collections <- dbGetQuery(db, query, params = list(user()$UserID))
    
    updateSelectInput(session, "existing_collection",
                      choices = setNames(collections$CollectionID, collections$CollectionName)
    )
  })
  
  # Handle the Add to Collection confirmation
  observeEvent(input$confirm_add_to_collection, {
    req(input$selected_item)
    
    db <- connect_to_db()
    on.exit({
      if (dbIsValid(db)) dbDisconnect(db)
    })
    
    tryCatch({
      if (!is.null(input$new_collection_name) && input$new_collection_name != "") {
        # Create a new collection if a name is provided
        query_create_collection <- "INSERT INTO Collections (UserID, CollectionName, CreationDate) VALUES (?, ?, NOW())"
        dbExecute(db, query_create_collection, params = list(user()$UserID, input$new_collection_name))
        
        # Fetch the ID of the newly created collection
        collection_id <- dbGetQuery(db, "SELECT LAST_INSERT_ID() AS CollectionID")$CollectionID[1]
      } else {
        # Use the selected existing collection
        req(input$existing_collection)
        collection_id <- input$existing_collection
      }
      
      # Add the item to the collection
      query_add_to_collection <- "INSERT INTO CollectionItems (CollectionID, ItemID, AddedDate) VALUES (?, ?, NOW())"
      dbExecute(db, query_add_to_collection, params = list(collection_id, input$selected_item))
      
      showNotification("Item successfully added to collection!", type = "message")
      removeModal()
    }, error = function(e) {
      showNotification("Failed to add item to collection. Please try again.", type = "error")
      print(paste("Error:", e$message))
    })
  })
  
  #-------------------------------------------------------------------------------------------------------------------------------------
  # My Account - Server Logic
  observe({
    req(user())  # Ensure the user is logged in
    print(paste("Fetching details for UserID:", user()$UserID))  # Log the user ID
    db <- connect_to_db()
    on.exit({
      if (dbIsValid(db)) dbDisconnect(db)
    })
    query <- "SELECT Username, Email, UserType, Rating, RegistrationDate FROM Users WHERE UserID = ?"
    user_data <- dbGetQuery(db, query, params = list(user()$UserID))
    print(user_data)  # Debug log
    
    
    # Populate modal with user details
    output$profile_username <- renderText({
      req(user())
      if (nrow(user_data) == 0 || is.na(user_data$Username[1])) {
        return("Username not available")
      } else {
        return(user_data$Username[1])
      }
    })
    
    output$profile_email <- renderText({
      req(user())
      if (nrow(user_data) == 0 || is.na(user_data$Email[1])) {
        return("Email not available")
      } else {
        return(user_data$Email[1])
      }
    })
    
    output$profile_user_type <- renderText({
      req(user())
      if (nrow(user_data) == 0 || is.na(user_data$UserType[1])) {
        return("User type not specified")
      } else {
        return(user_data$UserType[1])
      }
    })
    
    output$profile_rating <- renderText({
      req(user())
      if (nrow(user_data) == 0 || is.na(user_data$Rating[1])) {
        return("No rating available")
      } else {
        return(format(user_data$Rating[1], nsmall = 2))
      }
    })
    
    output$profile_registration_date <- renderText({
      req(user())
      if (nrow(user_data) == 0 || is.na(user_data$RegistrationDate[1])) {
        return("Registration date not available")
      } else {
        return(format(as.Date(user_data$RegistrationDate[1]), "%B %d, %Y"))
      }
    })
    
  })
  
  
  
}

# Run the application
shinyApp(ui = ui, server = server)
