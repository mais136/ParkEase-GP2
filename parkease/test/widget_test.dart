import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:parkease/main.dart';
import 'package:parkease/models/user.dart';

void main() {
  testWidgets('App startup test', (WidgetTester tester) async {
    // Mock a user model or provide initial states as needed
    User mockUser = User('', false); // Example user, not logged in
    await tester.pumpWidget(
      ChangeNotifierProvider<User>.value(
        value: mockUser,
        child: MyApp(),
      ),
    );
  });
}
