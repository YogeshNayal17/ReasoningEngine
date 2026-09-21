import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ClaimSource { instagram, facebook, whatsapp }

extension ClaimSourceLabel on ClaimSource {
  String get label => switch (this) {
        ClaimSource.instagram => 'Instagram Link',
        ClaimSource.facebook => 'Facebook Link',
        ClaimSource.whatsapp => 'WhatsApp Message',
      };

  String get inputHint => switch (this) {
        ClaimSource.instagram => 'Paste Instagram post URL',
        ClaimSource.facebook => 'Paste Facebook post URL',
        ClaimSource.whatsapp => 'Paste or type the WhatsApp message',
      };

  String get apiName => switch (this) {
        ClaimSource.instagram => 'instagram',
        ClaimSource.facebook => 'facebook',
        ClaimSource.whatsapp => 'whatsapp',
      };
}

class ClaimInput {
  const ClaimInput({required this.source, required this.content});
  final ClaimSource source;
  final String content;
}

class ClaimInputNotifier extends Notifier<ClaimInput?> {
  @override
  ClaimInput? build() => null;

  void set(ClaimInput? input) => state = input;
}

final claimInputProvider = NotifierProvider<ClaimInputNotifier, ClaimInput?>(
  ClaimInputNotifier.new,
);
