import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ps12_image_overview/di/service_locator.dart';
import 'package:ps12_image_overview/providers/image_overview_provider.dart';
import 'package:ps12_image_overview/screens/image_overview_screen.dart';

void main() {
  // Set up service locator with mock services
  setupServiceLocator(useMocks: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImageOverviewProvider()),
      ],
      child: MaterialApp(
        title: 'Image Overview',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const ImageOverviewScreen(),
      ),
    );
  }
}
