import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

// Define the native functions
typedef LogToAndroidFunc = Void Function();
typedef LogToAndroid = void Function();

typedef LoadModelFunc = Pointer<Void> Function(Pointer<Utf8> filename);
typedef LoadModel = Pointer<Void> Function(Pointer<Utf8> filename);

typedef FreeModelFunc = Void Function(Pointer<Void> model);
typedef FreeModel = void Function(Pointer<Void> model);

typedef NewContextFunc = Pointer<Void> Function(Pointer<Void> model);
typedef NewContext = Pointer<Void> Function(Pointer<Void> model);

typedef FreeContextFunc = Void Function(Pointer<Void> context);
typedef FreeContext = void Function(Pointer<Void> context);

typedef BackendInitFunc = Void Function(Bool numa);
typedef BackendInit = void Function(bool numa);

typedef BackendFreeFunc = Void Function();
typedef BackendFree = void Function();

typedef NewBatchFunc = Pointer<Void> Function(Int32 nTokens, Int32 embd, Int32 nSeqMax);
typedef NewBatch = Pointer<Void> Function(int nTokens, int embd, int nSeqMax);

typedef FreeBatchFunc = Void Function(Pointer<Void> batch);
typedef FreeBatch = void Function(Pointer<Void> batch);

typedef NewSamplerFunc = Pointer<Void> Function();
typedef NewSampler = Pointer<Void> Function();

typedef FreeSamplerFunc = Void Function(Pointer<Void> sampler);
typedef FreeSampler = void Function(Pointer<Void> sampler);

typedef BenchModelFunc = Pointer<Utf8> Function(
    Pointer<Void> context,
    Pointer<Void> model,
    Pointer<Void> batch,
    Int32 pp,
    Int32 tg,
    Int32 pl,
    Int32 nr
);
typedef BenchModel = Pointer<Utf8> Function(
    Pointer<Void> context,
    Pointer<Void> model,
    Pointer<Void> batch,
    int pp,
    int tg,
    int pl,
    int nr
);

typedef SystemInfoFunc = Pointer<Utf8> Function();
typedef SystemInfo = Pointer<Utf8> Function();

typedef CompletionInitFunc = Int32 Function(
    Pointer<Void> context,
    Pointer<Void> batch,
    Pointer<Utf8> text,
    Int32 nLen
);
typedef CompletionInit = int Function(
    Pointer<Void> context,
    Pointer<Void> batch,
    Pointer<Utf8> text,
    int nLen
);

typedef CompletionLoopFunc = Pointer<Utf8> Function(
    Pointer<Void> context,
    Pointer<Void> batch,
    Pointer<Void> sampler,
    Int32 nLen,
    Pointer<Void> ncur
);
typedef CompletionLoop = Pointer<Utf8> Function(
    Pointer<Void> context,
    Pointer<Void> batch,
    Pointer<Void> sampler,
    int nLen,
    Pointer<Void> ncur
);

typedef KvCacheClearFunc = Void Function(Pointer<Void> context);
typedef KvCacheClear = void Function(Pointer<Void> context);

// Load the shared library
final DynamicLibrary nativeAddLib = Platform.isAndroid
    ? DynamicLibrary.open("libllama_android.so")
    : DynamicLibrary.process();

// Lookup the functions
final LogToAndroid logToAndroid = nativeAddLib
    .lookup<NativeFunction<LogToAndroidFunc>>("log_to_android")
    .asFunction<LogToAndroid>();

final LoadModel loadModel = nativeAddLib
    .lookup<NativeFunction<LoadModelFunc>>("load_model")
    .asFunction<LoadModel>();

final FreeModel freeModel = nativeAddLib
    .lookup<NativeFunction<FreeModelFunc>>("free_model")
    .asFunction<FreeModel>();

final NewContext newContext = nativeAddLib
    .lookup<NativeFunction<NewContextFunc>>("new_context")
    .asFunction<NewContext>();

final FreeContext freeContext = nativeAddLib
    .lookup<NativeFunction<FreeContextFunc>>("free_context")
    .asFunction<FreeContext>();

final BackendInit backendInit = nativeAddLib
    .lookup<NativeFunction<BackendInitFunc>>("backend_init")
    .asFunction<BackendInit>();

final BackendFree backendFree = nativeAddLib
    .lookup<NativeFunction<BackendFreeFunc>>("backend_free")
    .asFunction<BackendFree>();

final NewBatch newBatch = nativeAddLib
    .lookup<NativeFunction<NewBatchFunc>>("new_batch")
    .asFunction<NewBatch>();

final FreeBatch freeBatch = nativeAddLib
    .lookup<NativeFunction<FreeBatchFunc>>("free_batch")
    .asFunction<FreeBatch>();

final NewSampler newSampler = nativeAddLib
    .lookup<NativeFunction<NewSamplerFunc>>("new_sampler")
    .asFunction<NewSampler>();

final FreeSampler freeSampler = nativeAddLib
    .lookup<NativeFunction<FreeSamplerFunc>>("free_sampler")
    .asFunction<FreeSampler>();

final BenchModel benchModel = nativeAddLib
    .lookup<NativeFunction<BenchModelFunc>>("bench_model")
    .asFunction<BenchModel>();

final SystemInfo systemInfo = nativeAddLib
    .lookup<NativeFunction<SystemInfoFunc>>("system_info")
    .asFunction<SystemInfo>();

final CompletionInit completionInit = nativeAddLib
    .lookup<NativeFunction<CompletionInitFunc>>("completion_init")
    .asFunction<CompletionInit>();

final CompletionLoop completionLoop = nativeAddLib
    .lookup<NativeFunction<CompletionLoopFunc>>("completion_loop")
    .asFunction<CompletionLoop>();

final KvCacheClear kvCacheClear = nativeAddLib
    .lookup<NativeFunction<KvCacheClearFunc>>("kv_cache_clear")
    .asFunction<KvCacheClear>();

class IntVar {
  int value;

  IntVar(this.value);

  void inc() {
    value += 1;
  }
}

sealed class State {}

class Idle extends State {}

class Loaded extends State {
  final Pointer<Void> model;
  final Pointer<Void> context;
  final Pointer<Void> batch;
  final Pointer<Void> sampler;

  Loaded(this.model, this.context, this.batch, this.sampler);
}

class LLamaAndroid {
  static final LLamaAndroid _instance = LLamaAndroid._internal();
  final String tag = 'LLamaAndroid';
  final int nlen = 64;
  State _state = Idle();

  factory LLamaAndroid() {
    return _instance;
  }

  LLamaAndroid._internal() {
    // Initialize the native library and set up the run loop
    logToAndroid();
    backendInit(false);
    print(systemInfo().toDartString());
  }

  Future<String> bench(int pp, int tg, int pl, {int nr = 1}) async {
    if (_state is Loaded) {
      final state = _state as Loaded;
      final result = benchModel(state.context, state.model, state.batch, pp, tg, pl, nr);
      return result.toDartString();
    } else {
      throw Exception('No model loaded');
    }
  }

  Future<void> load(String pathToModel) async {
    if (_state is Idle) {
      final model = loadModel(pathToModel.toNativeUtf8());
      if (model.address == 0) throw Exception('load_model() failed');

      final context = newContext(model);
      if (context.address == 0) throw Exception('new_context() failed');

      final batch = newBatch(512, 0, 1);
      if (batch.address == 0) throw Exception('new_batch() failed');

      final sampler = newSampler();
      if (sampler.address == 0) throw Exception('new_sampler() failed');

      _state = Loaded(model, context, batch, sampler);
    } else {
      throw Exception('Model already loaded');
    }
  }

  Stream<String> send(String message) async* {
    if (_state is Loaded) {
      final state = _state as Loaded;
      final ncur = IntVar(completionInit(state.context, state.batch, message.toNativeUtf8(), nlen));
      while (ncur.value <= nlen) {
        final str = completionLoop(state.context, state.batch, state.sampler, nlen, ncur);
        if (str.address == 0) {
          break;
        }
        yield str.toDartString();
      }
      kvCacheClear(state.context);
    }
  }

  Future<void> unload() async {
    if (_state is Loaded) {
      final state = _state as Loaded;
      freeContext(state.context);
      freeModel(state.model);
      freeBatch(state.batch);
      freeSampler(state.sampler);
      _state = Idle();
    }
  }
}
