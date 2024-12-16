# eBay Collectibles Management Platform-R-Shiny-App
This project is a web application designed to manage and analyze collectible items like Video Games, Trading Cards,
Comics, Funko Pops, LEGO Sets, Coins, and Sports Cards. The platform includes features for listing items, tracking
collections, analyzing market trends, and predicting future prices. It uses R Shiny for the frontend and a MariaDB/MySQL 
database for data storage and querying. Additionally, the application leverages AI-powered SQL generation using Python and
OpenAI's GPT-4 for advanced query capabilities

# Features
## User Management
User registration, login, and profile management.
Roles: Buyer, Seller.

## Item Management
Add, view, and delete items.
Item conditions, categories, and verification status.

## Personal Collections
Create and manage personal collections.
Track cumulative value over time.
Add items to collections directly from the market overview.

## Market Overview
Analyze market trends and item pricing data.
Generate SQL queries using AI to fetch insights.

## AI-Powered SQL Querying
Use natural language to generate SQL queries dynamically.

## Price Prediction
Predict future prices for items using time-series analysis (Prophet).

## Database Integration
Comprehensive schema to store users, items, transactions, collections, and reviews.
Procedures to populate tables with random data for testing and demonstration.

# Technologies Used
 
## Frontend
R Shiny: Interactive UI for managing items and collections.
ShinyJS: Adding interactivity to the application.
Plotly: Visualizations for market trends and collection analysis.

## Backend
MariaDB/MySQL: Database to store users, items, transactions, etc.
RMariaDB: R package for database connectivity.

## AI and Python Integration
LangChain: AI-based SQL query generation.
OpenAI's GPT-4: Natural language processing for SQL queries
Prophet: Time-series analysis for price prediction
Reticulate: Integration of Python scripts into R

# Database Schema Tables
Users: Stores user details.
Items: Stores item information (e.g., category, condition, price).
Transactions: Tracks transactions between buyers and sellers.
Collections: User-created collections of items.
CollectionItems: Links items to collections.
MarketData: Historical pricing data for items.
Verification: Tracks item verification status.
Reviews: User reviews and ratings.

# Installation Instructions
## Prerequisites
R (with Shiny and required packages installed)
Python (with virtualenv and required Python packages)
MariaDB/MySQL database server
OpenAI API key for GPT-4
