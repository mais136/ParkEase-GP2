import 'package:flutter/foundation.dart';

class User extends ChangeNotifier {
  String accessToken;
  bool _isAdmin;

  User(this.accessToken, this._isAdmin);

  String get token => accessToken;
  bool get isAdmin => _isAdmin;

  set token(String value) {
    accessToken = value;
    notifyListeners();
  }

  set isAdmin(bool value) {
    _isAdmin = value;
    notifyListeners();
  }
}
