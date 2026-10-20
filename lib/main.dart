import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  runApp(const CompressorApp());
}

class CompressorApp extends StatelessWidget {
  const CompressorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vermeil Compressor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.red,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _videoPath;
  bool _isCompressing = false;
  String _quality = '28';
  String _log = '';

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      setState(() {
        _videoPath = result.files.single.path;
        _log = '';
      });
    }
  }

  Future<void> _compressVideo() async {
    if (_videoPath == null) return;
    setState(() {
      _isCompressing = true;
      _log = 'Memproses video...';
    });

    final directory = await getTemporaryDirectory();
    final outputPath = '${directory.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.mp4';
    String command = '-y -i $_videoPath -vcodec libx264 -crf $_quality -preset fast $outputPath';

    await FFmpegKit.executeAsync(command, (session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        setState(() {
          _isCompressing = false;
          _log = 'SUKSES!\nTersimpan di: $outputPath';
        });
        _showAlert('Sukses', 'Video berhasil dikompres!');
      } else {
        setState(() {
          _isCompressing = false;
          _log = 'GAGAL.';
        });
      }
    });
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Compressor'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.movie_filter, size: 80, color: Colors.red[700]),
            const SizedBox(height: 20),
            Text(
              _videoPath == null ? 'Belum ada video' : 'Dipilih: ${_videoPath!.split('/').last}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isCompressing ? null : _pickVideo,
              icon: const Icon(Icons.folder_open),
              label: const Text('Pilih Video'),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _quality,
              items: const [
                DropdownMenuItem(value: '23', child: Text('Kualitas Tinggi (CRF 23)')),
                DropdownMenuItem(value: '28', child: Text('Kualitas Sedang (CRF 28)')),
                DropdownMenuItem(value: '32', child: Text('Ukuran Ekstrem (CRF 32)')),
              ],
              onChanged: (val) => setState(() => _quality = val!),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: (_videoPath != null && !_isCompressing) ? _compressVideo : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              child: _isCompressing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('KOMPRES', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            Text(_log, textAlign: TextAlign.center, style: const TextStyle(color: Colors.greenAccent)),
          ],
        ),
      ),
    );
  }
}
