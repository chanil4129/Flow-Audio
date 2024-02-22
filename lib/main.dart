import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

void main() async {
  await dotenv.load(fileName: "setting.env");
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int currentUnit = 0;
  final int totalUnits = 200;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      // AudioPlayer 상태가 변할 때마다 UI를 갱신
      setState(() {});
    });

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

  Future<String> _getFilePath(int unit) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$unit.mp3';
    return filePath;
  }

  Future<void> _cacheOrPlayUnit(int unit) async {
    final filePath = await _getFilePath(unit);
    final file = File(filePath);

    if (await file.exists()) {
      print('cache UNIT $unit');
      _audioPlayer.play(DeviceFileSource(filePath));
    } else {
      final url = '${dotenv.env['AUDIO_URL']}$unit.mp3';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        print('playing UNIT $unit');
        _audioPlayer.play(DeviceFileSource(filePath));
      }
    }
  }

  void _playUnit(int unit) {
    _cacheOrPlayUnit(unit);
  }

  void _rewind5Seconds() async {
    Duration? currentPosition = await _audioPlayer.getCurrentPosition();
    if (currentPosition != null) { // currentPosition이 null이 아닐 때만 실행
      Duration rewindPosition = currentPosition - Duration(seconds: 5);
      if (rewindPosition < Duration.zero) {
        rewindPosition = Duration.zero;
      }
      _audioPlayer.seek(rewindPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
                  if (currentUnit == unitNumber) {
                    // 이미 실행 중인 유닛을 다시 눌렀을 경우, 시작 지점으로 이동
                    _audioPlayer.seek(Duration.zero);
                    _audioPlayer.resume(); // 시작 지점에서 재생을 재개
                  } else {
                    currentUnit = unitNumber; // 선택된 UNIT으로 현재 UNIT 설정
                    _playUnit(currentUnit); // 선택된 UNIT 재생
                  }
                });
              },
            );
          },
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text('Unit $currentUnit'),
              IconButton(
                icon: Icon(Icons.replay_5),
                onPressed: _rewind5Seconds,
              ),
              IconButton( // Play/Pause 토글 버튼
                icon: Icon(_audioPlayer.state == PlayerState.playing
                    ? Icons.pause
                    : Icons.play_arrow),
                onPressed: () {
                  if (_audioPlayer.state == PlayerState.playing) {
                    _audioPlayer.pause();
                  } else if (_audioPlayer.state == PlayerState.paused) {
                    _audioPlayer.resume();
                  } else {
                    _playUnit(currentUnit);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
