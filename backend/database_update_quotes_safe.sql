-- Update quotes table structure to match new Quote model
USE crmapp;

-- Add missing columns to quotes table
ALTER TABLE quotes 
ADD COLUMN IF NOT EXISTS quote_date DATE NOT NULL DEFAULT (CURDATE()) AFTER quote_number,
ADD COLUMN IF NOT EXISTS expiry_date DATE NULL AFTER quote_date;

-- Rename columns to match new structure
ALTER TABLE quotes 
CHANGE COLUMN total total_amount DECIMAL(10,2) NOT NULL;

-- Check if quote_items table exists, if not create it
CREATE TABLE IF NOT EXISTS quote_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quote_id INT NOT NULL,
    item_id INT NULL,
    item_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity DECIMAL(8,2) NOT NULL DEFAULT 1.00,
    total_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (quote_id) REFERENCES quotes(id) ON DELETE CASCADE,
    INDEX idx_quote_items_quote_id (quote_id),
    INDEX idx_quote_items_item_id (item_id)
);
