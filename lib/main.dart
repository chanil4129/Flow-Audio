import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  print("APP START");
  try {
    await dotenv.load(fileName: "setting.env");
    print("ENV LOADED");
  } catch (e) {
    print("Failed to load .env file: $e");
  }
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int currentUnit = 1;
  final int totalUnits = 200;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((event) {
      // 재생이 완료된 후 다음 UNIT 재생
      if (currentUnit < totalUnits) {
        setState(() {
          currentUnit++;
          _playUnit(currentUnit);
        });
      }
    });
  }

  void _playUnit(int unit) {
    final url = '${dotenv.env['AUDIO_URL']}$unit.mp3';
    _audioPlayer.play(UrlSource(url)); // URL을 재생
    print('Playing UNIT $unit');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('UNIT Player'),
        ),
        body: ListView.builder(
          itemCount: totalUnits,
          itemBuilder: (context, index) {
            int unitNumber = index + 1; // UNIT 번호는 1부터 시작
            return ListTile(
              title: Text('UNIT $unitNumber'),
              onTap: () {
                setState(() {
                  currentUnit = unitNumber; // 선택된 UNIT으로 현재 UNIT 설정
                  _playUnit(currentUnit); // 선택된 UNIT 재생
                });
              },
            );
          },
        ),
      ),
    );
  }
}
