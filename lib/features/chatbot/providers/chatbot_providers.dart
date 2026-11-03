import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// ── Rule-based response engine ────────────────────────────────────────────────

String _respond(String input) {
  final msg = input.toLowerCase().trim();

  // Greetings
  if (_has(msg, ['bonjour', 'bonsoir', 'salut', 'hello', 'hi', 'coucou'])) {
    return 'Bonjour ! 😊 Je suis MedAssist, votre assistant santé. Comment puis-je vous aider aujourd\'hui ?';
  }

  // How are you
  if (_has(msg, ['comment vas', 'ça va', 'comment allez', 'how are you'])) {
    return 'Je vais bien, merci de demander ! 💜 Et vous, comment vous sentez-vous aujourd\'hui ?';
  }

  // Missed dose
  if (_has(msg, ['oublié', 'oublie', 'manqué', 'manque', 'raté', 'rate', 'missed', 'forgot'])) {
    return 'Ne vous inquiétez pas, cela arrive ! 🌸\n\nSi vous avez oublié une dose, ne doublez jamais la dose suivante. Prenez votre médicament dès que vous vous en souvenez, sauf si c\'est presque l\'heure de la prochaine prise.\n\nEn cas de doute, consultez votre médecin ou votre pharmacien.';
  }

  // Side effects
  if (_has(msg, ['effet', 'effets', 'secondaire', 'side effect', 'reaction', 'réaction', 'allergie', 'allergi'])) {
    return 'Les effets secondaires peuvent être préoccupants. 🤝\n\nSi vous ressentez des effets indésirables après la prise d\'un médicament, notez-les et signalez-les à votre médecin lors de votre prochaine consultation.\n\nEn cas de réaction grave (difficultés à respirer, gonflement, éruption cutanée sévère), appelez le 15 (SAMU) immédiatement.';
  }

  // Pain / feeling bad
  if (_has(msg, ['mal', 'douleur', 'souffre', 'souffrance', 'douloureux', 'pain', 'hurt', 'malade', 'sick', 'fatigue', 'fatigué'])) {
    return 'Je suis désolé d\'apprendre que vous ne vous sentez pas bien. 💙\n\nPrenez soin de vous et reposez-vous. Si la douleur persiste ou s\'aggrave, n\'hésitez pas à contacter votre médecin. Votre santé est la priorité.';
  }

  // Anxiety / stress
  if (_has(msg, ['anxieux', 'anxiété', 'stress', 'angoisse', 'peur', 'inquiet', 'inquiète', 'worried', 'anxious'])) {
    return 'Je comprends votre inquiétude. 🌿\n\nPrenez quelques respirations profondes. Vous n\'êtes pas seul(e). Parler à un proche ou à votre médecin peut beaucoup aider. Je suis là pour vous soutenir.';
  }

  // When to take medication
  if (_has(msg, ['quand', 'heure', 'moment', 'when', 'time', 'prendre', 'take'])) {
    return 'La régularité est clé pour l\'efficacité de vos médicaments. ⏰\n\nEssayez de prendre vos médicaments toujours à la même heure. L\'application MedCare vous envoie des rappels pour ne jamais oublier !\n\nSi vous avez des questions sur les horaires spécifiques, consultez votre ordonnance ou votre médecin.';
  }

  // Storage / conservation
  if (_has(msg, ['conserver', 'conservation', 'stocker', 'stockage', 'ranger', 'store', 'storage', 'garde'])) {
    return 'La bonne conservation de vos médicaments est importante. 🏠\n\nEn général :\n• Conservez-les dans un endroit frais et sec\n• À l\'abri de la lumière et de l\'humidité\n• Hors de portée des enfants\n• Vérifiez toujours la date de péremption\n\nCertains médicaments nécessitent le réfrigérateur — vérifiez la notice.';
  }

  // Dose / dosage
  if (_has(msg, ['dose', 'dosage', 'combien', 'quantité', 'how much', 'mg', 'comprimé', 'pilule'])) {
    return 'Il est très important de respecter la dose prescrite par votre médecin. 💊\n\nNe modifiez jamais votre dosage sans en parler d\'abord à votre médecin ou pharmacien. Si vous pensez que votre dose n\'est plus adaptée, prenez rendez-vous pour en discuter.';
  }

  // Interaction between medications
  if (_has(msg, ['interaction', 'ensemble', 'mélange', 'mélanger', 'combine', 'together', 'avec', 'autre médicament'])) {
    return 'Les interactions médicamenteuses sont importantes à connaître. ⚠️\n\nN\'associez jamais des médicaments sans l\'avis de votre médecin ou pharmacien, même des médicaments en vente libre.\n\nVotre pharmacien peut vérifier les interactions de votre traitement gratuitement.';
  }

  // Thank you
  if (_has(msg, ['merci', 'thank', 'thanks', 'super', 'parfait', 'génial'])) {
    return 'Avec plaisir ! 😊 Je suis toujours là si vous avez d\'autres questions. Prenez bien soin de vous ! 💜';
  }

  // Goodbye
  if (_has(msg, ['au revoir', 'bye', 'bonne journée', 'bonne nuit', 'à bientôt', 'ciao'])) {
    return 'Au revoir et prenez bien soin de vous ! 🌸 N\'oubliez pas vos médicaments et à bientôt !';
  }

  // Doctor / appointment
  if (_has(msg, ['médecin', 'docteur', 'rendez-vous', 'consultation', 'doctor', 'appointment', 'hopital', 'hôpital'])) {
    return 'Consulter votre médecin régulièrement est essentiel. 🏥\n\nN\'hésitez pas à noter vos questions avant votre rendez-vous pour ne rien oublier. Votre médecin est votre meilleur allié pour gérer votre traitement.';
  }

  // Emergency
  if (_has(msg, ['urgence', 'emergency', 'secours', 'sos', 'appelle', 'samu', '15', '112'])) {
    return '🚨 En cas d\'urgence médicale, appelez immédiatement le 15 (SAMU) ou le 112.\n\nNe restez pas seul(e). Prévenez un proche ou le voisinage si vous ne pouvez pas appeler vous-même.';
  }

  // What can you do
  if (_has(msg, ['aide', 'help', 'quoi', 'que peux', 'que fais', 'what can', 'comment utiliser'])) {
    return 'Je suis MedAssist, votre assistant santé ! 💜 Je peux vous aider avec :\n\n• Des rappels sur la prise de médicaments\n• Des conseils sur les oublis de dose\n• La conservation de vos médicaments\n• Des informations sur les effets secondaires\n• Du soutien émotionnel\n\nQue souhaitez-vous savoir ?';
  }

  // Default fallback
  debugPrint('[Chatbot] No rule matched for: $input');
  return 'Je vous entends. 💙 Pour des conseils médicaux précis, je vous recommande de consulter votre médecin ou votre pharmacien.\n\nJe peux vous aider avec des questions sur vos médicaments, les oublis de dose, les effets secondaires ou simplement vous soutenir. Comment puis-je vous aider ?';
}

bool _has(String msg, List<String> keywords) =>
    keywords.any((k) => msg.contains(k));

// ── Notifier ──────────────────────────────────────────────────────────────────

class ChatNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() => [];

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    state = [
      ...state,
      ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
    ];

    // Simulate a short thinking delay for a natural feel
    await Future.delayed(const Duration(milliseconds: 600));

    final reply = _respond(text);
    state = [
      ...state,
      ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()),
    ];
  }

  void setGreeting(String text) {
    state = [
      ChatMessage(text: text, isUser: false, timestamp: DateTime.now()),
    ];
  }

  void clearChat() {
    state = [];
  }
}

final chatProvider =
    NotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);
