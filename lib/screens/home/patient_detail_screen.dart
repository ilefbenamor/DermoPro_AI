import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'analysis_screen.dart'; // Assure-toi que c'est le bon import

class PatientDetailScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  // --- FONCTION POUR AFFICHER LE RAPPORT COMPLET ---
  void _viewFullReport(
    BuildContext context,
    Map<String, dynamic> data,
    String date,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Clinical Report",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[900],
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const Divider(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: MarkdownBody(
                    data: data['analysis_result'] ?? "No data available.",
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 15, height: 1.5),
                      h2: TextStyle(
                        color: Colors.teal[700],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const colPrimary = Color(0xFF009688);

    return StreamBuilder<DocumentSnapshot>(
      // ON RÉCUPÈRE LES INFOS DU PATIENT EN TEMPS RÉEL
      stream: FirebaseFirestore.instance
          .collection('doctors')
          .doc(user?.uid)
          .collection('patients')
          .doc(patientId)
          .snapshots(),
      builder: (context, patientSnapshot) {
        if (!patientSnapshot.hasData)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );

        final patientData =
            patientSnapshot.data!.data() as Map<String, dynamic>;
        final String riskLevel = patientData['risk_level'] ?? "Stable";
        final String age = patientData['age'] ?? "N/A";

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFA),
          appBar: AppBar(
            title: const Text(
              "Patient Profile",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: colPrimary,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DoctorHomeScreen(
                  patientId: patientId,
                  patientName: patientName,
                ),
              ),
            ),
            icon: const Icon(Icons.add_a_photo, color: Colors.white),
            label: const Text(
              "New AI Scan",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.orange[800],
          ),
          body: Column(
            children: [
              // --- 1. HEADER DYNAMIQUE ---
              Container(
                padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
                decoration: const BoxDecoration(
                  color: colPrimary,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white24,
                      child: Text(
                        patientName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Age: $age • ID: ${patientId.substring(0, 6).toUpperCase()}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: riskLevel == "Urgent"
                                  ? Colors.red[400]
                                  : Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Status: $riskLevel",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- 2. TITRE HISTORIQUE ---
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.teal[800], size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Clinical History",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[800],
                      ),
                    ),
                  ],
                ),
              ),

              // --- 3. LISTE DES ANALYSES DYNAMIQUE ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('doctors')
                      .doc(user?.uid)
                      .collection('patients')
                      .doc(patientId)
                      .collection('analyses')
                      .orderBy('created_at', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) return _buildEmptyState();

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;

                        // DATE DYNAMIQUE
                        DateTime date =
                            (data['created_at'] as Timestamp?)?.toDate() ??
                            DateTime.now();
                        String formattedDate = DateFormat(
                          'MMM dd, yyyy • HH:mm',
                        ).format(date);

                        String analysis =
                            data['analysis_result'] ?? "No result";
                        String preview = analysis.length > 120
                            ? "${analysis.substring(0, 120)}..."
                            : analysis;

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: Colors.grey[200]!),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.analytics_outlined,
                                      color: colPrimary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (data['type'] == 'comparative')
                                      const Tooltip(
                                        message: "Evolution Scan",
                                        child: Icon(
                                          Icons.compare_arrows,
                                          color: Colors.orange,
                                          size: 18,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  preview,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => _viewFullReport(
                                      context,
                                      data,
                                      formattedDate,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: colPrimary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      "View Full Detailed Report",
                                      style: TextStyle(
                                        color: colPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_late_outlined,
            size: 60,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 15),
          const Text(
            "No medical scans recorded yet.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
