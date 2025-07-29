-- Add missing columns to companies table for settings functionality

-- Check if columns exist before adding them
SET @sql = (SELECT IF(
  (SELECT COUNT(*)
   FROM INFORMATION_SCHEMA.COLUMNS
   WHERE table_name = 'companies'
   AND table_schema = DATABASE()
   AND column_name = 'website') > 0,
  'SELECT 1',
  'ALTER TABLE companies ADD COLUMN website VARCHAR(255) NULL'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add tax_id column if it doesn't exist
SET @sql = (SELECT IF(
  (SELECT COUNT(*)
   FROM INFORMATION_SCHEMA.COLUMNS
   WHERE table_name = 'companies'
   AND table_schema = DATABASE()
   AND column_name = 'tax_id') > 0,
  'SELECT 1',
  'ALTER TABLE companies ADD COLUMN tax_id VARCHAR(100) NULL'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add phone column if it doesn't exist (for older schemas)
SET @sql = (SELECT IF(
  (SELECT COUNT(*)
   FROM INFORMATION_SCHEMA.COLUMNS
   WHERE table_name = 'companies'
   AND table_schema = DATABASE()
   AND column_name = 'phone') > 0,
  'SELECT 1',
  'ALTER TABLE companies ADD COLUMN phone VARCHAR(50) NULL'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
