import 'package:flutter/material.dart';
import '../widgets/ai_analysis_history_tab.dart';
import '../widgets/help_panel.dart';
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
          actions: [
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.help_outline_rounded),
                tooltip: 'Yardım',
                onPressed: () =>
                    HelpPanel.show(ctx, HelpContent.plantDatabase),
              ),
            ),
          ],
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
