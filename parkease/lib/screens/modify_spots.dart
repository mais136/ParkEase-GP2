import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ModifyParkingSpotScreen extends StatefulWidget {
  final bool isAdmin;
  final String accessToken;

  ModifyParkingSpotScreen({required this.isAdmin, required this.accessToken});

  @override
  _ModifyParkingSpotScreenState createState() =>
      _ModifyParkingSpotScreenState();
}

class _ModifyParkingSpotScreenState extends State<ModifyParkingSpotScreen> {
  List<dynamic> parkingSpots = [];
  bool isLoading = true;
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _standardSpotControllers = {};
  final Map<String, TextEditingController> _evSpotControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchParkingSpots();
  }

  Future<void> _fetchParkingSpots() async {
    var url = Uri.parse('http://192.168.1.61:3001/api/spots/list-spots');
    try {
      var response = await http.get(
        url,
        headers: {"Authorization": "Bearer ${widget.accessToken}"},
      );
      if (response.statusCode == 200) {
        setState(() {
          parkingSpots = json.decode(response.body);
          isLoading = false;
          for (var spot in parkingSpots) {
            String id = spot['_id'];
            _nameControllers[id] = TextEditingController(text: spot['name']);
            _standardSpotControllers[id] =
                TextEditingController(text: spot['standardSpot'].toString());
            _evSpotControllers[id] =
                TextEditingController(text: spot['evSpots']?.toString() ?? '');
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch parking spots.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching parking spots: $e')),
      );
    }
  }

  Future<void> _updateSpot(String id, String newName, String newStandardSpots,
      String newEvSpots) async {
    final url = Uri.parse('http://192.168.1.61:3001/api/spots/update-spot/$id');
    final isEVChargingAvailable =
        newEvSpots.isNotEmpty && int.tryParse(newEvSpots) != 0;
    final evSpotsCount = int.tryParse(newEvSpots);

    final body = jsonEncode({
      "name": newName,
      "standardSpot": int.tryParse(newStandardSpots) ?? 0,
      "isEVChargingAvailable": isEVChargingAvailable,
      "evSpots": evSpotsCount ?? 0,
    });

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${widget.accessToken}"
      },
      body: body,
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Parking spot updated successfully.')),
      );
      _fetchParkingSpots();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to update parking spot. Response: ${response.body}'),
        ),
      );
    }
  }

  Future<void> _deleteSpot(String id) async {
    var url = Uri.parse('http://192.168.1.61:3001/api/spots/delete-spot/$id');
    try {
      var response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.accessToken}"
        },
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Parking spot deleted successfully.')),
        );
        _fetchParkingSpots();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete parking spot.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting parking spot: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Modify Parking Spot"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: parkingSpots.length,
              itemBuilder: (context, index) {
                var spot = parkingSpots[index];
                String id = spot['_id'];
                return Card(
                  key: ValueKey(id),
                  elevation: 4,
                  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _nameControllers[id],
                          decoration: InputDecoration(
                            labelText: 'Parking Spot Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _standardSpotControllers[id],
                          decoration: InputDecoration(
                            labelText: 'Standard Spots',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _evSpotControllers[id],
                          decoration: InputDecoration(
                            labelText: 'EV Spots (leave empty if none)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () => _updateSpot(
                                id,
                                _nameControllers[id]!.text,
                                _standardSpotControllers[id]!.text,
                                _evSpotControllers[id]!.text,
                              ),
                              child: Text('Save'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors
                                    .green, // Use backgroundColor instead of primary
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _deleteSpot(id),
                              child: Text('Delete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors
                                    .red, // Use backgroundColor instead of primary
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
