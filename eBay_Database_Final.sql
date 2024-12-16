-- Drop existing schema if needed (Be careful with this in production environments)
DROP DATABASE IF EXISTS eBayCollectibles;

-- Create Schema for the Database
CREATE DATABASE IF NOT EXISTS eBayCollectibles;
USE eBayCollectibles;

-- Users Table
CREATE TABLE Users (
    UserID INT AUTO_INCREMENT PRIMARY KEY,
    Username VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    UserType ENUM('buyer', 'seller') NOT NULL,
    Rating DECIMAL(3, 2),
    RegistrationDate DATETIME DEFAULT NULL
);

-- Items Table
CREATE TABLE Items (
    ItemID INT AUTO_INCREMENT PRIMARY KEY,
    ItemName VARCHAR(100) NOT NULL,
    Category ENUM('Video Games', 'Trading Cards', 'Comics', 'Funko Pops', 'LEGO Sets', 'Coins', 'Sports Cards') NOT NULL,
    Description TEXT,
    ItemCondition ENUM('New', 'Used', 'Mint', 'Good'),
    Price DECIMAL(10, 2) NOT NULL,
    ListDate DATETIME DEFAULT NULL,
    VerificationStatus ENUM('pending', 'verified', 'rejected') DEFAULT 'pending'
);

-- Transactions Table
CREATE TABLE Transactions (
    TransactionID INT AUTO_INCREMENT PRIMARY KEY,
    SellerID INT,
    BuyerID INT,
    ItemID INT,
    TransactionDate DATETIME DEFAULT NULL,
    Price DECIMAL(10, 2),
    FOREIGN KEY (SellerID) REFERENCES Users(UserID),
    FOREIGN KEY (BuyerID) REFERENCES Users(UserID),
    FOREIGN KEY (ItemID) REFERENCES Items(ItemID)
);

-- Collections Table
CREATE TABLE Collections (
    CollectionID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT,
    CollectionName VARCHAR(100) NOT NULL,
    CreationDate DATETIME DEFAULT NULL,
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- CollectionItems Table (associative entity between Collections and Items)
CREATE TABLE CollectionItems (
    CollectionItemID INT PRIMARY KEY AUTO_INCREMENT,
    CollectionID INT,
    ItemID INT,
    AddedDate DATETIME DEFAULT NULL,
    FOREIGN KEY (CollectionID) REFERENCES Collections(CollectionID),
    FOREIGN KEY (ItemID) REFERENCES Items(ItemID)
);

-- Make sure you're using the correct schema
USE eBayCollectibles;

-- Create the MarketData table if it does not exist
CREATE TABLE IF NOT EXISTS MarketData (
    MarketDataID INT AUTO_INCREMENT PRIMARY KEY,
    ItemID INT,
    PriceDate DATE,
    Price DECIMAL(10, 2),
    FOREIGN KEY (ItemID) REFERENCES Items(ItemID)
);

-- Verification Table
CREATE TABLE Verification (
    VerificationID INT PRIMARY KEY AUTO_INCREMENT,
    ItemID INT,
    VerificationStatus ENUM('pending', 'verified', 'rejected') NOT NULL,
    VerificationDate DATETIME DEFAULT NULL,
    VerifiedBy VARCHAR(100),
    FOREIGN KEY (ItemID) REFERENCES Items(ItemID)
);

-- Reviews Table
CREATE TABLE Reviews (
    ReviewID INT PRIMARY KEY AUTO_INCREMENT,
    ReviewerID INT,
    RevieweeID INT,
    Rating DECIMAL(3, 2) NOT NULL,
    ReviewText TEXT,
    ReviewDate DATETIME DEFAULT NULL,
    FOREIGN KEY (ReviewerID) REFERENCES Users(UserID),
    FOREIGN KEY (RevieweeID) REFERENCES Users(UserID)
);

DELIMITER ;;

CREATE PROCEDURE PopulateDetailedItems()
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE randCat INT;
    DECLARE randCond INT;
    DECLARE randVerStat INT;
    DECLARE randName INT;
    DECLARE itemName VARCHAR(100);
    DECLARE itemCondition ENUM('New', 'Used', 'Mint', 'Good');
    DECLARE verificationStatus ENUM('pending', 'verified', 'rejected');

    WHILE i < 4000 DO
        -- Generate random indexes for category, condition, verification status, and name
        SET randCat = FLOOR(1 + RAND() * 7);
        SET randCond = FLOOR(1 + RAND() * 4);
        SET randVerStat = FLOOR(1 + RAND() * 3);
        SET randName = FLOOR(1 + RAND() * 10);

        -- Determine the item name based on category
        SET itemName = CASE randCat
            WHEN 1 THEN ELT(randName, 'Super Mario Bros.', 'The Legend of Zelda', 'Fortnite', 'Call of Duty', 'Pokémon', 'Minecraft', 'FIFA 20', 'Elder Scrolls V: Skyrim', 'Grand Theft Auto V', 'Cyberpunk 2077')
            WHEN 2 THEN ELT(randName, 'Black Lotus', 'Charizard', 'Blue Eyes White Dragon', 'Snapcaster Mage', 'Mox Pearl', 'Pikachu', 'Royal Assassin', 'Vampire Nighthawk', 'Serra Angel', 'The Tabernacle at Pendrell Vale')
            WHEN 3 THEN ELT(randName, 'Action Comics #1', 'Detective Comics #27', 'Spider-Man #1', 'X-Men #1', 'Black Panther #1', 'Watchmen #1', 'The Killing Joke', 'Sandman #1', 'Flash #123', 'Superman #75')
            WHEN 4 THEN ELT(randName, 'Iron Man', 'Harry Potter', 'Batman', 'Superman', 'Wonder Woman', 'Rick Sanchez', 'Morty', 'Hulk', 'Thor', 'Joker')
            WHEN 5 THEN ELT(randName, 'Millennium Falcon', 'Hogwarts Castle', 'Central Perk', 'Star Destroyer', 'Batmobile', 'Death Star', 'Tower Bridge', 'Voltron', 'Pirates of Barracuda Bay', 'Apollo Saturn V')
            WHEN 6 THEN ELT(randName, '1907 Saint Gaudens Double Eagle', '1794 Flowing Hair Silver Dollar', '2007 Queen Elizabeth II Gold Sovereign', '1964 Kennedy Half Dollar', '1881 Morgan Silver Dollar', '1913 Liberty Head Nickel', '1932 Washington Quarter', '1851 $20 Liberty Gold Coin', '2000 Sacagawea Dollar', '1927 Peace Dollar')
            WHEN 7 THEN ELT(randName, '1986 Michael Jordan Rookie Card', '1952 Mickey Mantle', '2000 Tom Brady Rookie Card', '1979 Wayne Gretzky', '1965 Joe Namath', '1992 Shaquille O\'Neal', '1989 Ken Griffey Jr.', '1998 Peyton Manning', '2001 Tiger Woods', '1963 Pete Rose')
        END;

        -- Determine the item condition
        SET itemCondition = ELT(randCond, 'New', 'Used', 'Mint', 'Good');

        -- Determine the verification status
        SET verificationStatus = ELT(randVerStat, 'pending', 'verified', 'rejected');

        -- Insert the item into the table
        INSERT INTO Items (ItemName, Category, Description, ItemCondition, Price, ListDate, VerificationStatus)
        VALUES (
            itemName,
            ELT(randCat, 'Video Games', 'Trading Cards', 'Comics', 'Funko Pops', 'LEGO Sets', 'Coins', 'Sports Cards'),
            CONCAT('Description of ', itemName),
            itemCondition,
            ROUND(10 + (RAND() * 990), 2),  -- Price varies from 10 to 1000
            DATE_ADD(DATE_ADD('2022-01-01', INTERVAL FLOOR(RAND() * 700) DAY), INTERVAL FLOOR(RAND() * 1000) DAY),  -- Random list date within ~3 years
            verificationStatus
        );

        SET i = i + 1;
    END WHILE;
END;;

DELIMITER ;

-- Call the procedure to populate the table
CALL PopulateDetailedItems();

DELIMITER ;;

-- Procedure to populate Users and Items
CREATE PROCEDURE PopulateUsersAndItems()
BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < 1000 DO
        INSERT INTO Users (Username, Email, PasswordHash, UserType, Rating, RegistrationDate)
        VALUES (CONCAT('User', i), CONCAT('user', i, '@example.com'), 'hash', IF(i%2 = 0, 'buyer', 'seller'), ROUND(RAND() * 5, 1), DATE_ADD('2022-01-01', INTERVAL FLOOR(RAND() * 700) DAY));
        
        INSERT INTO Items (ItemName, Category, Description, ItemCondition, Price, ListDate, VerificationStatus)
        VALUES (CONCAT('Item', i), ELT(FLOOR(1 + RAND() * 7), 'Video Games', 'Trading Cards', 'Comics', 'Funko Pops', 'LEGO Sets', 'Coins', 'Sports Cards'), 'A cool item', ELT(FLOOR(1 + RAND() * 4), 'New', 'Used', 'Mint', 'Good'), ROUND(10 + (RAND() * 990), 2), DATE_ADD('2022-01-01', INTERVAL FLOOR(RAND() * 700) DAY), ELT(FLOOR(1 + RAND() * 3), 'pending', 'verified', 'rejected'));
        
        SET i = i + 1;
    END WHILE;
END;;

DELIMITER ;;

-- Procedure to populate Transactions
CREATE PROCEDURE PopulateTransactions()
BEGIN
    DECLARE j INT DEFAULT 0;
    DECLARE maxUserID INT;
    DECLARE maxItemID INT;
    
    SELECT MAX(UserID) INTO maxUserID FROM Users;
    SELECT MAX(ItemID) INTO maxItemID FROM Items;
    
    WHILE j < 500 DO
        INSERT INTO Transactions (SellerID, BuyerID, ItemID, TransactionDate, Price)
        VALUES (
            FLOOR(1 + RAND() * maxUserID), -- Random SellerID
            FLOOR(1 + RAND() * maxUserID), -- Random BuyerID
            FLOOR(1 + RAND() * maxItemID), -- Random ItemID
            DATE_ADD(DATE_ADD('2022-01-01', INTERVAL FLOOR(RAND() * 700) DAY), INTERVAL -FLOOR(RAND() * 365) DAY), -- Random date within the last year
            ROUND(10 + (RAND() * 990), 2) -- Random price from 10 to 1000
        );
        SET j = j + 1;
    END WHILE;
END;;

DELIMITER ;;

-- Procedure to populate MarketData
CREATE PROCEDURE PopulateMarketData()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE maxItemID INT;
    SELECT MAX(ItemID) INTO maxItemID FROM Items;
    
    -- Check if maxItemID is NULL which means Items table might be empty
    IF maxItemID IS NOT NULL THEN
        WHILE i <= maxItemID DO
            INSERT INTO MarketData (ItemID, PriceDate, Price)
            VALUES (i, CURDATE() - INTERVAL FLOOR(RAND() * 365) DAY, ROUND(100 + (RAND() * 900), 2));
            SET i = i + 1;
        END WHILE;
    END IF;
END;;

DELIMITER ;;

-- Procedure to populate Collections
CREATE PROCEDURE PopulateCollections()
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE maxUserID INT;
    SELECT MAX(UserID) INTO maxUserID FROM Users;
    
    WHILE i < 500 DO
        INSERT INTO Collections (UserID, CollectionName, CreationDate)
        VALUES (
            FLOOR(1 + RAND() * maxUserID), -- Random UserID
            CONCAT('Collection', i),
            DATE_ADD('2022-01-01', INTERVAL FLOOR(RAND() * 700) DAY)
        );
        SET i = i + 1;
    END WHILE;
END;;

DELIMITER ;;

-- Procedure to populate CollectionItems
CREATE PROCEDURE PopulateCollectionItems()
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE maxCollectionID INT;
    DECLARE maxItemID INT;
    
    SELECT MAX(CollectionID) INTO maxCollectionID FROM Collections;
    SELECT MAX(ItemID) INTO maxItemID FROM Items;
    
    WHILE i < 1000 DO
        INSERT INTO CollectionItems (CollectionID, ItemID, AddedDate)
        VALUES (
            FLOOR(1 + RAND() * maxCollectionID), -- Random CollectionID
            FLOOR(1 + RAND() * maxItemID), -- Random ItemID
            DATE_ADD('2022-01-01', INTERVAL FLOOR(RAND() * 700) DAY)
        );
        SET i = i + 1;
    END WHILE;
END;;

DELIMITER ;;

-- Procedure to populate Verification
CREATE PROCEDURE PopulateVerification()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE maxItemID INT;
    SELECT MAX(ItemID) INTO maxItemID FROM Items;
    
    WHILE i <= maxItemID DO
        INSERT INTO Verification (ItemID, VerificationStatus, VerificationDate, VerifiedBy)
        VALUES (
            i,
            ELT(FLOOR(1 + RAND() * 3), 'pending', 'verified', 'rejected'),
            DATE_ADD('2022-01-01', INTERVAL FLOOR(RAND() * 700) DAY),
            CONCAT('Verifier', FLOOR(1 + RAND() * 10))
        );
        SET i = i + 1;
    END WHILE;
END;;

DELIMITER ;;

-- Procedure to populate Reviews
CREATE PROCEDURE PopulateReviews()
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE maxUserID INT;
    SELECT MAX(UserID) INTO maxUserID FROM Users;
    
    WHILE i < 500 DO
        INSERT INTO Reviews (ReviewerID, RevieweeID, Rating, ReviewText, ReviewDate)
        VALUES (
            FLOOR(1 + RAND() * maxUserID), -- Random ReviewerID
            FLOOR(1 + RAND() * maxUserID), -- Random RevieweeID
            ROUND(RAND() * 5, 2),
            CONCAT('Review for user ', FLOOR(1 + RAND() * maxUserID)),
            DATE_ADD('2022-01-01', INTERVAL FLOOR(RAND() * 700) DAY)
        );
        SET i = i + 1;
    END WHILE;
END;;

DELIMITER ;

-- Call procedures to populate the database
CALL PopulateUsersAndItems();
CALL PopulateTransactions();
CALL PopulateMarketData();
CALL PopulateCollections();
CALL PopulateCollectionItems();
CALL PopulateVerification();
CALL PopulateReviews();

-- Output to confirm creation
SELECT 'Procedure Created Successfully' AS Message;

-- Select data to verify
SELECT * FROM Items LIMIT 4000;
SELECT * FROM Transactions LIMIT 4000;
SELECT * FROM Users LIMIT 4000;
SELECT * FROM Collections LIMIT 4000;
SELECT * FROM CollectionItems LIMIT 4000;
SELECT * FROM Verification LIMIT 4000;
SELECT * FROM Reviews LIMIT 4000;
SHOW TABLES LIKE 'MarketData';
SELECT * FROM MarketData LIMIT 4000;
