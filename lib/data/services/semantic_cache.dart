import '../../domain/models/incident_analysis.dart';

class SemanticCacheEntry {
  final String normalizedText;
  final Set<String> tokens;
  final IncidentAnalysis analysis;
  final String rawJson;
  final DateTime createdAt;

  SemanticCacheEntry({
    required this.normalizedText,
    required this.tokens,
    required this.analysis,
    required this.rawJson,
    required this.createdAt,
  });
}

class SemanticCache {
  final List<SemanticCacheEntry> _entries = [];
  final double similarityThreshold;

  SemanticCache({this.similarityThreshold = 0.45});

  int get size => _entries.length;

  static final Set<String> _stopWords = {
    'de', 'a', 'o', 'que', 'e', 'do', 'da', 'em', 'um', 'para', 'com',
    'nao', 'não', 'uma', 'os', 'no', 'se', 'na', 'por', 'mais', 'as',
    'dos', 'como', 'mas', 'ao', 'ele', 'das', 'seu', 'sua', 'ou', 'quando',
    'muito', 'nos', 'já', 'eu', 'também', 'só', 'pelo', 'pela', 'até',
    'the', 'is', 'at', 'which', 'on', 'and', 'an', 'in', 'to', 'for',
    'devido', 'devida',
  };

  /// Normaliza texto e extrai conjunto de tokens/stems semânticos significativos
  Set<String> _extractTokens(String text) {
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2 && !_stopWords.contains(t));

    final Set<String> tokens = {};
    for (final word in words) {
      tokens.add(_stem(word));
    }
    return tokens;
  }

  /// Stemmer heurístico leve para termos técnicos em PT/EN
  String _stem(String word) {
    String w = word;
    if (w == 'aplicativo' || w == 'aplicação' || w == 'aplicacao') return 'app';
    if (w.startsWith('cancel')) return 'cancel';
    if (w.startsWith('lentid') || w.startsWith('lent')) return 'lent';
    if (w.startsWith('solicit') || w.startsWith('ped')) return 'ped';
    if (w.startsWith('reembols')) return 'reembols';
    if (w.startsWith('falh')) return 'falh';
    if (w.startsWith('crash')) return 'crash';

    // Remoção de sufixos usuais
    final suffixes = ['mente', 'mento', 'ando', 'endo', 'indo', 'adas', 'ados', 'ada', 'ado', 'es', 's'];
    for (final s in suffixes) {
      if (w.endsWith(s) && w.length - s.length >= 3) {
        return w.substring(0, w.length - s.length);
      }
    }
    return w;
  }

  /// Calcula o coeficiente de similaridade Jaccard entre dois conjuntos de tokens
  double _calculateJaccardSimilarity(Set<String> setA, Set<String> setB) {
    if (setA.isEmpty && setB.isEmpty) return 1.0;
    if (setA.isEmpty || setB.isEmpty) return 0.0;
    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    return intersection / union;
  }

  /// Procura uma resposta semanticamente compatível no cache em memória
  SemanticCacheEntry? lookup(String text) {
    final queryTokens = _extractTokens(text);
    if (queryTokens.isEmpty) return null;

    SemanticCacheEntry? bestMatch;
    double highestScore = 0.0;

    for (final entry in _entries) {
      final score = _calculateJaccardSimilarity(queryTokens, entry.tokens);
      if (score > highestScore) {
        highestScore = score;
        bestMatch = entry;
      }
    }

    if (highestScore >= similarityThreshold && bestMatch != null) {
      return bestMatch;
    }

    return null;
  }

  /// Salva uma nova entrada no cache
  void put({
    required String text,
    required IncidentAnalysis analysis,
    required String rawJson,
  }) {
    final tokens = _extractTokens(text);
    // Remove duplicados de texto idêntico
    _entries.removeWhere((e) => e.tokens == tokens);
    _entries.insert(
      0,
      SemanticCacheEntry(
        normalizedText: text,
        tokens: tokens,
        analysis: analysis,
        rawJson: rawJson,
        createdAt: DateTime.now(),
      ),
    );

    // Mantém no máximo 50 entradas mais recentes
    if (_entries.length > 50) {
      _entries.removeLast();
    }
  }

  void clear() {
    _entries.clear();
  }
}
