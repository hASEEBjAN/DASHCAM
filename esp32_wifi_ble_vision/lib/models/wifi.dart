class Wifi {
  int _id;
  String _ssid;
  String _password;
  String _date;

  Wifi(this._ssid, this._date, this._password);

  Wifi.withId(this._id, this._ssid, this._date, this._password);

  int get id => _id;

  String get ssid => _ssid;

  String get password => _password;

  String get date => _date;

  set ssid(String newSSID) {
    if (newSSID.length <= 255) {
      this._ssid = newSSID;
    }
  }

  set password(String newPassword) {
    if (newPassword.length <= 64 || newPassword.length >= 8) {
      this._password = newPassword;
    }
  }

  set date(String newDate) {
    this._date = newDate;
  }

  // Convert a Note object into a Map object
  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    if (id != null) {
      map['id'] = _id;
    }
    map['SSID'] = _ssid;
    map['Password'] = _password;
    map['date'] = _date;
    return map;
  }

  // Extract a Wifi object from a Map object
  Wifi.fromMapObject(Map<String, dynamic> map) {
    this._id = map['id'];
    this._ssid = map['SSID'];
    this._password = map['Password'];
    this._date = map['date'];
  }
}
