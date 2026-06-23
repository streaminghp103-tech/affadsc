import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_video/ffmpeg_kit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';
import 'dart:convert';

void main() => runApp(MaterialApp(
      theme: ThemeData.dark(),
      home: AutoAffiliateAndroid(),
    ));

class AutoAffiliateAndroid extends StatefulWidget {
  @override
  _AutoAffiliateAndroidState createState() => _AutoAffiliateAndroidState();
}

class _AutoAffiliateAndroidState extends State<AutoAffiliateAndroid> {
  final _apiController = TextEditingController();
  String? _selectedVideoPath;
  String _statusLog = "Status: Siap memproses video.";
  bool _isProcessing = false;

  Future<void> _pilihVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      setState(() {
        _selectedVideoPath = result.files.single.path;
        _statusLog = "Video Terpilih: ${result.files.single.name}";
      });
    }
  }

  Future<void> _mulaiOtomatisasi() async {
    if (_apiController.text.isEmpty || _selectedVideoPath == null) {
      setState(() => _statusLog = "Kesalahan: API Key atau Video belum diisi!");
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusLog = "Mengunggah & membiarkan AI Gemini menonton video Anda...";
    });

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiController.text);
      final videoBytes = await File(_selectedVideoPath!).readAsBytes();
      
      final prompt = TextPart(
        "Tonton video jualan ini. Lakukan riset SEO Indonesia. "
        "Kembalikan respon hanya dalam bentuk JSON mentah kaku dengan format berikut: "
        "{\"judul\":\"Judul teks pendek ramah SEO di layar\",\"naskah\":\"Naskah voice over persuasif bahasa Indonesia max 30 kata\"}"
      );
      final videoPart = DataPart('video/mp4', videoBytes);
      
      final response = await model.generateContent([Content.multi([prompt, videoPart])]);
      
      final dataAi = jsonDecode(response.text!.replaceAll("```json", "").replaceAll("```", "").trim());
      String judulSEO = dataAi['judul'];
      
      setState(() => _statusLog = "AI Selesai menganalisis! Memulai proses rendering video... Mohon tunggu karena proses ini memakan waktu beberapa menit di background.");

      String outputPath = _selectedVideoPath!.replaceAll(".mp4", "_matang_SEO.mp4");
      String ffmpegCommand = "-i $_selectedVideoPath -vf \"hflip,setpts=0.95*PTS\" -an -ss 00:00:00.5 $outputPath";

      await FFmpegKit.execute(ffmpegCommand).then((session) async {
        final returnCode = await session.getReturnCode();
        if (returnCode!.isValueSuccess()) {
          setState(() {
            _isProcessing = false;
            _statusLog = "SUKSES! Video siap di-upload: $outputPath\n\nJudul Konten: $judulSEO";
          });
        } else {
          setState(() {
            _isProcessing = false;
            _statusLog = "Gagal memproses video di internal sistem HP.";
          });
        }
      });

    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusLog = "Terjadi kegagalan sistem: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Happy Puppy AI - Affiliate Pro")),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _apiController,
              decoration: InputDecoration(
                labelText: "Masukkan API Key Gemini",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
              ),
              obscureText: true,
            ),
            SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: _pilihVideo,
              icon: Icon(Icons.video_collection),
              label: Text("AMBIL VIDEO MENTAH DOUYIN"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), // Perbaikan parameter tinggi tombol 1
              ),
            ),
            SizedBox(height: 30),
            Container(
              padding: EdgeInsets.all(15),
              color: Colors.black45,
              height: 150,
              child: SingleChildScrollView(child: Text(_statusLog, style: TextStyle(fontFamily: 'monospace', color: Colors.green))),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _isProcessing ? null : _mulaiOtomatisasi,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 55), // Perbaikan parameter tinggi tombol 2
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _isProcessing ? "ROBOT SEDANG BEKERJA..." : "MULAI PROSES VIDEO",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
