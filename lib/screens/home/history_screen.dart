import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // NOUVEAU: Import pour le formatage des dates

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupérer l'utilisateur actuel
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Gérer le cas où l'utilisateur n'est pas connecté (même si normalement il devrait l'être)
      return const Center(
        child: Text("Veuillez vous connecter pour voir l'historique."),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Historique d'Analyses"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        // FILTRAGE PAR UTILISATEUR
        stream: FirebaseFirestore.instance
            .collection('gemini_analyses')
            .where(
              'user_id',
              isEqualTo: user
                  .uid, // Utiliser user.uid car on a vérifié qu'il n'est pas null
            )
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Gestion des erreurs d'Index Firestore (très bonne idée de l'inclure !)
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Erreur de chargement. Vérifiez si vous avez créé l'Index dans la console Firebase.\n\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Votre historique est vide. Commencez une nouvelle analyse !",
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.all(15),
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data =
                  doc.data() as Map<String, dynamic>; // Meilleure pratique

              var timestamp = data['date'] as Timestamp?;
              var date = timestamp?.toDate() ?? DateTime.now();

              // Formatage de la date et de l'heure
              String formattedDate = DateFormat(
                'EEEE d MMM yyyy',
                'fr_FR',
              ).format(date); // Ex: "Samedi 31 Janv. 2026"
              String formattedTime = DateFormat(
                'HH:mm',
              ).format(date); // Ex: "21:00"

              // Tenter d'utiliser un titre si disponible, sinon les premières lignes de l'analyse
              String analysisContent =
                  data['analyse'] ?? "Analyse non disponible";

              // Définir un titre (si vous l'avez) ou un sous-titre pertinent
              // Ici, on utilise le début de l'analyse pour le sous-titre

              return Card(
                elevation: 2, // Légère élévation pour un meilleur look
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.teal.shade100, width: 1),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.description, color: Colors.white),
                  ),
                  title: Text(
                    "$formattedDate", // Seulement la date dans le titre
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    analysisContent
                        .replaceAll(RegExp(r'[\r\n]+'), ' ')
                        .trim(), // Remplacer les sauts de ligne pour un meilleur affichage
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  trailing: Text(
                    formattedTime, // L'heure en trailing
                    style: const TextStyle(fontSize: 12, color: Colors.teal),
                  ),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors
                          .transparent, // Pour que le borderRadius soit visible
                      builder: (c) => DraggableScrollableSheet(
                        initialChildSize: 0.8,
                        minChildSize: 0.5,
                        maxChildSize: 0.95,
                        expand: false,
                        builder: (context, scrollController) => Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(25),
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: MarkdownBody(
                              data: analysisContent,
                              styleSheet: MarkdownStyleSheet(
                                // Ajout de style pour le rendu Markdown
                                h1: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                                strong: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
