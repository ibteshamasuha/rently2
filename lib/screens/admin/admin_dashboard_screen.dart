import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../profile/profile_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final UserModel currentUser;

  const AdminDashboardScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(user: currentUser)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Users',
                    stream: firestore.collection('users').snapshots().map((s) => s.docs.length),
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Apartments',
                    stream: firestore.collection('apartments').snapshots().map((s) => s.docs.length),
                    icon: Icons.apartment,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Requests',
                    stream: firestore.collection('rentalRequests').snapshots().map((s) => s.docs.length),
                    icon: Icons.inbox,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Repairs',
                    stream: firestore.collection('maintenanceRequests').snapshots().map((s) => s.docs.length),
                    icon: Icons.build,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Registered System Users',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final users = snapshot.data?.docs ?? [];

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final data = users[index].data() as Map<String, dynamic>;
                    final uid = users[index].id;
                    final role = data['role'] ?? 'tenant';
                    final name = data['name'] ?? 'Unnamed';
                    final email = data['email'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: role == 'landlord'
                              ? Colors.deepPurple.shade100
                              : (role == 'admin' ? Colors.red.shade100 : Colors.teal.shade100),
                          child: Icon(
                            role == 'landlord'
                                ? Icons.domain
                                : (role == 'admin' ? Icons.shield : Icons.person),
                            color: role == 'landlord'
                                ? Colors.deepPurple
                                : (role == 'admin' ? Colors.red : Colors.teal),
                          ),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$email\nUID: $uid', style: const TextStyle(fontSize: 11)),
                        isThreeLine: true,
                        trailing: Chip(
                          label: Text(
                            role.toString().toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Stream<int> stream;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.stream,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Text(
                '$count',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              );
            },
          ),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
        ],
      ),
    );
  }
}
