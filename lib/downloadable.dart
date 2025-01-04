import 'dart:io';
import 'package:android_download_manager/android_download_manager.dart';
import 'package:flutter/material.dart';
import 'package:your_package/main_view_model.dart';
import 'package:your_package/download_manager.dart';

class Downloadable {
  final String name;
  final Uri source;
  final File destination;

  Downloadable({
    required this.name,
    required this.source,
    required this.destination,
  });

  static const String? tag = 'Downloadable';

  sealed class State {}
  class Ready extends State {}
  class Downloading extends State {
    final int id;
    Downloading(this.id);
  }
  class Downloaded extends State {
    final Downloadable downloadable;
    Downloaded(this.downloadable);
  }
  class Error extends State {
    final String message;
    Error(this.message);
  }

  static Widget buildButton(MainViewModel viewModel, DownloadManager dm, Downloadable item) {
    return _DownloadButton(viewModel: viewModel, dm: dm, item: item);
  }
}

class _DownloadButton extends StatefulWidget {
  final MainViewModel viewModel;
  final DownloadManager dm;
  final Downloadable item;

  const _DownloadButton({
    required this.viewModel,
    required this.dm,
    required this.item,
  });

  @override
  _DownloadButtonState createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  late Downloadable.State status;
  double progress = 0.0;

  @override
  void initState() {
    super.initState();
    status = widget.item.destination.existsSync() 
        ? Downloadable.Downloaded(widget.item)
        : Downloadable.Ready();
  }

  Future<Downloadable.State> waitForDownload(
      Downloadable.Downloading result, Downloadable item) async {
    while (true) {
      final cursor = await widget.dm.query(
          DownloadManager.Query()..setFilterById(result.id));

      if (cursor == null) {
        debugPrint('${Downloadable.tag}: dm.query() returned null');
        return Downloadable.Error('dm.query() returned null');
      }

      if (!cursor.moveToFirst() || cursor.count < 1) {
        cursor.close();
        debugPrint('${Downloadable.tag}: cursor.moveToFirst() returned false or cursor.count < 1, download canceled?');
        return Downloadable.Ready();
      }

      final pix = cursor.getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR);
      final tix = cursor.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES);
      final sofar = cursor.getLongOrNull(pix) ?? 0;
      final total = cursor.getLongOrNull(tix) ?? 1;
      cursor.close();

      if (sofar == total) {
        return Downloadable.Downloaded(item);
      }

      setState(() {
        progress = (sofar * 1.0) / total;
      });

      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void onClick() {
    if (status is Downloadable.Downloaded) {
      widget.viewModel.load(widget.item.destination.path);
    } else if (status is Downloadable.Downloading) {
      waitForDownload(status as Downloadable.Downloading, widget.item)
          .then((newStatus) {
        setState(() {
          status = newStatus;
        });
      });
    } else {
      widget.item.destination.deleteSync();

      final request = DownloadManager.Request(widget.item.source)
        ..setTitle('Downloading model')
        ..setDescription('Downloading model: ${widget.item.name}')
        ..setAllowedNetworkTypes(DownloadManager.Request.NETWORK_WIFI)
        ..setDestinationUri(Uri.file(widget.item.destination.path));

      widget.viewModel.log('Saving ${widget.item.name} to ${widget.item.destination.path}');
      debugPrint('${Downloadable.tag}: Saving ${widget.item.name} to ${widget.item.destination.path}');

      final id = widget.dm.enqueue(request);
      setState(() {
        status = Downloadable.Downloading(id);
      });
      onClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: status is Downloadable.Downloading ? null : onClick,
      child: Text(
        switch (status) {
          Downloadable.Downloading _ => 'Downloading ${(progress * 100).toInt()}%',
          Downloadable.Downloaded _ => 'Load ${widget.item.name}',
          Downloadable.Ready _ => 'Download ${widget.item.name}',
          Downloadable.Error _ => 'Download ${widget.item.name}',
        },
      ),
    );
  }
}
