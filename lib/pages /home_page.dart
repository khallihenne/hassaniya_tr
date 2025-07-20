import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
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

  @override
  void initState() {
    super.initState();
    chargerMots();
    _traductionController.addListener(() {
      setState(() {
        estArabe = contientArabe(_traductionController.text);
      });
    });
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
      });
    }
  }

  bool contientArabe(String texte) {
    final regexArabe = RegExp(r'[\u0600-\u06FF]');
    return regexArabe.hasMatch(texte);
  }

  Future<void> choisirFichierAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        audioFile = File(result.files.single.path!);
      });

      // 🔁 ici tu fais ton upload vers Firebase Storage (hors de ce fichier),
      // puis tu obtiens une URL, que tu passes à la méthode suivante :

      // String audioUrl = 'https://your-audio-url-from-storage.com'; // <== à remplacer

      await UploadService.enregistrerTraduction(
        mot: motActuel,
        texte: _traductionController.text,
        langue: estArabe ? 'arabe' : 'latin',
        audioFile: audioFile,
      );

      afficherMotAleatoire(); // passe au mot suivant
    }
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
                  icon: const Icon(Icons.mic, color: Colors.orange),
                  onPressed: choisirFichierAudio, // déclenche l'enregistrement audio
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
          ],
        ),
      ),
    );
  }
}
