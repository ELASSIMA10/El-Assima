import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MembersListScreen extends StatelessWidget {
  const MembersListScreen({super.key});

  Future<void> _seedInitialMembers() async {
    final collection = FirebaseFirestore.instance.collection('members');
    final snapshot = await collection.get();
    
    if (snapshot.docs.isEmpty) {
      await collection.add({
        'name': 'Laroui Souheib',
        'cardId': 'ac001',
        'is_present': false,
        'matricule': 'ac001',
      });
      await collection.add({
        'name': 'Lafri Nabil',
        'cardId': 'ac010',
        'is_present': false,
        'matricule': 'ac010',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Attempt seeding when building
    _seedInitialMembers();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: Colors.red.shade900,
          child: const Text(
            "MEMBRES ZONE 14",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('members').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text("Erreur de chargement des données."));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final members = snapshot.data!.docs;

              if (members.isEmpty) {
                return const Center(
                  child: Text(
                    "Aucun membre dans la base de données.",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index].data() as Map<String, dynamic>;
                  final String name = member['name'] ?? 'Inconnu';
                  final String cardId = member['cardId'] ?? 'Pas d\'ID';
                  final bool isPresent = member['is_present'] ?? false;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPresent ? Colors.green : Colors.red,
                        child: Icon(
                          isPresent ? Icons.check : Icons.close,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Text("ID: $cardId"),
                      trailing: Text(
                        isPresent ? "PRÉSENT" : "ABSENT",
                        style: TextStyle(
                          color: isPresent ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
