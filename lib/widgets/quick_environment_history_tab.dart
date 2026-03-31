import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class QuickEnvironmentHistoryTab extends StatelessWidget {
  const QuickEnvironmentHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('agri_history');
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box b, _) {
        if (b.isEmpty) {
          return const Center(
              child: Text('Kaydedilmiş anlık çevre analizi yok.'));
        }
        return ListView.builder(
          itemCount: b.length,
          reverse: true,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, i) {
            final item = b.getAt(i);
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.wb_sunny_outlined,
                      color: Colors.blue.shade700, size: 28),
                ),
                title: Text(
                  item['date'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '📍 ${item['location']}\n🌡️ ${item['temp']}   🌿 pH: ${item['ph']}',
                    style: TextStyle(height: 1.4, color: Colors.grey.shade700),
                  ),
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => b.deleteAt(i),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
