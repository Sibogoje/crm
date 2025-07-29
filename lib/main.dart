import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'providers/auth_provider.dart';
import 'providers/client_provider.dart';
import 'providers/item_provider.dart';
import 'providers/quote_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/receipt_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => QuoteProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => ReceiptProvider()),
      ],
      child: MaterialApp(
        title: 'LIQ-CRM',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    // Remove native splash after a short delay to ensure Flutter is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      FlutterNativeSplash.remove();
    });
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();
    
    // If user is logged in, load their data
    if (authProvider.isLoggedIn) {
      final clientProvider = Provider.of<ClientProvider>(context, listen: false);
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      await clientProvider.loadClients();
      await itemProvider.loadItems();
    }
    
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen until initialization is complete
    if (!_isInitialized) {
      return SplashScreen(
        onInitializationComplete: () {
          _initializeApp();
        },
      );
    }
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // If authentication state changes to true, load data
        if (authProvider.isLoggedIn && !authProvider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadDataIfNeeded();
          });
        }

        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        if (authProvider.isLoggedIn) {
          return const DashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }

  Future<void> _loadDataIfNeeded() async {

    final clientProvider = Provider.of<ClientProvider>(context, listen: false);
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
    
    // Only load if data hasn't been loaded yet
    if (clientProvider.clients.isEmpty) {

      await clientProvider.loadClients();
    }
    if (itemProvider.items.isEmpty) {

      await itemProvider.loadItems();
    }
    if (quoteProvider.quotes.isEmpty) {

      await quoteProvider.loadQuotes();
    }

  }
}
