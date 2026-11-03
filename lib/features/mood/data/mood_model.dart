class MoodEntry {
  final String emoji;
  final String key;
  final String labelFr;
  final String labelEn;

  const MoodEntry({
    required this.emoji,
    required this.key,
    required this.labelFr,
    required this.labelEn,
  });

  static const List<MoodEntry> moods = [
    MoodEntry(emoji: '😊', key: 'great', labelFr: 'Très bien', labelEn: 'Great'),
    MoodEntry(emoji: '😐', key: 'ok', labelFr: 'Bien', labelEn: 'Good'),
    MoodEntry(emoji: '😔', key: 'bad', labelFr: 'Pas bien', labelEn: 'Not well'),
  ];
}
