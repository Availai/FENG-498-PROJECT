import 'package:flutter/material.dart';
import '../widgets/ai_analysis_history_tab.dart';
import '../widgets/quick_environment_history_tab.dart';

class PlantDatabaseScreen extends StatelessWidget {
  const PlantDatabaseScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kayıtlı Verilerim'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(icon: Icon(Icons.landscape), text: 'AI Görüntü Analizleri'),
              Tab(icon: Icon(Icons.history), text: 'Hızlı Çevre Geçmişi'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AiAnalysisHistoryTab(),
            QuickEnvironmentHistoryTab(),
          ],
        ),
      ),
    );
  }
}
