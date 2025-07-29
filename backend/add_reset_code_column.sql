-- Add reset_code column to users table if it doesn't exist
USE crmapp;
SET @exist := (SELECT count(*) FROM information_schema.COLUMNS WHERE TABLE_NAME='users' AND COLUMN_NAME='reset_code' AND TABLE_SCHEMA='crmapp');
SET @sqlstmt := IF(@exist=0,'ALTER TABLE users ADD COLUMN reset_code VARCHAR(10) NULL','SELECT "reset_code column already exists"');
PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;
