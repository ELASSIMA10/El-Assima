import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  Future<void> _clearOrders(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Vider les commandes ?"),
        content: const Text("Toutes les commandes de maillots seront supprimées définitivement."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ANNULER")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("OUI, TOUT VIDER", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final snapshot = await FirebaseFirestore.instance.collection('orders').get();
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // 4 tabs now
      child: Column(
        children: [
          Container(
            color: Colors.red.shade900,
            child: Row(
              children: [
                const Expanded(
                  child: TabBar(
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(icon: Icon(Icons.checkroom), text: "MAILLOTS"),
                      Tab(icon: Icon(Icons.vpn_key), text: "P. CLÉ"),
                      Tab(icon: Icon(Icons.pie_chart), text: "TAILLES"),
                      Tab(icon: Icon(Icons.map), text: "ZONES"),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  tooltip: "Vider les commandes",
                  onPressed: () => _clearOrders(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('orders').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Erreur."));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final allOrders = snapshot.data!.docs;

                if (allOrders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("Aucune commande pour le moment.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final jerseyOrders = allOrders.where((d) => (d.data() as Map)['product']?.toString().contains('Maillot') ?? false).toList();
                final keychainOrders = allOrders.where((d) => (d.data() as Map)['product']?.toString().contains('Porte-clé') ?? false).toList();

                return TabBarView(
                  children: [
                    _buildOrdersList(jerseyOrders),
                    _buildKeychainOrders(keychainOrders),
                    _buildStatsBySize(jerseyOrders),
                    _buildStatsByZone(allOrders),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeychainOrders(List<QueryDocumentSnapshot> orders) {
    int totalPcs = 0;
    // Group by member to sum quantities
    Map<String, Map<String, dynamic>> memberStats = {};
    for (var doc in orders) {
      final data = doc.data() as Map<String, dynamic>;
      final mId = data['memberId'];
      final q = data['quantity'] ?? 1;
      totalPcs += (q as int);
      
      if (!memberStats.containsKey(mId)) {
        memberStats[mId] = {
          'name': data['memberName'],
          'qty': 0,
          'zone': data['zone'],
          'docId': doc.id,
        };
      }
      memberStats[mId]!['qty'] += q;
    }

    final members = memberStats.values.toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.amber.shade100,
          child: Text(
            "TOTAL PORTE-CLÉS : $totalPcs PIÈCES",
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final m = members[index];
              final mId = memberStats.keys.elementAt(index);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.vpn_key, color: Colors.black, size: 16)),
                  title: Text(m['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("ID: $mId • Zone ${m['zone']}"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15)),
                    child: Text("${m['qty']} PCS", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList(List<QueryDocumentSnapshot> orders) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.red.shade50,
          child: Text(
            "TOTAL MAILLOTS : ${orders.length}",
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.red),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
        final doc = orders[index];
        final data = doc.data() as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.black, child: Icon(Icons.person, color: Colors.white)),
            title: Text(data['memberName'] ?? 'Inconnu', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("ID: ${data['memberId']} • Zone ${data['zone']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    data['size'] ?? '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Annuler cette commande ?"),
                        content: Text("Voulez-vous supprimer la commande de ${data['memberName']} ?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("NON")),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("OUI", style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await FirebaseFirestore.instance.collection('orders').doc(doc.id).delete();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
            ),
          ),
        ],
      );
    }

  Widget _buildStatsBySize(List<QueryDocumentSnapshot> orders) {
    Map<String, int> stats = {};
    for (var doc in orders) {
      final size = (doc.data() as Map<String, dynamic>)['size'] ?? 'Unknown';
      stats[size] = (stats[size] ?? 0) + 1;
    }

    final sortedSizes = ['S', 'M', 'L', 'XL', 'XXL'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text("TOTAL GÉNÉRAL PAR TAILLE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        ...sortedSizes.map((size) {
          final count = stats[size] ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
            child: ListTile(
              title: Text("Taille $size", style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text("$count", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.red)),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatsByZone(List<QueryDocumentSnapshot> orders) {
    // Map<Zone, Map<ProductType, Count>>
    Map<int, Map<String, int>> zoneProductStats = {};
    // Map<Zone, Map<Size, Count>> for Jerseys
    Map<int, Map<String, int>> zoneSizeStats = {};
    
    for (var doc in orders) {
      final data = doc.data() as Map<String, dynamic>;
      final zone = data['zone'] ?? 0;
      final product = data['product']?.toString() ?? 'Inconnu';
      
      zoneProductStats.putIfAbsent(zone, () => {'Maillots': 0, 'Porte-clés': 0});
      if (product.contains('Maillot')) {
        zoneProductStats[zone]!['Maillots'] = (zoneProductStats[zone]!['Maillots'] ?? 0) + 1;
        
        final size = data['size'] ?? 'Unknown';
        zoneSizeStats.putIfAbsent(zone, () => {});
        zoneSizeStats[zone]![size] = (zoneSizeStats[zone]![size] ?? 0) + 1;
      } else if (product.contains('Porte-clé')) {
        final qty = data['quantity'] ?? 1;
        zoneProductStats[zone]!['Porte-clés'] = (zoneProductStats[zone]!['Porte-clés'] ?? 0) + (qty as int);
      }
    }

    final sortedZones = zoneProductStats.keys.toList()..sort();
    final sortedSizes = ['S', 'M', 'L', 'XL', 'XXL'];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedZones.length,
      itemBuilder: (context, index) {
        final zone = sortedZones[index];
        final products = zoneProductStats[zone]!;
        final sizes = zoneSizeStats[zone] ?? {};

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("ZONE $zone", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                    const Icon(Icons.location_on, color: Colors.red),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    _buildMiniStat("MAILLOTS", products['Maillots'] ?? 0, Colors.red),
                    const SizedBox(width: 20),
                    _buildMiniStat("P. CLÉS", products['Porte-clés'] ?? 0, Colors.amber.shade700),
                  ],
                ),
                if (products['Maillots']! > 0) ...[
                  const SizedBox(height: 16),
                  const Text("DÉTAIL TAILLES :", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sortedSizes.map((size) {
                      final count = sizes[size] ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: count > 0 ? Colors.black : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "$size: $count",
                          style: TextStyle(color: count > 0 ? Colors.white : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text("$value", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}
