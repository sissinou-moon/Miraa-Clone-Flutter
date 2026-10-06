import 'package:flutter_test/flutter_test.dart';
import 'package:miraa_shadowing/main.dart';
import 'package:miraa_shadowing/services/api_service.dart';
import 'package:miraa_shadowing/services/download_service.dart';
import 'package:miraa_shadowing/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Miraa app smoke test - launches and displays initial blank screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final storage = StorageService();
    final api = ApiService();
    final download = DownloadService();

    await tester.pumpWidget(MiraaApp(
      storageService: storage,
      apiService: api,
      downloadService: download,
    ));

    await tester.pumpAndSettle();

    expect(find.text('Miraa Shadowing'), findsOneWidget);
    expect(find.text('Add Video URL'), findsOneWidget);
  });
}
