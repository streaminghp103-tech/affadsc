import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  String _statusLog = "Status: Siap memproses video dengan AI Gemini.";
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
      String naskahVO = dataAi['naskah'];
      
      setState(() {
        _isProcessing = false;
        _statusLog = "SUKSES!\n\nJudul Konten: $judulSEO\n\nNaskah VO: $naskahVO\n\n(Salin naskah ini untuk digunakan sebagai Voice Over di CapCut/Shopee Video).";
      });

    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusLog = "Terjadi kegagalan sistem AI: $e";
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
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 30),
            Container(
              padding: EdgeInsets.all(15),
              color: Colors.black45,
              height: 200,
              child: SingleChildScrollView(child: SelectableText(_statusLog, style: TextStyle(fontFamily: 'monospace', color: Colors.green))),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _isProcessing ? null : _mulaiOtomatisasi,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _isProcessing ? "ROBOT SEDANG BEKERJA..." : "MULAI ANALISIS AI",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
