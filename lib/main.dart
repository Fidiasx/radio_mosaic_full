
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
}

class RadioApp extends StatelessWidget {
  const RadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Radio Mosaic',
      theme: ThemeData.dark(),
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

  int current = 0;

  final stations = const [
    Station(
      name: 'LOS40',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/6/65/LOS40_Logo.svg',
      url: 'https://25543.live.streamtheworld.com/LOS40.mp3',
    ),
    Station(
      name: 'COPE',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/4/4f/COPE_logo.svg',
      url: 'https://flucast-b02-04.flumotion.com/cope/net1.mp3',
    ),
    Station(
      name: 'Rock FM',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/0/06/Rock_FM_logo.svg',
      url: 'https://rockfm-cope-rrcast.flumotion.com/cope/rockfm-low.mp3',
    ),
    Station(
      name: 'Cadena SER',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/2/20/Cadena_SER_logo.svg',
      url: 'https://playerservices.streamtheworld.com/api/livestream-redirect/CADENASER.mp3',
    ),
  ];

  Future<void> play(int index) async {
    await player.setUrl(stations[index].url);
    await player.play();

    setState(() {
      current = index;
    });
  }

  @override
  void initState() {
    super.initState();
    play(0);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = stations[current];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radio Mosaic Premium'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: stations.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final station = stations[index];
                final selected = current == index;

                return GestureDetector(
                  onTap: () => play(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: selected ? Colors.blueGrey : Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          station.logo,
                          height: 90,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          station.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (selected)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Icon(Icons.equalizer),
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
            color: Colors.black87,
            child: Row(
              children: [
                Image.network(
                  active.logo,
                  width: 60,
                  height: 60,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    active.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.pause),
                  onPressed: () async {
                    await player.pause();
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
