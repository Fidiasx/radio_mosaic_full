import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const RadioApp());
}

class Station {
  final String name;
  final String logo;
  final String url;

  const Station({
    required this.name,
    required this.logo,
    required this.url,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'logo': logo,
        'url': url,
      };

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      name: json['name'] ?? '',
      logo: json['logo'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class RadioApp extends StatelessWidget {
  const RadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Radio Mosaic Premium',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E0B14),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0E0B14),
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioPlayer player = AudioPlayer();
  final TextEditingController searchController = TextEditingController();

  int? current;
  bool isPlaying = false;
  String search = '';

  final List<Station> catalog = [
    const Station(
      name: 'LOS40',
      logo: 'https://los40.com/favicon.ico',
      url: 'https://playerservices.streamtheworld.com/api/livestream-redirect/LOS40.mp3',
    ),
    const Station(
      name: 'COPE',
      logo: 'https://www.cope.es/favicon.ico',
      url: 'https://flucast-b02-04.flumotion.com/cope/net1.mp3',
    ),
    const Station(
      name: 'Rock FM',
      logo: 'https://www.rockfm.fm/favicon.ico',
      url: 'https://rockfm-cope-rrcast.flumotion.com/cope/rockfm-low.mp3',
    ),
    const Station(
      name: 'Cadena SER',
      logo: 'https://cadenaser.com/favicon.ico',
      url: 'https://playerservices.streamtheworld.com/api/livestream-redirect/CADENASER.mp3',
    ),
    const Station(
      name: 'Kiss FM',
      logo: 'https://www.kissfm.es/favicon.ico',
      url: 'https://bbkissfm.kissfmradio.cires21.com/bbkissfm.mp3',
    ),
    const Station(
      name: 'Europa FM',
      logo: 'https://www.europafm.com/favicon.ico',
      url: 'https://livefastly-webs.europafm.com/europafm/audio/chunklist.m3u8',
    ),
    const Station(
      name: 'Onda Cero',
      logo: 'https://www.ondacero.es/favicon.ico',
      url: 'https://livefastly-webs.ondacero.es/ondacero/audio/chunklist.m3u8',
    ),
    const Station(
      name: 'Radio Marca',
      logo: 'https://www.marca.com/favicon.ico',
      url: 'https://playerservices.streamtheworld.com/api/livestream-redirect/RADIOMARCA_NACIONAL.mp3',
    ),
  ];

  List<Station> mosaic = [];

  @override
  void initState() {
    super.initState();
    loadMosaic();
  }

  Future<void> loadMosaic() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('mosaic');

    if (saved == null) {
      mosaic = catalog.take(4).toList();
    } else {
      final decoded = jsonDecode(saved) as List;
      mosaic = decoded.map((e) => Station.fromJson(e)).toList();
    }

    setState(() {});
  }

  Future<void> saveMosaic() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'mosaic',
      jsonEncode(mosaic.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> playStation(int index) async {
    try {
      await player.stop();
      await player.setUrl(mosaic[index].url);
      await player.play();

      setState(() {
        current = index;
        isPlaying = true;
      });
    } catch (e) {
      showMessage('No se pudo reproducir esta emisora');
    }
  }

  Future<void> togglePlay() async {
    if (current == null) return;

    if (isPlaying) {
      await player.pause();
    } else {
      await player.play();
    }

    setState(() {
      isPlaying = !isPlaying;
    });
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  void openStationSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF17131F),
      isScrollControlled: true,
      builder: (_) {
        final filtered = catalog
            .where((s) => s.name.toLowerCase().contains(search.toLowerCase()))
            .toList();

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  children: [
                    const Text(
                      'Buscar emisora',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'LOS40, COPE, SER...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => search = value);
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: filtered.map((station) {
                          return Card(
                            child: ListTile(
                              leading: stationLogo(station.logo, 42),
                              title: Text(station.name),
                              subtitle: Text(
                                station.url,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle),
                                onPressed: () async {
                                  if (!mosaic.any((e) => e.name == station.name)) {
                                    setState(() => mosaic.add(station));
                                    await saveMosaic();
                                    showMessage('${station.name} añadida al mosaico');
                                  }
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: openManualAdd,
                      icon: const Icon(Icons.edit),
                      label: const Text('Añadir emisora manual'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void openManualAdd() {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final logoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Nueva emisora'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(labelText: 'URL streaming'),
                ),
                TextField(
                  controller: logoCtrl,
                  decoration: const InputDecoration(labelText: 'URL logo'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || urlCtrl.text.isEmpty) {
                  showMessage('Falta nombre o URL');
                  return;
                }

                final station = Station(
                  name: nameCtrl.text.trim(),
                  url: urlCtrl.text.trim(),
                  logo: logoCtrl.text.trim(),
                );

                setState(() => mosaic.add(station));
                await saveMosaic();

                if (context.mounted) Navigator.pop(context);
                showMessage('Emisora añadida');
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Widget stationLogo(String logo, double size) {
    if (logo.isEmpty) {
      return Icon(Icons.radio, size: size);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        logo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.radio, size: size),
      ),
    );
  }

  @override
  void dispose() {
    player.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = current == null ? null : mosaic[current!];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Radio Mosaic Premium',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: openStationSelector,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: mosaic.isEmpty
                ? const Center(child: Text('Añade emisoras al mosaico'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: mosaic.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) {
                      final station = mosaic[index];
                      final selected = current == index;

                      return GestureDetector(
                        onTap: () => playStation(index),
                        onLongPress: () async {
                          setState(() {
                            mosaic.removeAt(index);
                            if (current == index) current = null;
                          });
                          await saveMosaic();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? const LinearGradient(
                                    colors: [Color(0xFF4A90E2), Color(0xFF6B5BFF)],
                                  )
                                : null,
                            color: selected ? null : const Color(0xFF1C1C1F),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(0.35),
                                      blurRadius: 18,
                                    )
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              stationLogo(station.logo, 72),
                              const SizedBox(height: 14),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  station.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (selected)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Icon(Icons.graphic_eq),
                                ),
                            ],
                          ),
                        ).animate().fadeIn(),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                if (active != null) stationLogo(active.logo, 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    active?.name ?? 'Selecciona una emisora',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  iconSize: 34,
                  icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
                  onPressed: togglePlay,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
