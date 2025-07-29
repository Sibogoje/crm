# Database Setup Instructions

## Step 1: Start XAMPP
1. Open XAMPP Control Panel
2. Start **Apache** service
3. Start **MySQL** service

## Step 2: Create Database
1. Open your web browser and go to: http://localhost/phpmyadmin
2. Click on "SQL" tab
3. Copy and paste the contents of `backend/setup/create_database.sql`
4. Click "Go" to execute

Alternatively, you can:
1. Click "New" in phpMyAdmin
2. Create a database named `crmapp`
3. Select the `crmapp` database
4. Import the SQL file

## Step 3: Test Database Connection
Open your browser and go to: http://localhost/crm/backend/api/test_connection.php

You should see: `{"status":"success","message":"Database connection successful!"}`

## Step 4: Test CORS Fix
The Flutter app should now be able to communicate with the backend without CORS errors.

## Troubleshooting

### If you see "Database connection failed":
1. Make sure MySQL is running in XAMPP
2. Check if the database `crmapp` exists
3. Verify the database credentials in `backend/config/database.php`

### Default MySQL credentials:
- Host: localhost
- Username: root
- Password: (empty)
- Database: crmapp

### If CORS errors persist:
1. Make sure Apache is running in XAMPP
2. Clear your browser cache
3. Check that all API files have the OPTIONS handler added
