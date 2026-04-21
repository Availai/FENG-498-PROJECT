import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// AI görüntü analizi ve anlık çevre geçmişi için Hive facade.
/// Widget'lar Hive/Box tiplerine doğrudan bağımlı olmamalı; bu repository
/// üzerinden okur/yazar.
class HistoryRepository {
  HistoryRepository();

  static const _aiAnalysisBoxName = 'recognized_plants';
  static const _quickEnvBoxName = 'agri_history';

  Box get _aiAnalysisBox => Hive.box(_aiAnalysisBoxName);
  Box get _quickEnvBox => Hive.box(_quickEnvBoxName);

  Listenable aiAnalysisListenable() => _aiAnalysisBox.listenable();
  Listenable quickEnvListenable() => _quickEnvBox.listenable();

  int get aiAnalysisCount => _aiAnalysisBox.length;
  int get quickEnvCount => _quickEnvBox.length;

  dynamic aiAnalysisAt(int index) => _aiAnalysisBox.getAt(index);
  dynamic quickEnvAt(int index) => _quickEnvBox.getAt(index);

  Future<void> deleteAiAnalysisAt(int index) => _aiAnalysisBox.deleteAt(index);
  Future<void> deleteQuickEnvAt(int index) => _quickEnvBox.deleteAt(index);
}
