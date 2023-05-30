import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fibramarciorame',

      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Fibramarciorame'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {


  var markers = [].map((point) => _createMarker(point, Colors.black)).toList();
  late var layer;
  late final SuperclusterMutableController _superclusterController;
  late final AnimatedMapController _animatedMapController;

  @override
  void initState() {
    loadJson();
    _superclusterController = SuperclusterMutableController();
    _animatedMapController = AnimatedMapController(vsync: this);
    super.initState();
  }
  var _mapController = MapController();
  static List<String> list = <String>[
    'ALPIGNANO',
    'AVIGLIANA',
    'BANCHETTE',
    'BARI',
    'BEINASCO',
    'BORGARO TORINESE',
    'BRANDIZZO',
    'BRUINO',
    'CALUSO',
    'CAMBIANO',
    'CATANIA',
    'GENOVA',
    'NAPOLI',
    'MESSINA',
    'PALERMO',
    'PARMA',
    'SENNORI',
    'TORINO',
    'TREMESTIERI ETNEO'
  ];
  String dropdownValue = list.first;
  loadJson() async {
    final String response =
        await rootBundle.loadString('$dropdownValue.json');
    final data = await json.decode(response);
    for (var civ in data) {
      print(civ);
      _superclusterController.add(_createMarker(
          LatLng(double.parse(civ['latitude']), double.parse(civ['longitude'])),
          civ['status'] == "DISPONIBILE" ? Colors.green : Colors.orange));
      markers.add(
        Marker(
            point: LatLng(
                double.parse(civ['latitude']), double.parse(civ['longitude'])),
            width: 50,
            height: 50,
            builder: (context) => IconButton(
                onPressed: () {
                  print("culo");
                },
                icon: Icon(
                  Icons.circle,
                ))),
      );
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        actions: [
          DropdownButton<String>(
            dropdownColor: Colors.blueGrey,
            value: dropdownValue,
              items: list.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      SizedBox(width: 18,),
                      Text(value,style: TextStyle(color:Colors.white),),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? value) {
                // This is called when the user selects an item.
                setState(() {
                  print(value);
                  dropdownValue = value!;
                  changeCity(value);
                });
              }),
          StreamBuilder<SuperclusterState>(
              stream: _superclusterController.stateStream,
              builder: (context, snapshot) {
                final data = snapshot.data;
                final String markerCountLabel;
                if (data == null ||
                    data.loading ||
                    data.aggregatedClusterData == null) {
                  markerCountLabel = '...';
                } else {
                  markerCountLabel =
                      data.aggregatedClusterData!.markerCount.toString();
                }

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 50,left: 40),
                    child: Text('Civici caricati: $markerCountLabel',style: TextStyle(fontSize: 18),),
                  ),
                );
              }),
        ],
        title: Text(widget.title),
      ),
      body: Container(
        child: FlutterMap(
          mapController: _animatedMapController,
          nonRotatedChildren: <Widget>[
            SuperclusterLayer.mutable(
              controller: _superclusterController,
              calculateAggregatedClusterData: true,
              clusterWidgetSize: const Size(40, 40),
              anchor: AnchorPos.align(AnchorAlign.center),
              initialMarkers: markers,
              builder: (BuildContext context, LatLng position, int markerCount,
                  ClusterDataBase? extraClusterData) {
                return Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: Colors.lightBlueAccent),
                  child: Center(
                    child: Text(
                      markerCount.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
              indexBuilder: IndexBuilders.computeWithOriginalMarkers,
            )
          ],
          options: MapOptions(
            maxZoom: 18,
            onMapReady: () {
              _mapController.mapEventStream.listen((evt) {});
              // And any other `MapController` dependent non-movement methods
            },
            center: LatLng(41.90, 12.5),
            zoom: 7,
          ),
          children: [
            //MarkerLayer(markers: markers,),
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
          ],
        ),
      ),
    );
  }
  Future<void> changeCity(String newCity) async {
    final String response =
        await rootBundle.loadString('assets/${newCity.replaceAll(" ", "_")}.json');
    final data = await json.decode(response);

    _superclusterController.clear();
    for (var civ in data) {
      print(civ);
      _superclusterController.add(_createMarker(
          LatLng(double.parse(civ['latitude']), double.parse(civ['longitude'])),
          civ['status'] == "DISPONIBILE" ? Colors.green : Colors.orange));
    }
  }


  static Marker _createMarker(LatLng point, Color color) => Marker(
        anchorPos: AnchorPos.align(AnchorAlign.top),
        rotate: true,
        rotateAlignment: AnchorAlign.top.rotationAlignment,
        height: 30,
        width: 30,
        point: point,
        builder: (ctx) => Icon(
          Icons.circle,
          color: color,
          size: 20,
        ),
      );
}
