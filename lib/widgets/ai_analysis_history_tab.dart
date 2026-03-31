import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'bottom_sheet_content.dart';

class AiAnalysisHistoryTab extends StatelessWidget {
  const AiAnalysisHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('recognized_plants');
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box b, _) {
        if (b.isEmpty) {
          return const Center(
              child: Text('Henüz bir AI görüntü analizi kaydedilmedi.'));
        }
        return ListView.builder(
          itemCount: b.length,
          reverse: true,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, i) {
            final item = b.getAt(i);
            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: item['type'] == 'plant'
                      ? Colors.green.shade100
                      : Colors.amber.shade100,
                  child: Icon(
                    item['type'] == 'plant' ? Icons.eco : Icons.landscape,
                    color: item['type'] == 'plant'
                        ? Colors.green
                        : Colors.amber.shade900,
                    size: 30,
                  ),
                ),
                title: Text(
                  item['title'] ?? 'Bilinmeyen',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(item['date'],
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => b.deleteAt(i),
                ),
                onTap: () => _showDetails(context, item),
              ),
            );
          },
        );
      },
    );
  }

  void _showDetails(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) =>
            BottomSheetContent(item: item, controller: controller),
      ),
    );
  }
}
