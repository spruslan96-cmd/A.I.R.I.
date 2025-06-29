import 'dart:async';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:local_ai_chat/models/chat_history.dart' as chat_history;

class GemmaHelper {
  static final GemmaHelper _instance = GemmaHelper._internal();
  factory GemmaHelper() => _instance;
  GemmaHelper._internal();

  InferenceModel? _model;
  InferenceChat? _chat;
  bool _modelLoaded = false;
  final chatHistory = chat_history.ChatHistory();

  Future<void> loadModel(String modelAssetPath) async {
    if (_modelLoaded) return;
    final gemma = FlutterGemmaPlugin.instance;
    final modelManager = gemma.modelManager;

    print("Installing model from asset: $modelAssetPath");

    try {
      await modelManager.installModelFromAsset(modelAssetPath);

      _model = await gemma.createModel(
        modelType: ModelType.gemmaIt,
        preferredBackend: PreferredBackend.gpu,
        maxTokens: 2048,
      );

      _chat = await _model!.createChat(
        temperature: 0.8,
        randomSeed: 1,
        topK: 1,
      );

      _modelLoaded = true;

      // Add system prompt
      chatHistory.addMessage(
          role: chat_history.Role.system, content: _systemPrompt);

      print("Gemma model loaded successfully.");
    } catch (e) {
      print("Error loading Gemma model: $e");
      rethrow;
    }
  }

  Future<Stream<String>> generateText(String prompt) async {
    if (!_modelLoaded || _chat == null) {
      throw Exception("Gemma model not loaded or chat not initialized");
    }

    final controller = StreamController<String>();

    try {
      chatHistory.addMessage(role: chat_history.Role.user, content: prompt);

      final formattedPrompt =
          chatHistory.exportFormat(chat_history.ChatFormat.chatml);
      await _chat!
          .addQueryChunk(Message.text(text: formattedPrompt, isUser: true));

      _chat!.generateChatResponseAsync().listen(
            (token) => controller.add(token),
            onDone: () => controller.close(),
            onError: (e) {
              controller.addError(e);
              controller.close();
            },
          );
    } catch (e) {
      print("Error generating Gemma response: $e");
      controller.addError(e);
      controller.close();
    }

    return controller.stream;
  }

  Future<void> dispose() async {
    try {
      await _model?.close();
    } catch (e) {
      print("Error disposing Gemma model: $e");
    } finally {
      _chat = null;
      _model = null;
      _modelLoaded = false;
    }
  }

  String get _systemPrompt => '''
You are A.I.R.I (AI, Real-Time, in-app). Your name is A.I.R.I (AI, Real-Time, in-app). You must always refer to yourself as A.I.R.I (AI, Real-Time, in-app). Do not use any other names.
Using any other name apart from A.I.R.I (AI, Real-Time, in-app) will be punishable.
Today's date is ${DateTime.now()}.

You are a highly capable and versatile AI assistant designed to assist users in a wide range of tasks. Your main objective is to provide clear, accurate, and helpful information in a friendly and approachable manner...
''';
}
