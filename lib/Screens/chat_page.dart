import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_ai_chat/Widgets/model_init_bottomsheet.dart';
import 'package:local_ai_chat/Widgets/drawer.dart';
import 'package:local_ai_chat/Widgets/prompt_text_field.dart';
import 'package:local_ai_chat/models/chat_history.dart';
import 'package:local_ai_chat/utils/ai_helpers.dart';
import 'package:local_ai_chat/utils/llama_helpers.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final _llamaHelper = LlamaHelper();
  // String? _selectedModel;
  bool _isLoading = false;
  bool _modelLoaded = false;
  bool _isGenerating = false;
  String _loadingMessage = "";

  @override
  void dispose() {
    _llamaHelper.dispose();
    super.dispose();
  }

  Future<void> _generateText() async {
    if (!_modelLoaded || _isGenerating) return;

    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _messages.add({'sender': 'user', 'text': prompt});
      _messages.add({'sender': 'ai', 'text': '...'});
      _controller.clear();
    });

    await AiHelpers.generateText(
      prompt,
      ChatHistory(),
      (response) {
        setState(() {
          _messages.last['text'] = response;
        });
      },
      (error) => AiHelpers.showSnackBar(context, error),
    ).whenComplete(() => setState(() => _isGenerating = false));
  }

  void _openModelSettingsBottomSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ModelInitBottomSheet(
        llamaHelper: _llamaHelper,
        onModelInitialized: (modelName) {
          setState(() {
            // _selectedModel = modelName;
            _modelLoaded = true;
            _isLoading = false;
            _loadingMessage = "";
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      drawer: const Hamburger(),
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openModelSettingsBottomSheet,
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_loadingMessage),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: _messages.isEmpty && !_modelLoaded
                        ? const Center(
                            child: Text(
                              'No model is loaded. Click settings to initialize one.',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isUser = message['sender'] == 'user';
                              return Align(
                                alignment: isUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    message['text']!,
                                    style: TextStyle(
                                      color: isUser
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: PromptTextField(controller: _controller),
                        ),
                        _isGenerating
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: _modelLoaded ? _generateText : null,
                                color: _modelLoaded
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
