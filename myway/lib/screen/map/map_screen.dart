import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/screen/map/course_recommend_bottomsheet.dart';
import 'package:myway/temp/test_latlng.dart';
import 'package:provider/provider.dart';

import '../../model/course_model.dart';
import '../../provider/map_provider.dart';
import 'start_tracking_bottomsheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? mapController;
  Location location = Location();
  bool isTracking = false;
  List<LatLng> route = [];
  Set<Polyline> polylines = {};
  int? selectedIndex;
  LocationData? currentPosition;
  bool _initialPositionSet = false;

  @override
  void initState() {
    super.initState();
    route = TestLatlng().getTestLatlng();

    _initLocationService();
  }

  Future<void> _initLocationService() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
    }

    if (permissionGranted == PermissionStatus.granted) {
      location.changeSettings(accuracy: LocationAccuracy.high, interval: 1000);
      _getLocation();
    }
  }

  Future<void> _getLocation() async {
    print('📍 getLocation');
    currentPosition = await location.getLocation();
    if (currentPosition != null && mounted) {
      print('📍 currentPosition : $currentPosition');

      setState(() {
        _updateLocation(currentPosition!);
      });
    }
  }

  void _updateLocation(LocationData locationData) {
    print('📍 updateLocation');

    if (!mounted) return;
    setState(() {
      currentPosition = locationData;
      print('📍 currentPosition : $currentPosition');
    });

    if (!_initialPositionSet &&
        currentPosition != null &&
        mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(currentPosition!.latitude!, currentPosition!.longitude!),
          17.0,
        ),
      );
      _initialPositionSet = true;
    }

    if (context.read<MapProvider>().isTracking) {
      route.add(
        LatLng(currentPosition!.latitude!, currentPosition!.longitude!),
      );
      _updatePolylines();
    }
  }

  void _updatePolylines() {
    print('📍 _updatePolylines');
    if (route.isNotEmpty) {
      setState(() {
        polylines.clear();
        polylines.add(
          Polyline(
            polylineId: PolylineId('route'),
            color: Colors.orange,
            width: 5,
            points: List.from(route),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: WHITE,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          '마이웨이',
          style: TextStyle(
            color: GRAYSCALE_LABEL_900,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return GoogleMap(
                onMapCreated: (controller) {
                  mapController = controller;
                },
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    currentPosition?.latitude ?? 35.1691,
                    currentPosition?.longitude ?? 129.0874,
                  ),
                  zoom: 17.0,
                ),
                myLocationEnabled: true,
                polylines: polylines,
              );
            },
          ),
          if (mapProvider.isCourseRecommendBottomSheetVisible)
            CourseRecommendBottomsheet(),
          if (mapProvider.isStartTrackingBottomSheetVisible)
            StartTrackingBottomsheet(),
        ],
      ),
    );
  }
}
