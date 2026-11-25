import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/auth/data/datasources/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'legacy token moves to secure storage and logout clears both stores',
    () async {
      const key = 'linkguard_mobile_token';
      SharedPreferences.setMockInitialValues({key: 'legacy-token'});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const store = SecureTokenStore();

      expect(await store.read(), 'legacy-token');
      expect(await store.storage.read(key: key), 'legacy-token');
      expect(prefs.getString(key), isNull);

      await store.clear();
      expect(await store.read(), isNull);
      expect(prefs.getString(key), isNull);
    },
  );
}
