import 'dart:async';
import 'dart:isolate';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:local_ai_chat/models/chat_format.dart';
import 'package:local_ai_chat/models/chat_history.dart';

class LlamaHelper {
  bool _modelLoaded = false;

  final chatHistory = ChatHistory();
  String? modelPath;
  SendPort? _isolateSendPort;
  Isolate? _isolate;

  Future<void> loadModel(String modelFileName) async {
    if (_modelLoaded) return;
    modelPath = modelFileName;
    print('MODEL PATH GOT AS: $modelPath');

    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_modelIsolate, receivePort.sendPort);
    _isolateSendPort = await receivePort.first as SendPort;

    final modelInitPort = ReceivePort();
    _isolateSendPort!
        .send({'modelPath': modelPath, 'sendPort': modelInitPort.sendPort});
    await modelInitPort.first; // Wait for model to be initialized

    _modelLoaded = true;
  }

  Future<Stream<String>> generateText(String prompt) async {
    if (!_modelLoaded || _isolateSendPort == null) {
      throw Exception('Model not loaded or isolate not initialized');
    }

    final responseStream = StreamController<String>();
    final receivePort = ReceivePort();

    _isolateSendPort!
        .send({'prompt': prompt, 'sendPort': receivePort.sendPort});

    receivePort.listen((message) {
      if (message is String) {
        responseStream.add(message);
      } else if (message == 'done') {
        responseStream.close();
      }
    });

    return responseStream.stream;
  }

  void _modelIsolate(SendPort sendPort) async {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    String? modelPath;
    Llama? llamaInstance;
    final systemPrompt = """
You are A.I.R.I (AI, Real-Time, in-app). Your name is A.I.R.I (AI, Real-Time, in-app). You must always refer to yourself as A.I.R.I (AI, Real-Time, in-app). Do not use any other names.
Using any other name apart from A.I.R.I (AI, Real-Time, in-app) will be punishable.
Today's date is ${DateTime.now()}.

You are a highly capable and versatile AI assistant designed to assist users in a wide range of tasks. Your main objective is to provide clear, accurate, and helpful information in a friendly and approachable manner. You should always aim to be polite, empathetic, and solution-oriented, offering explanations or assistance as needed.

Your primary strengths include:
1. Information retrieval and explanations: You can provide well-researched, concise, and easy-to-understand explanations across various topics, including technology, science, literature, mathematics, and more.
2. Task automation and troubleshooting: You can assist with performing tasks, solving problems, and offering step-by-step guidance to troubleshoot issues or provide instructions.
3. Conversational interaction: You can engage in casual conversation, maintaining a friendly tone while also adapting to the user’s communication style. Always be respectful and patient.
4. Personalized assistance: You can make recommendations or offer tailored advice based on user preferences or requirements when appropriate, while respecting privacy and ensuring security.

While responding, please adhere to the following guidelines:
- Be accurate and thorough: Ensure the information you provide is correct and up-to-date. If you're unsure about something, be transparent and offer suggestions for further exploration.
- Stay neutral and non-judgmental: Avoid biases and ensure that all responses are objective, respecting different viewpoints, cultures, and opinions.
- Be concise but informative: Try to provide clear, actionable answers without overwhelming the user with unnecessary details.
- Use a positive, friendly tone: Always aim to be approachable and kind, even when delivering complex or challenging information.

If you encounter a question or topic you are not able to answer, gently guide the user by suggesting alternative ways to gather the information or offering your best guess based on what you know. However, always prioritize honesty and clarity.

Your role is to empower users by making their tasks easier, providing valuable insights, and helping them solve problems effectively.
""";

    await for (final message in receivePort) {
      if (message is Map && message.containsKey('modelPath')) {
        modelPath = message['modelPath'];
        final clientSendPort = message['sendPort'] as SendPort;
        // final prefs = await SharedPreferences.getInstance();
        final _contextParams = ContextParams();
        _contextParams.nCtx = message['nCtx'] ?? 2048;
        _contextParams.nBatch = message['nBatch'] ?? 1024;
        _contextParams.nPredit = message['nPredict'] ?? 1024;
        final _samplerParams = SamplerParams();
        final _modelParams = ModelParams();

        try {
          Llama.libraryPath = "libllama.so";
          llamaInstance = Llama(
            modelPath!,
            _modelParams,
            _contextParams,
            _samplerParams,
          );

          //add system prompt to chat history.
          final chatHistory = ChatHistory();
          chatHistory.addMessage(role: Role.system, content: systemPrompt);

          print("Model loaded successfully in isolate.");
          clientSendPort.send('ready');
        } catch (e, stactrace) {
          print("Error loading model in isolate: $e");
          print('Stacktrace = $stactrace');
          clientSendPort.send('error: $e');
        }
      } else if (message is Map && message.containsKey('prompt')) {
        final prompt = message['prompt'] as String;
        final clientSendPort = message['sendPort'] as SendPort;

        if (llamaInstance == null) {
          clientSendPort.send('error: Model not initialized');
          clientSendPort.send('done');
          continue;
        }
        String response = '';
        try {
          print('User prompt = $prompt');
          chatHistory.addMessage(role: Role.user, content: prompt);
          final formattedPrompt = chatHistory.exportFormat(ChatFormat.chatml);
          llamaInstance.setPrompt(formattedPrompt);

          final responseBuffer = StringBuffer();

          final responseStream = llamaInstance.generateText();
          await responseStream.forEach((item) {
            item = ChatMLFormat().filterResponse(item) ?? '';
            response += item;

            clientSendPort.send(item);
            responseBuffer.write(item);
          }).whenComplete(() {
            print('Done Generating response');
            // clientSendPort.send(' done');
          });
          print('ai response = $response');
        } catch (e) {
          print("Error generating in isolate: $e");
          clientSendPort.send('error: $e');
        }
      } else if (message == 'dispose') {
        llamaInstance?.dispose();
        receivePort.close();
        break;
      }
    }
  }

  void dispose() {
    _isolateSendPort?.send('dispose');
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;

    _isolateSendPort = null;
    _modelLoaded = false;
  }
}
