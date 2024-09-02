import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert';
import 'package:parkease/screens/admin_panel.dart';
import 'package:parkease/screens/change_password.dart';
import 'package:parkease/screens/get_started_screen.dart';
import 'package:parkease/screens/login_screen.dart';
import 'package:parkease/widgets/google_map_widget.dart';
import 'package:parkease/screens/qr_code_example.dart';

class UserParkingScreen extends StatefulWidget {
  final bool isAdmin;
  final String accessToken;

  UserParkingScreen({required this.isAdmin, required this.accessToken});

  @override
  _UserParkingScreenState createState() => _UserParkingScreenState();
}

class _UserParkingScreenState extends State<UserParkingScreen> {
  final storage = FlutterSecureStorage();
  List<dynamic> parkingSpots = [];
  bool isLoading = true;
  TextEditingController usernameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  GoogleMapController? mapController;
  LatLng? userLocation;
  bool isAdmin = false;
  Set<Marker> _markers = Set();
  String originalUsername = '';
  String originalPhoneNumber = '';
  bool isUsernameEditMode = false;
  bool isPhoneNumberEditMode = false;
  String? reservedSpotId;
  bool hasCheckedIn = false;
  Map<String, dynamic> reservationStatus = {};

  @override
  void initState() {
    super.initState();
    isAdmin = widget.isAdmin;
    _determinePosition();
    _fetchParkingSpots();
    _fetchUserProfile();
  }

  Future<void> _refresh() async {
    await _fetchUserProfile();
    await _fetchParkingSpots();
  }

  Future<void> _fetchUserProfile() async {
    final response = await http.get(
      Uri.parse('http://192.168.1.61:3001/api/users/profile'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['profile'];
      setState(() {
        originalUsername = data['Username'] ?? "Default Name";
        originalPhoneNumber = data['PhoneNumber'] ?? "Default Phone Number";
        usernameController.text = originalUsername;
        phoneNumberController.text = originalPhoneNumber;
        isAdmin = data['isAdmin'] ?? false;
      });
    } else {
      if (response.statusCode == 401) {
        await _logoutDueToUnauthorized();
      }
      _showErrorDialog(context,
          'Failed to fetch user profile. Status code: ${response.statusCode}');
    }
  }

  Future<void> _updateUsername() async {
    if (usernameController.text == originalUsername) {
      setState(() {
        isUsernameEditMode = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('http://192.168.1.61:3001/api/users/updateUsername');
    var response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${widget.accessToken}',
      },
      body: jsonEncode({
        'newUsername': usernameController.text,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        isLoading = false;
        isUsernameEditMode = false;
        originalUsername = usernameController.text;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updatePhoneNumber() async {
    if (phoneNumberController.text == originalPhoneNumber) {
      setState(() {
        isPhoneNumberEditMode = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url =
        Uri.parse('http://192.168.1.61:3001/api/users/updatePhoneNumber');
    var response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${widget.accessToken}',
      },
      body: jsonEncode({
        'newPhoneNumber': phoneNumberController.text,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        isLoading = false;
        isPhoneNumberEditMode = false;
        originalPhoneNumber = phoneNumberController.text;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        userLocation = LatLng(
          position.latitude,
          position.longitude,
        );
      });
    } catch (e) {
      print('Error determining position: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _goToSpot(double latitude, double longitude) async {
    String googleMapsUrl =
        "https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving";
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the map.')),
      );
    }
  }

  void _focusOnSpot(double latitude, double longitude) {
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(latitude, longitude),
            zoom: 18.0,
          ),
        ),
      );
    } else {
      print('Map controller is not initialized');
    }
  }

  Future<void> _logoutDueToUnauthorized() async {
    await storage.delete(key: "accessToken");
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
  }

  Future<void> _createReservation(String spotId, String spotType) async {
    final url = Uri.parse('http://192.168.1.61:3001/api/spots/reserve-spot');
    String typeToSend = spotType == 'ev' ? 'ev' : 'standardSpot';

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}'
        },
        body: jsonEncode({'spotId': spotId, 'spotType': typeToSend}),
      );

      if (response.statusCode == 201) {
        final reservation = jsonDecode(response.body)['reservation'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Spot Reserved Successfully')),
        );
        setState(() {
          reservedSpotId = spotId;
          reservationStatus[spotId] = reservation['qrCode'];
          _fetchParkingSpots();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to reserve the spot. ${json.decode(response.body)['message']}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating reservation: $e')),
      );
    }
  }

  Future<void> _deleteReservation(String? reservationId) async {
    if (reservationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No reservation to cancel')),
      );
      return;
    }

    final url = Uri.parse(
        'http://192.168.1.61:3001/api/spots/delete-reservation/$reservationId');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reservation cancelled successfully')),
        );
        setState(() {
          _fetchParkingSpots();
          reservedSpotId = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to cancel the reservation: ${json.decode(response.body)['message']}'),
          ),
        );
        print('Error: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling reservation: $e')),
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    final url = Uri.parse('http://192.168.1.61:3001/api/auth/logout');
    String phoneNumber = await storage.read(key: "phoneNumber") ?? "";

    if (widget.accessToken.isNotEmpty) {
      try {
        var response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.accessToken}',
          },
          body: jsonEncode({'phoneNumber': phoneNumberController.text}),
        );
        print('Logout API Response: ${response.statusCode}');
      } catch (e) {
        print('Logout API Call Error: $e');
      }
    }

    await storage.deleteAll();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => GetStartedScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('An Error Occurred'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _fetchParkingSpots() async {
    var url = Uri.parse('http://192.168.1.61:3001/api/spots/list-spots');
    try {
      var response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );
      if (response.statusCode == 200) {
        var tempMarkers = Set<Marker>();
        var fetchedSpots = jsonDecode(response.body) as List;

        fetchedSpots.forEach((spot) {
          var spotId = spot['_id'];
          var spotName = spot['name'] ?? 'Unknown';
          var latitude = spot['latitude'] is double ? spot['latitude'] : 0.0;
          var longitude = spot['longitude'] is double ? spot['longitude'] : 0.0;

          var marker = Marker(
            markerId: MarkerId(spotId),
            position: LatLng(latitude, longitude),
            infoWindow: InfoWindow(title: spotName),
            onTap: () {
              mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                      target: LatLng(latitude, longitude), zoom: 14.0),
                ),
              );
            },
          );
          tempMarkers.add(marker);
        });

        setState(() {
          parkingSpots = fetchedSpots;
          _markers = tempMarkers;
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to fetch parking spots. Status code: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching parking spots: $e')),
      );
    }
  }

  Widget _buildSpotListItem(Map<String, dynamic> spot) {
    bool isEVChargingAvailable = spot['isEVChargingAvailable'] ?? false;
    int totalStandardSpots = spot['standardSpot'] ?? 0;
    int availableStandardSpots = spot['standardSpotAvailable'] ?? 0;
    int totalEvSpots = isEVChargingAvailable ? spot['evSpots'] ?? 0 : 0;
    int availableEvSpots =
        isEVChargingAvailable ? spot['evSpotsAvailable'] ?? 0 : 0;
    int totalSpots = totalStandardSpots + totalEvSpots;
    int totalAvailableSpots = availableStandardSpots + availableEvSpots;
    bool isCheckedIn = spot['reservationStatus'] == 'checked-in';
    bool isReservedByCurrentUser = spot['reservedByCurrentUser'] == true;
    String? reservationId = spot['reservationId'];
    String? qrCode = reservationStatus[reservationId];
    bool isAvailable = totalAvailableSpots > 0;

    return GestureDetector(
      onTap: () {
        double latitude = spot['latitude']?.toDouble() ?? 0.0;
        double longitude = spot['longitude']?.toDouble() ?? 0.0;
        _focusOnSpot(latitude, longitude);
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                spot['name'] ?? 'Unnamed Spot',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 5),
              Text(
                "Total Spots: $totalSpots",
                style: TextStyle(fontSize: 14),
              ),
              Text(
                "Standard Spots Available: $availableStandardSpots / $totalStandardSpots",
                style: TextStyle(fontSize: 14),
              ),
              if (isEVChargingAvailable)
                Text(
                  "EV Spots Available: $availableEvSpots / $totalEvSpots",
                  style: TextStyle(fontSize: 14),
                ),
              if (qrCode != null)
                QrCodeExample(
                  qrCode: qrCode,
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isAvailable && !isReservedByCurrentUser)
                    ElevatedButton(
                      onPressed: () => _showReservationDialog(spot['_id']),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: Text('Reserve'),
                    ),
                  if (isReservedByCurrentUser && !isCheckedIn)
                    ElevatedButton(
                      onPressed: () => _checkIn(reservationId!),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        backgroundColor: Colors.green,
                      ),
                      child: Text('Check In'),
                    ),
                  if (isReservedByCurrentUser)
                    ElevatedButton(
                      onPressed: () => _deleteReservation(reservationId!),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        backgroundColor: Colors.red,
                      ),
                      child: Icon(Icons.cancel, color: Colors.white),
                    ),
                  IconButton(
                    icon: Icon(Icons.directions, color: Colors.blueAccent),
                    onPressed: () =>
                        _goToSpot(spot['latitude'], spot['longitude']),
                    tooltip: 'Navigate to Spot',
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkIn(String reservationId) async {
    var url = Uri.parse('http://192.168.1.61:3001/api/spots/check-in');
    var response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.accessToken}',
      },
      body: jsonEncode({'reservationId': reservationId}), // Ensure correct body
    );

    if (response.statusCode == 200) {
      setState(() {
        reservationStatus[reservationId] = 'checked-in';
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Checked in successfully')));
      _fetchParkingSpots(); // Optionally refresh the spots list to reflect the check-in
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to check in')));
    }
  }

  Future<void> _checkOut(String reservationId) async {
    var url = Uri.parse('http://192.168.1.61:3001/api/spots/check-out');
    var response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.accessToken}',
      },
      body: jsonEncode({'reservationId': reservationId}), // Ensure correct body
    );

    if (response.statusCode == 200) {
      setState(() {
        reservationStatus.remove(reservationId);
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Checked out successfully')));
      _fetchParkingSpots(); // Optionally refresh the spots list to reflect the check-out
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to check out')));
    }
  }

  Future<void> _showReservationDialog(String spotId) async {
    var spot =
        parkingSpots.firstWhere((s) => s['_id'] == spotId, orElse: () => null);
    bool isEVChargingAvailable = spot?['isEVChargingAvailable'] ?? false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Spot Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (isEVChargingAvailable)
                ListTile(
                  leading: Icon(Icons.electric_car, color: Colors.blueAccent),
                  title: Text('EV Spot'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _createReservation(spotId, 'ev');
                  },
                ),
              ListTile(
                leading: Icon(Icons.directions_car, color: Colors.blueAccent),
                title: Text('Standard Spot'),
                onTap: () {
                  Navigator.of(context).pop();
                  _createReservation(spotId, 'standard');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reserve Parking Spot"),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlueAccent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              accountName: isUsernameEditMode
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: usernameController,
                            decoration: InputDecoration(
                              hintText: "Username",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.white),
                          onPressed: _updateUsername,
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              usernameController.text = originalUsername;
                              isUsernameEditMode = false;
                            });
                          },
                        ),
                      ],
                    )
                  : InkWell(
                      onTap: () {
                        setState(() {
                          isUsernameEditMode = true;
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                              child: Text(usernameController.text.isEmpty
                                  ? 'Name not available'
                                  : usernameController.text)),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(Icons.edit, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
              accountEmail: isPhoneNumberEditMode
                  ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: phoneNumberController,
                            decoration: InputDecoration(
                              hintText: "Phone Number",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.white),
                          onPressed: _updatePhoneNumber,
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              phoneNumberController.text = originalPhoneNumber;
                              isPhoneNumberEditMode = false;
                            });
                          },
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                            child: Text(phoneNumberController.text.isEmpty
                                ? 'Phone not available'
                                : phoneNumberController.text)),
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              isPhoneNumberEditMode = true;
                            });
                          },
                        ),
                      ],
                    ),
            ),
            if (isAdmin)
              ListTile(
                title: Text('Admin Panel'),
                leading:
                    Icon(Icons.admin_panel_settings, color: Colors.blueAccent),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => AdminPanelScreen(
                            isAdmin: true,
                            accessToken: widget.accessToken,
                          )));
                },
              ),
            ListTile(
              title: Text('Forgot Password'),
              leading: Icon(Icons.lock, color: Colors.blueAccent),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => ChangePasswordScreen(
                          token: widget.accessToken,
                          phoneNumber: phoneNumberController.text)),
                );
              },
            ),
            ListTile(
              title: Text('Logout'),
              leading: Icon(Icons.logout, color: Colors.blueAccent),
              onTap: () async {
                await logout(context);
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: GoogleMapWidget(
                initialPosition: userLocation ?? LatLng(0, 0),
                markers: _markers,
                onMapCreated: (map) {
                  mapController = map; // Ensure mapController is set
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: parkingSpots.length,
                      itemBuilder: (context, index) {
                        return _buildSpotListItem(parkingSpots[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
