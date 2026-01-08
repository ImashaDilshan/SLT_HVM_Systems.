import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:slt_hire_log/blocks/map_district_cubit.dart';

class MapDistrictPicker extends StatefulWidget {
  const MapDistrictPicker({super.key});

  @override
  State<MapDistrictPicker> createState() => _MapDistrictPickerState();
}

class _MapDistrictPickerState extends State<MapDistrictPicker> {
  List<_DistrictPolygon> polygons = [];

  @override
  void initState() {
    super.initState();
    loadMap();
  }

  Future<void> loadMap() async {
    final jsonString = await rootBundle.loadString('assets/gadm41_LKA_1.json');
    final geo = json.decode(jsonString);
    final List features = geo['features'];
    final loaded = <_DistrictPolygon>[];

    for (final f in features) {
      final name = f['properties']['NAME_1'];
      final geometry = f['geometry'];
      final type = geometry['type'];

      if (type == 'Polygon') {
        final coords = geometry['coordinates'][0];
        final points = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
        if (points.first != points.last) points.add(points.first);
        loaded.add(_DistrictPolygon(name: name, points: points));
      } else if (type == 'MultiPolygon') {
        for (final part in geometry['coordinates']) {
          final coords = part[0];
          final points = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
          if (points.first != points.last) points.add(points.first);
          loaded.add(_DistrictPolygon(name: name, points: points));
        }
      }
    }

    setState(() => polygons = loaded);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapDistrictCubit, String?>(
      builder: (context, selectedDistrict) {
        return FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(7.8731, 80.7718),
            backgroundColor: Colors.transparent,
            initialZoom: 6.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
            onTap: (_, latlng) {
              for (var poly in polygons) {
                if (_pointInPolygon(latlng, poly.points)) {
                  context.read<MapDistrictCubit>().selectDistrict(poly.name);
                  break;
                }
              }
            },
          ),
          children: [
            
            PolygonLayer(
              polygons:
                  polygons.map((p) {
                    final isSelected = p.name == selectedDistrict;
                    return Polygon(
                      points: p.points,
                      color:
                          isSelected
                              ? Colors.green.withOpacity(0.5)
                              : Colors.blue.withOpacity(0.2),
                      borderColor: const Color.fromARGB(99, 10, 66, 122),
                      borderStrokeWidth: 1,
                    );
                  }).toList(),
            ),
          ],
        );
      },
    );
  }

  bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int i = 0; i < polygon.length - 1; i++) {
      LatLng a = polygon[i];
      LatLng b = polygon[i + 1];
      if (((a.latitude > point.latitude) != (b.latitude > point.latitude)) &&
          (point.longitude <
              (b.longitude - a.longitude) *
                      (point.latitude - a.latitude) /
                      (b.latitude - a.latitude) +
                  a.longitude)) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1;
  }
}

class _DistrictPolygon {
  final String name;
  final List<LatLng> points;

  _DistrictPolygon({required this.name, required this.points});
}
