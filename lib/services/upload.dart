import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UploadService {
  // Upload un fichier audio vers Firebase Storage et retourne son URL
  static Future<String?> uploaderAudio(File audioFile, String mot) async {
    try {
      final fileName = '${mot}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final ref = FirebaseStorage.instance.ref().child('audios/$fileName');
      await ref.putFile(audioFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Erreur lors de l'upload de l'audio : $e");
      return null;
    }
  }

  // Enregistre une traduction avec texte + audio
  static Future<void> enregistrerTraduction({
    required String mot,
    required String texte,
    required String langue,
    File? audioFile,
  }) async {
    try {
      String? audioUrl;
      if (audioFile != null) {
        audioUrl = await uploaderAudio(audioFile, mot);
      }

      await FirebaseFirestore.instance.collection('traductions').add({
        'mot': mot,
        'traduction': texte,
        'langue': langue,
        'date': DateTime.now().toIso8601String(),
        'audioUrl': audioUrl,
      });
    } catch (e) {
      print("Erreur lors de l'enregistrement dans Firestore : $e");
    }
  }

  // Enregistre une URL audio dans Firestore (sans texte)
  static Future<void> enregistrerDepuisUrlAudio({
    required String mot,
    required String langue,
    required String audioUrl,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('traductions').add({
        'mot': mot,
        'traduction': '',
        'langue': langue,
        'audioUrl': audioUrl,
        'date': DateTime.now().toIso8601String(),
      });
      print("✅ URL audio enregistrée dans Firestore");
    } catch (e) {
      print("Erreur Firestore (enregistrerDepuisUrlAudio) : $e");
    }
  }
}
