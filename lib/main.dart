import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/invoice_form_screen.dart';
import 'screens/pdf_preview_screen.dart';
import 'models/invoice_model.dart';

void main() {
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
