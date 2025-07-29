-- Add phone column to users table for profile functionality

-- Check if phone column exists in users table before adding it
SET @sql = (SELECT IF(
  (SELECT COUNT(*)
   FROM INFORMATION_SCHEMA.COLUMNS
   WHERE table_name = 'users'
   AND table_schema = DATABASE()
   AND column_name = 'phone') > 0,
  'SELECT 1',
  'ALTER TABLE users ADD COLUMN phone VARCHAR(50) NULL AFTER last_name'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
