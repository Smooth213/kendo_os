import 'package:flutter_riverpod/flutter_riverpod.dart';

class UiMessage {
  final String id;
  final String text;
  final bool isError;
  
  UiMessage({
    required this.id,
    required this.text,
    this.isError = false,
  });
}

class UiMessageNotifier extends Notifier<UiMessage?> {
  @override
  UiMessage? build() => null;

  void showSuccess(String text) {
    state = UiMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), text: text, isError: false);
  }

  void showError(String text) {
    state = UiMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), text: text, isError: true);
  }
}

final uiMessageProvider = NotifierProvider<UiMessageNotifier, UiMessage?>(() {
  return UiMessageNotifier();
});