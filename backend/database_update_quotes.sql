-- Update quotes table structure to match new Quote model
USE crmapp;

-- Drop existing quotes and quote_items tables to recreate with new structure
DROP TABLE IF EXISTS quote_items;
DROP TABLE IF EXISTS quotes;

-- Recreate quotes table with updated structure
CREATE TABLE quotes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    company_id INT NOT NULL,
    client_id INT NOT NULL,
    quote_number VARCHAR(50) NOT NULL,
    quote_date DATE NOT NULL,
    expiry_date DATE NULL,
    status ENUM('draft', 'sent', 'accepted', 'rejected', 'expired') DEFAULT 'draft',
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_company_quote_number (company_id, quote_number),
    INDEX idx_quotes_company_id (company_id),
    INDEX idx_quotes_client_id (client_id)
);

-- Recreate quote_items table with updated structure
CREATE TABLE quote_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quote_id INT NOT NULL,
    item_id INT NULL, -- Can be null for custom items
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
