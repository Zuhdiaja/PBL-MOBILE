import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/notifications/notification_navigation.dart';

void main() {
  test('retains destination until consumed, then consumes it once', () {
    final navigation = NotificationNavigation();
    var changes = 0;
    navigation.addListener(() => changes++);
    navigation.accept({'report_id': '42'});
    expect(changes, 1);
    expect(navigation.take()?['report_id'], '42');
    expect(navigation.take(), isNull);
    navigation.dispose();
  });
}
