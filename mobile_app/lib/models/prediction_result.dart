class PredictionResult {
  final String message;
  final String prediction; // "spam" or "ham"
  final double spamProbability;
  final double hamProbability;
  final List<String> suspiciousKeywords;
  final bool isOfflineFallback;
  final bool isBlockedRule;
  final String? blockedRuleReason;
  final DateTime timestamp;

  PredictionResult({
    required this.message,
    required this.prediction,
    required this.spamProbability,
    required this.hamProbability,
    this.suspiciousKeywords = const [],
    this.isOfflineFallback = false,
    this.isBlockedRule = false,
    this.blockedRuleReason,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isSpam => prediction.toLowerCase() == 'spam' || isBlockedRule;

  factory PredictionResult.fromJson(
    Map<String, dynamic> json,
    String originalMessage, {
    bool isOffline = false,
  }) {
    final keywords = extractKeywords(originalMessage);
    final isBlocked = checkBlockedKeywords(originalMessage, '');

    return PredictionResult(
      message: originalMessage,
      prediction: isBlocked
          ? 'spam'
          : (json['prediction'] as String? ??
              (isOffline ? fallbackPredict(originalMessage) : 'ham')),
      spamProbability: isBlocked
          ? 1.0
          : ((json['spam_probability'] as num?)?.toDouble() ?? 0.0),
      hamProbability: isBlocked
          ? 0.0
          : ((json['ham_probability'] as num?)?.toDouble() ?? 1.0),
      suspiciousKeywords: keywords,
      isOfflineFallback: isOffline,
      isBlockedRule: isBlocked,
      blockedRuleReason: isBlocked ? 'Matched Blocked Sender Rule (MAHABK)' : null,
    );
  }

  static const List<String> defaultBlockedSenders = [
    'mahabk',
    'mahabank',
    'jm-mahabk',
    'ax-mahabk',
    'bk-mahabk',
  ];

  static const List<String> securityTriggers = [
    'free', 'winner', 'won', 'prize', 'urgent', 'claim',
    'reward', 'cash', 'offer', 'click', 'verify', 'account',
    'password', 'bank', 'credit', 'limited', 'congratulations',
    'mahabk', 'mahabank', 'http://', 'https://', 'www.', 'lottery'
  ];

  static bool checkBlockedKeywords(String message, String sender, [List<String>? customBlocklist]) {
    final msgLower = message.toLowerCase();
    final senderLower = sender.toLowerCase();

    final blocklist = [
      ...defaultBlockedSenders,
      if (customBlocklist != null) ...customBlocklist.map((e) => e.toLowerCase()),
    ];

    for (var term in blocklist) {
      if (term.isEmpty) continue;
      if (senderLower.contains(term) || msgLower.contains(term)) {
        return true;
      }
    }
    return false;
  }

  static List<String> extractKeywords(String message) {
    final lower = message.toLowerCase();
    return securityTriggers.where((kw) => lower.contains(kw)).toList();
  }

  static String fallbackPredict(String message) {
    final keywords = extractKeywords(message);
    return keywords.length >= 2 ? 'spam' : 'ham';
  }
}
