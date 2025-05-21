import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:myway/const/colors.dart';

List cars = [
  {'id': 0, 'name': 'Select a Ride', 'price': 0.0},
  {'id': 1, 'name': 'UberGo', 'price': 230.0},
  {'id': 2, 'name': 'Go Sedan', 'price': 300.0},
  {'id': 3, 'name': 'UberXL', 'price': 500.0},
  {'id': 4, 'name': 'UberAuto', 'price': 140.0},
];

class TestDrawer extends StatefulWidget {
  const TestDrawer({super.key});
  @override
  _TestDrawerState createState() => _TestDrawerState();
}

class _TestDrawerState extends State<TestDrawer> {
  late CameraPosition _initialPosition;
  GoogleMapController? mapController;

  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  final LatLng _center = const LatLng(35.1691, 129.0874);

  int selectedCarId = 1;
  bool backButtonVisible = true;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // 시트 열고 닫는 메소드
  void _toggleSheet() {
    // 여기에 시트 열고 닫기 로직 추가
    // 예를 들어, DraggableScrollableSheet의 상태를 변경하는 로직
    setState(() {
      backButtonVisible = !backButtonVisible; // 예시로 backButtonVisible을 변경
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading:
            backButtonVisible
                ? IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                )
                : null,
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SizedBox(
                height: constraints.maxHeight / 2,
                child: Container(color: BLUE_SECONDARY_500),

                //  GoogleMap(
                //   polylines: Set<Polyline>.of(polylines.values),
                //   initialCameraPosition: CameraPosition(
                //     target: _center,
                //     zoom: 17.0,
                //   ),
                //   onMapCreated: _onMapCreated,
                // ),
              );
            },
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.1,
            maxChildSize: 0.4,
            snapSizes: [0.1, 0.4],
            snap: true,
            builder: (BuildContext context, scrollSheetController) {
              return Container(
                color: Colors.white,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  physics: ClampingScrollPhysics(),
                  controller: scrollSheetController,
                  itemCount: cars.length,
                  itemBuilder: (BuildContext context, int index) {
                    final car = cars[index];
                    if (index == 0) {
                      return Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            SizedBox(width: 50, child: Divider(thickness: 5)),
                            Text('Choose a trip or swipe up for more'),
                          ],
                        ),
                      );
                    }
                    return Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(10),
                        onTap: () {
                          setState(() {
                            selectedCarId = car['id'];
                          });
                        },
                        leading: Icon(Icons.car_rental),
                        title: Text(car['name']),
                        trailing: Text(car['price'].toString()),
                        selected: selectedCarId == car['id'],
                        selectedTileColor: Colors.grey[200],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

main() {
  runApp(MaterialApp(home: TestDrawer()));
}
