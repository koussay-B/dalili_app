import 'package:flutter/material.dart';
import 'database_service.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _formsFuture;

  @override
  void initState() {
    super.initState();
    _formsFuture = DatabaseService().getForms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique des formulaires'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _formsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Aucun formulaire enregistré.'));
          }
          final forms = snapshot.data!;
          return ListView.separated(
            itemCount: forms.length,
            separatorBuilder: (_, __) => Divider(),
            itemBuilder: (context, index) {
              final form = forms[index];
              return ListTile(
                leading: Icon(Icons.assignment_turned_in, color: Colors.teal),
                title: Text(form['name'] ?? 'Nom inconnu'),
                subtitle: Text('Date : ${form['createdAt'] ?? ''}\nProblème : ${form['problemNature'] ?? ''}'),
                isThreeLine: true,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Détail du formulaire'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nom : ${form['name'] ?? ''}'),
                            Text('Âge : ${form['age'] ?? ''}'),
                            Text('Pays : ${form['country'] ?? ''}'),
                            Text('Maladie : ${form['hasDisease'] == 1 ? (form['disease'] ?? 'Oui') : 'Non'}'),
                            Text('Durée des symptômes : ${form['duration'] ?? ''}'),
                            Text('Température : ${form['temperature'] ?? ''}'),
                            Text('Nature du problème : ${form['problemNature'] ?? ''}'),
                            SizedBox(height: 8),
                            Text('Symptômes :', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(form['symptoms'] ?? ''),
                            SizedBox(height: 8),
                            Text('Réponse AI :', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(form['aiResponse'] ?? ''),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Fermer'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 