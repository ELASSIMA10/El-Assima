import 'package:cloud_firestore/cloud_firestore.dart';

class DataManager {
  static Future<void> seedInitialMembers() async {
    final collection = FirebaseFirestore.instance.collection('members');
    
    print("Synchronisation des membres avec la base de données...");
    
    // Suppression des IDs de test obsolètes
    await collection.doc('LS001').delete();
    await collection.doc('ID001').delete(); // Suppression de Test User ID001 comme demandé
    
    final List<Map<String, dynamic>> initialData = [
      {
        'cardId': 'AC001',
        'name': 'Laroui Souheib',
        'is_present': false,
        'matricule': 'AC001',
        'zone': 14,
      },
      {
        'cardId': 'AC010',
        'name': 'Lafri Nabil Riad',
        'is_present': false,
        'matricule': 'AC010',
        'zone': 14,
      },
      // Ajoutez ici les autres membres réels si nécessaire
    ];

    if (initialData.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (var member in initialData) {
        batch.set(collection.doc(member['cardId']), {
          ...member,
          'last_scanned': null,
        });
      }
      await batch.commit();
      print("Base de données mise à jour avec les membres réels.");
    }
  }
}
