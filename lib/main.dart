import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/invoice_form_screen.dart';
import 'screens/pdf_preview_screen.dart';
import 'models/invoice_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase - this is safe to call multiple times
    // If already initialized, it will just return the existing app
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e, stackTrace) {
    // Check if it's an "already initialized" error
    final errorMessage = e.toString().toLowerCase();
    if (errorMessage.contains('already initialized') || 
        errorMessage.contains('duplicate app')) {
      debugPrint('Firebase already initialized');
    } else {
      debugPrint('Firebase initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
      // Continue anyway - DatabaseService will handle the error
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'XLOOP Invoice Generator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: GoogleFonts.merriweatherTextTheme(),
      ),
      home: const HomeScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/invoice': (context) => const InvoiceFormScreen(),
        '/preview': (context) {
          final invoice =
              ModalRoute.of(context)!.settings.arguments as InvoiceModel;
          return PDFPreviewScreen(invoice: invoice);
        },
      },
    );
  }
}
