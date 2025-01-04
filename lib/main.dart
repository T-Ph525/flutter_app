import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class MainActivity extends StatefulWidget {
  final ActivityManager? activityManager;
  final DownloadManager? downloadManager;
  final ClipboardManager? clipboardManager;

  MainActivity({
    this.activityManager,
    this.downloadManager,
    this.clipboardManager,
  });

  @override
  _MainActivityState createState() => _MainActivityState();
}

class _MainActivityState extends State<MainActivity> {
  final String? tag = 'MainActivity';
  late ActivityManager _activityManager;
  late DownloadManager _downloadManager;
  late ClipboardManager _clipboardManager;
  late MainViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _activityManager = widget.activityManager ?? ActivityManager();
    _downloadManager = widget.downloadManager ?? DownloadManager();
    _clipboardManager = widget.clipboardManager ?? ClipboardManager();
    _viewModel = MainViewModel();

    _initializeApp();
  }

  // Get memory information
  MemoryInfo availableMemory() {
    var memoryInfo = MemoryInfo();
    _activityManager.getMemoryInfo(memoryInfo);
    return memoryInfo;
  }

  void _initializeApp() {
    final free = formatFileSize(availableMemory().availMem);
    final total = formatFileSize(availableMemory().totalMem);

    _viewModel.log("Current memory: $free / $total");
    _viewModel.log("Downloads directory: ${getExternalFilesDir()}");

    final extFilesDir = getExternalFilesDir();

    final models = [
      Downloadable(
        "Phi-2 7B (Q4_0, 1.6 GiB)",
        Uri.parse("https://huggingface.co/ggml-org/models/resolve/main/phi-2/ggml-model-q4_0.gguf?download=true"),
        File('${extFilesDir.path}/phi-2-q4_0.gguf'),
      ),
      Downloadable(
        "TinyLlama 1.1B (f16, 2.2 GiB)",
        Uri.parse("https://huggingface.co/ggml-org/models/resolve/main/tinyllama-1.1b/ggml-model-f16.gguf?download=true"),
        File('${extFilesDir.path}/tinyllama-1.1-f16.gguf'),
      ),
      Downloadable(
        "Phi 2 DPO (Q3_K_M, 1.48 GiB)",
        Uri.parse("https://huggingface.co/TheBloke/phi-2-dpo-GGUF/resolve/main/phi-2-dpo.Q3_K_M.gguf?download=true"),
        File('${extFilesDir.path}/phi-2-dpo.Q3_K_M.gguf'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SafeArea(
          child: MainCompose(
            viewModel: _viewModel,
            clipboard: _clipboardManager,
            dm: _downloadManager,
            models: models,
          ),
        ),
      ),
    );
  }
}

class MainCompose extends StatelessWidget {
  final MainViewModel viewModel;
  final ClipboardManager clipboard;
  final DownloadManager dm;
  final List<Downloadable> models;

  const MainCompose({
    required this.viewModel,
    required this.clipboard,
    required this.dm,
    required this.models,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: viewModel.messages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  viewModel.messages[index],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            },
          ),
        ),
        TextField(
          controller: TextEditingController(text: viewModel.message),
          onChanged: viewModel.updateMessage,
          decoration: InputDecoration(
            labelText: 'Message',
            border: OutlineInputBorder(),
          ),
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: viewModel.send,
              child: Text('Send'),
            ),
            ElevatedButton(
              onPressed: () => viewModel.bench(8, 4, 1),
              child: Text('Bench'),
            ),
            ElevatedButton(
              onPressed: viewModel.clear,
              child: Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(
                  text: viewModel.messages.join('\n'),
                ));
              },
              child: Text('Copy'),
            ),
          ],
        ),
        Column(
          children: models.map((model) => 
            DownloadableButton(
              viewModel: viewModel,
              dm: dm,
              downloadable: model,
            ),
          ).toList(),
        ),
      ],
    );
  }
}
