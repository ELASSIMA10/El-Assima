import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ScannerPlatformImplementation extends StatefulWidget {
  const ScannerPlatformImplementation({super.key});

  @override
  State<ScannerPlatformImplementation> createState() => _ScannerPlatformImplementationState();
}

class _ScannerPlatformImplementationState extends State<ScannerPlatformImplementation> {
  String _scanResult = "Le scanner OCR automatique n'est pas disponible sur Web.\n\nVeuillez utiliser la recherche manuelle ci-dessous.";
  bool _showSuccessOverlay = false;
  bool _showErrorOverlay = false;

  Future<void> _showManualSearchDialog() async {
    final TextEditingController searchController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Recherche Manuelle"),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: "Matricule (Ex: AC010)",
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ANNULER")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, searchController.text.trim()),
            child: const Text("RECHERCHER"),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      _verifyMember([result]);
    }
  }

  Future<void> _verifyMember(List<String> candidates) async {
    try {
      DocumentSnapshot? foundDoc;
      setState(() => _scanResult = "Vérification en cours...");

      for (var rawId in candidates) {
        final searchId = rawId.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
        if (searchId.isEmpty) continue;
        var querySnapshot = await FirebaseFirestore.instance.collection('members').where('cardId', isEqualTo: searchId).get();
        if (querySnapshot.docs.isNotEmpty) {
          foundDoc = querySnapshot.docs.first;
          break;
        }
        querySnapshot = await FirebaseFirestore.instance.collection('members').where('matricule', isEqualTo: searchId).get();
        if (querySnapshot.docs.isNotEmpty) {
          foundDoc = querySnapshot.docs.first;
          break;
        }
      }

      if (foundDoc != null) {
        final data = foundDoc.data() as Map<String, dynamic>;
        final String foundName = data['name'] ?? 'Supporter';
        final String foundZone = (data['zone'] ?? '?').toString();
        final String foundMatricule = data['matricule'] ?? data['cardId'] ?? '?';
        
        if (data['is_present'] ?? false) {
          setState(() {
            _showErrorOverlay = true;
            _scanResult = "⚠️ DÉJÀ ENTRÉ !\n\nNOM : $foundName\nZONE : $foundZone";
          });
          Future.delayed(const Duration(seconds: 4), () => setState(() => _showErrorOverlay = false));
          return;
        }

        await foundDoc.reference.update({'is_present': true, 'last_scanned': FieldValue.serverTimestamp()});
        await FirebaseFirestore.instance.collection('scans_history').add({
          'name': foundName, 'cardId': foundMatricule, 'zone': foundZone, 'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          _showSuccessOverlay = true;
          _scanResult = "✅ ENTRÉ AUTORISÉE\n\n$foundName\nZONE : $foundZone";
        });
        Future.delayed(const Duration(seconds: 3), () => setState(() => _showSuccessOverlay = false));
      } else {
        setState(() {
          _showErrorOverlay = true;
          _scanResult = "❌ AUCUN MEMBRE TROUVÉ\n\nMatricule : ${candidates.first}";
        });
        Future.delayed(const Duration(seconds: 4), () => setState(() => _showErrorOverlay = false));
      }
    } catch (e) {
      if (mounted) setState(() => _scanResult = "Erreur système : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    _scanResult,
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: _scanResult.contains("✅") ? Colors.green : (_scanResult.contains("❌") ? Colors.red : Colors.black)
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: _showManualSearchDialog,
                    icon: const Icon(Icons.search),
                    label: const Text("RECHERCHE MANUELLE", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(250, 60),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showSuccessOverlay) Positioned.fill(child: Container(color: Colors.green.withOpacity(0.6), child: const Center(child: Icon(Icons.check_circle, color: Colors.white, size: 100)))),
          if (_showErrorOverlay) Positioned.fill(child: Container(color: Colors.red.withOpacity(0.6), child: const Center(child: Icon(Icons.cancel, color: Colors.white, size: 100)))),
        ],
      ),
    );
  }
}
