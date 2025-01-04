import 'package:flutter/foundation.dart';
import 'package:your_package/LlamaAndroid.dart';

class LLamaAndroid {
  static final LLamaAndroid _instance = LLamaAndroid._internal();
  
  factory LLamaAndroid.instance() => _instance;
  
  LLamaAndroid._internal();

  Future<void> unload() async {}
  Stream<String> send(String text) async* {}
  Future<String> bench(int pp, int tg, int pl, int nr) async => '';
  Future<void> load(String pathToModel) async {}
}

class MainViewModel extends ChangeNotifier {
  static const double _nanosPerSecond = 1000000000.0;
  
  final LLamaAndroid _llamaAndroid;
  final String? _tag = 'MainViewModel';

  List<String> _messages = ['Initializing...'];
  List<String> get messages => _messages;

  String _message = '';
  String get message => _message;

  MainViewModel({LLamaAndroid? llamaAndroid}) 
      : _llamaAndroid = llamaAndroid ?? LLamaAndroid.instance();

  @override
  void dispose() {
    try {
      _llamaAndroid.unload();
    } catch (exc) {
      if (exc is StateError) {
        _addMessage(exc.message!);
      }
    }
    super.dispose();
  }

  void send() {
    final text = _message;
    _message = '';

    // Add to messages console.
    _addMessage(text);
    _addMessage('');

    _llamaAndroid.send(text)
      .handleError((error) {
        debugPrint('$_tag: send() failed: $error');
        _addMessage(error.toString());
      })
      .listen((response) {
        _messages = [..._messages.sublist(0, _messages.length - 1), 
                    _messages.last() + response];
        notifyListeners();
      });
  }

  Future<void> bench(int pp, int tg, int pl, {int nr = 1}) async {
    try {
      final start = DateTime.now().microsecondsSinceEpoch * 1000;
      final warmupResult = await _llamaAndroid.bench(pp, tg, pl, nr);
      final end = DateTime.now().microsecondsSinceEpoch * 1000;

      _addMessage(warmupResult);

      final warmup = (end - start) / _nanosPerSecond;
      _addMessage('Warm up time: $warmup seconds, please wait...');

      if (warmup > 5.0) {
        _addMessage('Warm up took too long, aborting benchmark');
        return;
      }

      final result = await _llamaAndroid.bench(512, 128, 1, 3);
      _addMessage(result);
    } catch (exc) {
      debugPrint('$_tag: bench() failed: $exc');
      if (exc is StateError) {
        _addMessage(exc.message!);
      }
    }
  }

  Future<void> load(String pathToModel) async {
    try {
      await _llamaAndroid.load(pathToModel);
      _addMessage('Loaded $pathToModel');
    } catch (exc) {
      debugPrint('$_tag: load() failed: $exc');
      if (exc is StateError) {
        _addMessage(exc.message!);
      }
    }
  }

  void updateMessage(String newMessage) {
    _message = newMessage;
    notifyListeners();
  }

  void clear() {
    _messages = [];
    notifyListeners();
  }

  void log(String message) {
    _addMessage(message);
  }

  void _addMessage(String message) {
    _messages = [..._messages, message];
    notifyListeners();
  }
}
