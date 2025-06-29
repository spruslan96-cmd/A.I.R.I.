import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_ai_chat/utils/ai_helpers.dart';
import 'package:local_ai_chat/utils/llama_helpers.dart';

class ModelInitBottomSheet extends StatefulWidget {
  final LlamaHelper llamaHelper;
  final void Function(String modelName) onModelInitialized;

  const ModelInitBottomSheet({
    super.key,
    required this.llamaHelper,
    required this.onModelInitialized,
  });

  @override
  State<ModelInitBottomSheet> createState() => _ModelInitBottomSheetState();
}

class _ModelInitBottomSheetState extends State<ModelInitBottomSheet> {
  List<String> _availableModels = [];
  String? _selectedModel;
  bool _isLoading = true;
  bool _isInitializing = false;

  final TextEditingController _nCtxController =
      TextEditingController(text: "2048");
  final TextEditingController _nBatchController =
      TextEditingController(text: "512");
  final TextEditingController _nPredictController =
      TextEditingController(text: "128");

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  void _loadModels() {
    AiHelpers.loadAvailableModels(
      (models) {
        setState(() {
          _availableModels = models;
          _isLoading = false;
        });
      },
      (error) {
        AiHelpers.showSnackBar(context, error);
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _initializeModel() async {
    if (_selectedModel == null) return;

    setState(() => _isInitializing = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('nCtx', int.tryParse(_nCtxController.text) ?? 2048);
    await prefs.setInt('nBatch', int.tryParse(_nBatchController.text) ?? 512);
    await prefs.setInt(
        'nPredict', int.tryParse(_nPredictController.text) ?? 128);
    final nCtx = prefs.getInt('nCtx') ?? 2048;
    final nBactch = prefs.getInt('nBatch') ?? 512;
    final nPredit = prefs.getInt('NPredict') ?? 128;
    await AiHelpers.loadModel(
      nCtx: nCtx,
      nBatch: nBactch,
      nPredict: nPredit,
      modelFileName:  _selectedModel!,
      modelLoaded: false,
      onModelLoading: (loading, message) {
        if (loading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      },
      onError: (error) => AiHelpers.showSnackBar(context, error),
    );

    widget.onModelInitialized(_selectedModel!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 420,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Initialize Model",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedModel,
                    decoration:
                        const InputDecoration(labelText: "Select Model"),
                    items: _availableModels.map((modelPath) {
                      return DropdownMenuItem<String>(
                        value: modelPath,
                        child: Text(modelPath.split('/').last,
                            overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedModel = val),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nCtxController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "n_ctx"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _nBatchController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: "n_batch"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nPredictController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "n_predict"),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isInitializing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isInitializing
                          ? "Initializing..."
                          : "Initialize Model"),
                      onPressed: _isInitializing ? null : _initializeModel,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
