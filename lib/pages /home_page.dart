import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../services/upload.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final TextEditingController _traductionController = TextEditingController();
  List<String> mots = [];
  String motActuel = '';
  bool estArabe = false;
  File? audioFile;
  bool _isRecording = false;
  String? _tempAudioPath;
  AudioRecorder? _record;
  String selectedLang = 'fr';

  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _record = AudioRecorder();
    super.initState();

    chargerMots();

    _traductionController.addListener(() {
      setState(() {
        estArabe = contientArabe(_traductionController.text);
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        await _record!.start(const RecordConfig(), path: _tempAudioPath!);
        setState(() => _isRecording = true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied')));
    }
  }

  Future<void> _stopRecording() async {
    if (_record != null) {
      final path = await _record!.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        audioFile = File(path);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio enregistré')));
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
    if (_isRecording) await _stopRecording();

    final texte = _traductionController.text;
    if (texte.isEmpty && audioFile == null) return;

    final langue = texte.isEmpty ? 'arabe' : (estArabe ? 'arabe' : 'latin');
    await UploadService.enregistrerTraduction(
      mot: motActuel,
      texte: texte,
      langue: langue,
      audioFile: audioFile,
    );
    afficherMotAleatoire();
  }

  String tr(String key) {
    final translations = {
      'fr': {
        'title': 'Mot à traduire :',
        'new_word': 'Nouveau mot',
        'lang_detected': 'Langue détectée',
      },
      'en': {
        'title': 'Word to translate:',
        'new_word': 'New word',
        'lang_detected': 'Detected language',
      },
      'ar': {
        'title': 'الكلمة المطلوب ترجمتها :',
        'new_word': 'كلمة جديدة',
        'lang_detected': 'اللغة المكتشفة',
      },
    };
    return translations[selectedLang]?[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final langueText = estArabe
        ? (selectedLang == 'ar' ? 'العربية' : 'Arabe')
        : (selectedLang == 'ar' ? 'لاتينية' : 'Latin');
    final langueColor = estArabe ? Colors.green : Colors.red;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 252, 248),
      appBar: AppBar(
        title: const Text('Traduction Hassaniya'),
        backgroundColor: Colors.teal[700],
        actions: [
          DropdownButton<String>(
            value: selectedLang,
            underline: const SizedBox(),
            icon: const Icon(Icons.language, color: Colors.white),
            dropdownColor: Colors.white,
            onChanged: (value) => setState(() => selectedLang = value!),
            items: const [
              DropdownMenuItem(value: 'fr', child: Text('Français')),
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'ar', child: Text('العربية')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              tr('title'),
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  motActuel,
                  style: GoogleFonts.amiri(fontSize: 40, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: afficherMotAleatoire,
              icon: const Icon(Icons.refresh),
              label: Text(tr('new_word')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _traductionController,
              decoration: InputDecoration(
                hintText: 'Écrire la traduction ici…',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _buildAnimatedMic(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${tr('lang_detected')} : $langueText',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 6,
                  backgroundColor: langueColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (_traductionController.text.isNotEmpty || audioFile != null || _isRecording)
                  ? _saveAndNext
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text('Save and Next'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedMic() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, child) {
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: _isRecording
                ? [
              BoxShadow(
                color: Colors.orange.withOpacity(0.6),
                blurRadius: 10 * _animationController.value + 2,
                spreadRadius: 1.5 * _animationController.value,
              ),
            ]
                : [],
          ),
          child: IconButton(
            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
            color: _isRecording ? Colors.red : Colors.orange,
            onPressed: _toggleRecording,
          ),
        );
      },
    );
  }
}
