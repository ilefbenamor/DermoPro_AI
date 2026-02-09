import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'patient_detail_screen.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>(); // Pour le contrôle de saisie

  final Color colPrimary = const Color(0xFF009688);
  final Color colDark = const Color(0xFF1A3D37);
  String _searchQuery = "";

  // --- CONTRÔLES DE SAISIE (VALIDATION) ---
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return "Name required";
    if (value.trim().length < 2) return "Too short";
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) return "Age required";
    final age = int.tryParse(value);
    if (age == null || age < 0 || age > 120) return "Invalid age (0-120)";
    return null;
  }

  // --- LOGIQUE CRUD : AJOUTER / MODIFIER ---
  void _showPatientDialog({
    String? id,
    String? currentName,
    String? currentAge,
  }) {
    final nameCtrl = TextEditingController(text: currentName);
    final ageCtrl = TextEditingController(text: currentAge);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          id == null ? "New Patient" : "Edit Record",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person),
                ),
                validator: _validateName,
              ),
              TextFormField(
                controller: ageCtrl,
                decoration: const InputDecoration(
                  labelText: "Age",
                  prefixIcon: Icon(Icons.cake),
                ),
                keyboardType: TextInputType.number,
                validator: _validateAge,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final data = {
                  'full_name': nameCtrl.text.trim(),
                  'age': ageCtrl.text.trim(),
                  'last_visit': FieldValue.serverTimestamp(),
                };
                if (id == null) {
                  data['risk_level'] = 'Stable';
                  await FirebaseFirestore.instance
                      .collection('doctors')
                      .doc(user!.uid)
                      .collection('patients')
                      .add(data);
                } else {
                  await FirebaseFirestore.instance
                      .collection('doctors')
                      .doc(user!.uid)
                      .collection('patients')
                      .doc(id)
                      .update(data);
                }
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // --- CONFIRMATION DE SUPPRESSION ---
  void _deletePatient(String id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Record?"),
            content: const Text(
              "This will permanently remove the patient's data.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Keep"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user!.uid)
          .collection('patients')
          .doc(id)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPatientDialog(),
        backgroundColor: colPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doctors')
            .doc(user?.uid)
            .collection('patients')
            .orderBy('last_visit', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final allDocs = snapshot.data!.docs;

          // Stats Dynamiques
          int total = allDocs.length;
          int urgent = allDocs
              .where((d) => (d.data() as Map)['risk_level'] == 'Urgent')
              .length;
          int stable = total - urgent;

          // Recherche Dynamique
          final filteredDocs = allDocs.where((doc) {
            final name = (doc.data() as Map)['full_name']
                .toString()
                .toLowerCase();
            return name.contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              // --- HEADER TEAL ARRONDI ---
              Container(
                padding: const EdgeInsets.only(
                  top: 60,
                  left: 25,
                  right: 25,
                  bottom: 30,
                ),
                decoration: BoxDecoration(
                  color: colPrimary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Welcome back,",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "Dr. ${user?.email?.split('@')[0].toUpperCase()}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search patient...",
                        hintStyle: const TextStyle(color: Colors.white60),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white60,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- STATS CARDS ---
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _statCard(
                      "TOTAL",
                      total.toString(),
                      Icons.group,
                      colPrimary,
                    ),
                    const SizedBox(width: 10),
                    _statCard(
                      "URGENT",
                      urgent.toString(),
                      Icons.warning,
                      Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    _statCard(
                      "STABLE",
                      stable.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ],
                ),
              ),

              // --- LISTE ---
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isUrgent = data['risk_level'] == 'Urgent';

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (dir) async {
                        _deletePatient(doc.id);
                        return false;
                      }, // On gère la suppression via notre dialogue
                      child: GestureDetector(
                        onLongPress: () => _showPatientDialog(
                          id: doc.id,
                          currentName: data['full_name'],
                          currentAge: data['age'],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PatientDetailScreen(
                              patientId: doc.id,
                              patientName: data['full_name'],
                            ),
                          ),
                        ),
                        child: _buildPatientTile(data, isUrgent),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            Text(
              val,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colDark,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientTile(Map<String, dynamic> data, bool isUrgent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colPrimary.withOpacity(0.1),
            child: Text(
              data['full_name'][0],
              style: TextStyle(color: colPrimary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['full_name'],
                  style: TextStyle(fontWeight: FontWeight.bold, color: colDark),
                ),
                Text(
                  "Age: ${data['age']}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isUrgent ? Colors.orange.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isUrgent ? "URGENT" : "STABLE",
              style: TextStyle(
                color: isUrgent ? Colors.orange : Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
