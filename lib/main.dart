import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'services/download_service.dart';
import 'services/storage_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.bgCream,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final storageService = StorageService();
  final savedUrl = await storageService.getServerUrl();
  if (savedUrl != null && savedUrl.trim().isNotEmpty) {
    ApiService.customBaseUrl = savedUrl.trim();
  }
  final apiService = ApiService();
  final downloadService = DownloadService();

  runApp(MiraaApp(
    storageService: storageService,
    apiService: apiService,
    downloadService: downloadService,
  ));
}

class MiraaApp extends StatelessWidget {
  final StorageService storageService;
  final ApiService apiService;
  final DownloadService downloadService;

  const MiraaApp({
    super.key,
    required this.storageService,
    required this.apiService,
    required this.downloadService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Miraa Shadowing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: HomeScreen(
        storageService: storageService,
        apiService: apiService,
        downloadService: downloadService,
      ),
    );
  }
}
