import 'package:flutter/material.dart';
import 'package:parkease/widgets/logo_widget.dart';
import 'package:parkease/widgets/input_field.dart';
import 'package:parkease/widgets/primary_button.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:parkease/screens/modify_spots.dart';

class AdminPanelScreen extends StatefulWidget {
  final bool isAdmin;
  final String accessToken;

  AdminPanelScreen({required this.isAdmin, required this.accessToken});

  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController spotsNumberController = TextEditingController();
  final TextEditingController evChargersController = TextEditingController();
  bool isEVChargingAvailable = false;

  Future<bool> createParkingSpot(String name, String address, int spotsNumber,
      int evChargers, bool isEVChargingAvailable) async {
    var url = Uri.parse('http://192.168.1.61:3001/api/spots/create-spot');
    try {
      var response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.accessToken}",
        },
        body: jsonEncode({
          "name": name,
          "address": address,
          "standardSpot": spotsNumber,
          "evSpots": evChargers,
          "isEVChargingAvailable": isEVChargingAvailable,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> _refresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Panel"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LogoWidget(),
              SizedBox(height: 30),
              Text(
                'Add a New Parking Spot',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Enter the details below to add a new spot to the system.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      InputField(
                        hintText: 'Parking Spot Name',
                        controller: nameController,
                        keyboardType: TextInputType.text,
                      ),
                      SizedBox(height: 16),
                      InputField(
                        hintText: 'Address',
                        controller: addressController,
                        keyboardType: TextInputType.text,
                      ),
                      SizedBox(height: 16),
                      InputField(
                        hintText: 'Number of Spots',
                        controller: spotsNumberController,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16),
                      CheckboxListTile(
                        title: Text("EV Charging Available"),
                        value: isEVChargingAvailable,
                        onChanged: (newValue) {
                          setState(() {
                            isEVChargingAvailable = newValue ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Colors.blueAccent,
                      ),
                      if (isEVChargingAvailable)
                        Column(
                          children: [
                            SizedBox(height: 16),
                            InputField(
                              hintText: 'Number of EV Chargers',
                              controller: evChargersController,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              PrimaryButton(
                text: 'Save Spot',
                onPressed: () async {
                  int spotsNumber =
                      int.tryParse(spotsNumberController.text) ?? 0;
                  int evChargers = isEVChargingAvailable
                      ? int.tryParse(evChargersController.text) ?? 0
                      : 0;

                  bool success = await createParkingSpot(
                    nameController.text,
                    addressController.text,
                    spotsNumber,
                    evChargers,
                    isEVChargingAvailable,
                  );

                  if (!mounted) return;

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Spot saved successfully')));
                    nameController.clear();
                    addressController.clear();
                    spotsNumberController.clear();
                    evChargersController.clear();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save spot')));
                  }
                },
              ),
              SizedBox(height: 20),
              PrimaryButton(
                text: 'Modify Spots',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ModifyParkingSpotScreen(
                              isAdmin: widget.isAdmin,
                              accessToken: widget.accessToken,
                            )),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
