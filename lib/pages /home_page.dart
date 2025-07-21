import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../services/upload.dart';
// ⚠️ important

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _traductionController = TextEditingController();
  List<String> mots = [];
  String motActuel = '';
  bool estArabe = false;
  File? audioFile;
  bool _isRecording = false;
  String? _tempAudioPath;
  AudioRecorder? _record;

  @override
  void initState() {
    super.initState();
    _record = AudioRecorder();
    chargerMots();
    _traductionController.addListener(() {
      setState(() {
        estArabe = contientArabe(_traductionController.text);
      });
    });
  }

  @override
  void dispose() {
    _record?.dispose();
    _traductionController.dispose();
    super.dispose();
  }

  void chargerMots() async {
    final csv = await rootBundle.loadString('assets/mots.csv');
    setState(() {
      mots = LineSplitter.split(csv).toList();
      afficherMotAleatoire();
    });
  }

  void afficherMotAleatoire() {
    if (mots.isNotEmpty) {
      final random = Random();
      String nouveauMot;
      do {
        nouveauMot = mots[random.nextInt(mots.length)];
      } while (nouveauMot == motActuel && mots.length > 1);
      setState(() {
        motActuel = nouveauMot;
        _traductionController.clear();
        audioFile = null;
        estArabe = false;
        _isRecording = false;
      });
    }
  }

  bool contientArabe(String texte) {
    final regexArabe = RegExp(r'[\u0600-\u06FF]');
    return regexArabe.hasMatch(texte);
  }

  Future<void> _startRecording() async {
    if (_record != null && await _record!.hasPermission()) {
      final tempDir = await getTemporaryDirectory();
      _tempAudioPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
      if (_tempAudioPath != null) {
        await _record!.start(
          const RecordConfig(),
          path: _tempAudioPath!,
        );
        setState(() => _isRecording = true);
      }
        
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied for recording')));
    }
  }

  Future<void> _stopRecording() async {
    if (_record != null) {
      final path = await _record!.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        audioFile = File(path);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio recorded successfully')));
      }
    }
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  Future<void> _saveAndNext() async {
    if (_isRecording) {
      await _stopRecording();
    }
    final String texte = _traductionController.text;
    if (texte.isEmpty && audioFile == null) {
      return;
    }
    final String langue = texte.isEmpty ? 'arabe' : (estArabe ? 'arabe' : 'latin');
    await UploadService.enregistrerTraduction(
      mot: motActuel,
      texte: texte,
      langue: langue,
      audioFile: audioFile,
    );
    afficherMotAleatoire();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 252, 248),
      appBar: AppBar(
        title: const Text('Traduction Hassaniya'),
        backgroundColor: Colors.teal[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'Mot à traduire :',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              motActuel,
              style: GoogleFonts.amiri(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: afficherMotAleatoire,
              child: const Text('🔁 Nouveau mot'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _traductionController,
              decoration: InputDecoration(
                hintText: 'Écrire la traduction ici…',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: _isRecording ? Colors.red : Colors.orange,
                  ),
                  onPressed: _toggleRecording,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              estArabe ? 'Langue détectée : Arabe' : 'Langue détectée : Latin',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: estArabe ? Colors.deepPurple : Colors.brown,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (_traductionController.text.isNotEmpty || audioFile != null || _isRecording)
                  ? _saveAndNext
                  : null,
              child: const Text('Save and Next'),
            ),
          ],
        ),
      ),
    );
  }
}