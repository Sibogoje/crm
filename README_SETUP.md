# Mini CRM Setup Instructions

## Overview
This is a complete CRM (Customer Relationship Management) system built with:
- **Frontend**: Flutter (Dart) - Cross-platform mobile/web app
- **Backend**: PHP with MySQL database
- **Server**: XAMPP (Apache + MySQL + PHP)

## Features Implemented
✅ **Authentication System**
- User registration with company setup
- Login/logout functionality
- JWT token-based authentication
- Secure password handling

✅ **Client Management**
- Add, edit, delete clients
- Search and filter clients
- Client details view
- Company association

✅ **Database Structure**
- Companies table
- Users table
- Clients table
- Ready for quotes, invoices, receipts

## Setup Instructions

### 1. Database Setup
1. Start XAMPP and ensure MySQL is running
2. Open phpMyAdmin (http://localhost/phpmyadmin)
3. Create a new database called `crm_database`
4. Import the schema from `backend/database_schema.sql`

### 2. PHP Backend Setup
1. Ensure the CRM folder is in `c:\xampp\htdocs\crm`
2. The API endpoints are located in `backend/api/`
3. Update database connection in `backend/config/database.php` if needed

### 3. Flutter App Setup
1. Ensure Flutter SDK is installed
2. Run `flutter pub get` in the project root
3. Update the API base URL in `lib/services/database_service.dart`:
   ```dart
   static const String baseUrl = 'http://localhost/crm/backend/api';
   ```
   Or for network access: `http://YOUR_IP_ADDRESS/crm/backend/api`

### 4. JWT Library (Optional - for enhanced security)
The backend uses Firebase JWT library. You can either:
- Install Composer and run `composer install` in the backend folder
- Or manually download firebase/php-jwt and place it in `backend/vendor/`
- Or modify `backend/utils/Auth.php` to use a simpler authentication method

## API Endpoints

### Authentication
- `POST /api/register.php` - User and company registration
- `POST /api/login.php` - User login

### Clients
- `GET /api/clients.php` - Get all clients
- `GET /api/clients.php?id={id}` - Get specific client
- `POST /api/clients.php` - Create new client
- `PUT /api/clients.php` - Update client
- `DELETE /api/clients.php` - Delete client

## Running the Application

### For Web (Chrome):
```bash
flutter run -d chrome
```

### For Android/iOS:
```bash
flutter run
```

### For Windows Desktop:
```bash
flutter run -d windows
```

## Project Structure

```
crm/
├── lib/                    # Flutter app source
│   ├── models/            # Data models
│   ├── screens/           # UI screens
│   ├── providers/         # State management
│   ├── services/          # API services
│   └── widgets/           # Reusable UI components
├── backend/               # PHP API backend
│   ├── api/              # API endpoints
│   ├── classes/          # PHP classes
│   ├── config/           # Database configuration
│   └── utils/            # Utility functions
└── pubspec.yaml          # Flutter dependencies
```

## Next Steps (To Be Implemented)

1. **Items/Services Management**
   - Add, edit, delete items/services
   - Pricing and SKU management

2. **Quote Management**
   - Create quotes from items
   - PDF generation
   - Email functionality
   - Quote to invoice conversion

3. **Invoice Management**
   - Create invoices
   - Payment tracking
   - Due date management
   - PDF generation

4. **Receipt Management**
   - Payment recording
   - Receipt generation

5. **Dashboard Enhancement**
   - Real-time statistics
   - Charts and graphs
   - Payment reminders

6. **Settings & Customization**
   - Company logo upload
   - Invoice templates
   - Tax rate configuration

## Troubleshooting

### Common Issues:

1. **Database Connection Error**
   - Ensure MySQL is running in XAMPP
   - Check database credentials in `config/database.php`

2. **API Not Accessible**
   - Ensure Apache is running in XAMPP
   - Check the base URL in Flutter app
   - Verify CORS headers in PHP files

3. **Flutter Dependencies Error**
   - Run `flutter clean` then `flutter pub get`
   - Ensure Flutter SDK is up to date

4. **Authentication Issues**
   - Clear app data/storage
   - Check JWT token handling
   - Verify API endpoints are working

## Security Notes

- Change the JWT secret key in `backend/utils/Auth.php`
- Use HTTPS in production
- Implement proper input validation
- Add rate limiting for API endpoints
- Regular security updates

This CRM system provides a solid foundation that can be extended with additional features as needed.
