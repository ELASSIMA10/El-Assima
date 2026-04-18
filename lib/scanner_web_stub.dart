import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScannerPlatformImplementation extends StatefulWidget {
  const ScannerPlatformImplementation({super.key});

  @override
  State<ScannerPlatformImplementation> createState() => _ScannerPlatformImplementationState();
}

class _ScannerPlatformImplementationState extends State<ScannerPlatformImplementation> {
  final TextEditingController _searchController = TextEditingController();

  Future<void> _verifyMember(String matricule) async {
    final search = matricule.trim().toUpperCase();
    if (search.isEmpty) return;

    try {
      final docRef = await FirebaseFirestore.instance.collection('members').doc(search).get();

      if (docRef.exists) {
        final data = docRef.data() as Map<String, dynamic>;
        final String foundName = data['name'] ?? 'Supporter';
        final String foundZone = (data['zone'] ?? '?').toString();
        
        if (data['is_present'] ?? false) {
           if (mounted) _showResultDialog("DÉJÀ ENTRÉ", "$foundName (Zone $foundZone)", false);
           return;
        }

        await docRef.reference.update({'is_present': true, 'last_scanned': FieldValue.serverTimestamp()});
        await FirebaseFirestore.instance.collection('scans_history').add({
          'name': foundName,
          'cardId': docRef.id,
          'zone': foundZone,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          _showResultDialog("ACCÈS AUTORISÉ", "$foundName (Zone $foundZone)", true);
          _searchController.clear();
        }
      } else {
        if (mounted) _showResultDialog("ACCÈS REFUSÉ", "Membre Introuvable", false);
      }
    } catch (e) {
      if (mounted) _showResultDialog("ERREUR", "Problème réseau", false);
    }
  }

  void _showResultDialog(String title, String subtitle, bool success) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: success ? Colors.green.shade50 : Colors.red.shade50,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(success ? Icons.check_circle : Icons.error, color: success ? Colors.green : Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: success ? Colors.green : Colors.red)),
            Text(subtitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("FERMER")
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               const Icon(Icons.computer, size: 80, color: Colors.white54),
               const SizedBox(height: 20),
               const Text(
                  "L'Intelligence Artificielle de lecture de texte (OCR) est optimisée pour l'application Mobile.\n\nSur l'interface Web, utilisez la recherche manuelle :",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 16, height: 1.5),
               ),
               const SizedBox(height: 40),
               TextField(
                 controller: _searchController,
                 style: const TextStyle(color: Colors.white, fontSize: 20),
                 textCapitalization: TextCapitalization.characters,
                 decoration: InputDecoration(
                   hintText: "Matricule (ex: AC010)",
                   hintStyle: const TextStyle(color: Colors.white38),
                   prefixIcon: const Icon(Icons.search, color: Colors.red),
                   filled: true,
                   fillColor: Colors.white10,
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                 ),
                 onSubmitted: _verifyMember,
               ),
               const SizedBox(height: 24),
               SizedBox(
                 width: double.infinity,
                 height: 60,
                 child: ElevatedButton(
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                   onPressed: () => _verifyMember(_searchController.text),
                   child: const Text("VÉRIFIER L'ACCÈS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: 1.5)),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }
}
