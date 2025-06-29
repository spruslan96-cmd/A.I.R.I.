// ai_helpers.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:local_ai_chat/utils/gemma_helpers.dart';
import 'package:local_ai_chat/utils/llama_helpers.dart';
import 'package:local_ai_chat/models/chat_history.dart';
import 'package:path_provider/path_provider.dart';

class AiHelpers {
  static bool isReasoningModel = false;

  static Future<void> loadAvailableModels(
      Function(List<String>) onModelsLoaded, Function(String) onError) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      final models = files
          .where((file) => file is File && file.path.endsWith('.gguf'))
          .map((file) => file.path)
          .toList();
      onModelsLoaded(models);
    } catch (e) {
      print("Error loading models: $e");
      onError("Error loading models: $e");
    }
  }

  static Future<void> loadModel({
    required String modelFileName,
    required bool modelLoaded,
    required Function(bool, String) onModelLoading,
    required Function(String) onError,
    required int nCtx,
    required int nBatch,
    required int nPredict,
  }) async {
    if (modelLoaded) return;

    onModelLoading(true, "Loading Model...");
    try {
      isReasoningModel = isGemmaModel(modelFileName);
      if (isReasoningModel) {
        print('This is a Gemma model');
        final gemmaHelper = GemmaHelper();
        await gemmaHelper.loadModel(modelFileName);
        onModelLoading(false, "");
      } else {
        print('This is a LLaMA model');
        final llamaHelper = LlamaHelper();
        await llamaHelper.loadModel(modelFileName);
        onModelLoading(false, "");
      }
    } catch (e) {
      print("Error loading model: $e");
      onModelLoading(false, "");
      onError("Error loading model: $e");
    }
  }

  static Future<void> generateText(
    String prompt,
    ChatHistory chatHistory,
    Function(String) onResponseGenerated,
    Function(String) onError, {
    Function()? onComplete,
  }) async {
    String result = '';
    try {
      if (isReasoningModel) {
        print('This is a gemma model');
        final gemmaHelper = GemmaHelper();
        final response = await gemmaHelper.generateText(prompt);
        response.listen(
          (chunk) {
            result += chunk;
            onResponseGenerated(result);
          },
          onError: (error) {
            print('Error Generating text: $error');
            onError('Error Generating text: $error');
          },
          onDone: () {
            print('Text Generation Done');
            chatHistory.addMessage(role: Role.assistant, content: result);
            if (onComplete != null) onComplete;
          },
        );
      } else {
        print('This is a llama model');
        final llamaHelper = LlamaHelper();
        final generatedTextStream = await llamaHelper.generateText(prompt);
        generatedTextStream.listen(
          (chunk) {
            result += chunk;
            onResponseGenerated(result);
          },
          onError: (error) {
            print("Error generating text: $error");
            onError("Error generating text: $error");
          },
          onDone: () {
            chatHistory.addMessage(role: Role.assistant, content: result);
            if (onComplete != null) onComplete(); // ✅ Trigger complete callback
          },
        );
      }
    } catch (e) {
      print("Error generating text: $e");
      onError("Error generating text: $e");
    }
  }

  // New method for generating voice
  static Future<void> generateVoice(
    String prompt,
    LlamaHelper llamaHelper,
    ChatHistory chatHistory,
    Function(String) onResponseGenerated,
    Function(String) onError, {
    Function()? onComplete,
  }) async {
    try {
      final generatedTextStream = await llamaHelper.generateText(prompt);
      String fullResponse = '';

      generatedTextStream.listen(
        (chunk) {
          fullResponse += chunk;
          onResponseGenerated(chunk); // ✅ Send only the chunk
        },
        onError: (error) {
          print("Error generating text: $error");
          onError("Error generating text: $error");
        },
        onDone: () {
          print('Triggering onDone');
          chatHistory.addMessage(role: Role.assistant, content: fullResponse);
          if (onComplete != null) onComplete(); // ✅ Trigger complete callback
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("Error generating text: $e");
      onError("Error generating text: $e");
    }
  }

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  static bool isGemmaModel(String modelName) {
    final gemmaModels = ['gemma', 'phi', 'deepseek', 'falcon', 'stablelm'];
    final lower = modelName.toLowerCase();
    return gemmaModels.any((id) => lower.contains(id));
  }
}
