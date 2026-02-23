/*
import 'package:flutter/material.dart';
import 'package:zephyron/dashboard/settings.dart';
import 'package:zephyron/enums.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:zephyron/main.dart' as main;
import 'package:archive/archive.dart';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:zephyron/backend/zstd.dart';
import 'package:minio/minio.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  Menu screen = Menu.chats;
  late PageController pages;
  late AnimationController controller;
  double progress = 0.0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    pages = PageController(initialPage: screen.index);
    controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && progress < 1.0) {
        setState(() {});
      }
    });
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      if ((main.env['MINIO_ENDPOINT'] ?? '').isEmpty) {
        throw Exception('MinIO endpoint not configured');
      }
      if ((main.env['MINIO_ROOT_USER'] ?? main.env['MINIO_ACCESS_KEY'] ?? '')
          .isEmpty) {
        throw Exception('MinIO user not configured');
      }
      if ((main.env['MINIO_ROOT_PASSWORD'] ??
          main.env['MINIO_SECRET_KEY'] ??
          '')
          .isEmpty) {
        throw Exception('MinIO password not configured');
      }
      await Directory(
        '${(await getApplicationDocumentsDirectory()).path}/internal',
      ).create(recursive: true);
      final client = Minio(
        endPoint: Uri.parse(main.env['MINIO_ENDPOINT']!).host,
        port: Uri.parse(main.env['MINIO_ENDPOINT']!).hasPort
            ? Uri.parse(main.env['MINIO_ENDPOINT']!).port
            : (Uri.parse(main.env['MINIO_ENDPOINT']!).scheme == 'https'
            ? 443
            : 9000),
        useSSL: Uri.parse(main.env['MINIO_ENDPOINT']!).scheme == 'https',
        accessKey: main.env['MINIO_ROOT_USER'] ??
            main.env['MINIO_ACCESS_KEY']!,
        secretKey: main.env['MINIO_ROOT_PASSWORD'] ??
            main.env['MINIO_SECRET_KEY']!,
      );
      final objects = <({String key, String name, int size, String? hash})>[];
      await for (final result in client.listObjectsV2(
        main.env['MINIO_BUCKET'] ?? 'internal',
      )) {
        for (final object in result.objects) {
          if (object.key != null && !object.key!.endsWith('/')) {
            objects.add((
            key: object.key!,
            name: object.key!.split('/').last,
            size: object.size ?? 0,
            hash: object.eTag,
            ));
          }
        }
      }
      if (objects.isEmpty) throw Exception('No files found in bucket');
      for (var i = 0; i < objects.length; i++) {
        await setUp(
          client,
          (await getApplicationDocumentsDirectory()).path,
          objects[i].key,
          objects[i].name,
          objects[i].size,
          objects[i].hash,
          i,
          objects.length,
          objects[i].name == 'zstd.tar.gz',
        );
      }
      if (!mounted) return;
      setState(() => progress = 1.0);
      controller.stop();
      controller.reset();
      controller.duration = const Duration(milliseconds: 800);
      await controller.forward();
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (error) {
      developer.log(
        'Initialization failed: $error',
        error: error,
        stackTrace: StackTrace.current,
        name: 'DashboardScreen.initState',
        level: 1000,
      );
      if (!mounted) return;
      setState(() => progress = 1.0);
      controller.stop();
      controller.reset();
      controller.duration = const Duration(milliseconds: 800);
      await controller.forward();
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    try {
      if (state == AppLifecycleState.resumed && mounted && progress < 1.0) {
        setState(() {});
      }
    } catch (error) {
      developer.log(
        'Lifecycle state change error: $error',
        error: error,
        stackTrace: StackTrace.current,
        name: 'DashboardScreen.didChangeAppLifecycleState',
        level: 1000,
      );
    }
  }

  Future<void> setUp(
      Minio client,
      String root,
      String path,
      String name,
      int size,
      String? hash,
      int index,
      int length,
      bool library,
      ) async {
    try {
      if (library) {
        if (!(await File('$root/internal/.zstd.tar.gz').exists() &&
            await Directory('$root/internal/zstd').exists())) {
          for (final file in [
            Directory('$root/internal/zstd'),
            File('$root/internal/.zstd.tar.gz'),
            File('$root/internal/$name'),
          ]) {
            if (await file.exists()) await file.delete(recursive: true);
          }
          await download(
            client,
            path,
            '$root/internal/$name',
            size,
            hash,
            index,
            length,
          );
          await decompress('$root/internal/$name', root);
          if (await File('$root/internal/$name').exists()) {
            await File('$root/internal/$name').delete();
          }
          await File('$root/internal/.zstd.tar.gz').create();
        } else if (Platform.isAndroid || Platform.isIOS) {
          if (await Directory(
            '$root/internal/zstd/${Platform.isAndroid ? 'android' : 'ios'}',
          ).exists()) {
            await for (final entity in Directory(
              '$root/internal/zstd/${Platform.isAndroid ? 'android' : 'ios'}',
            ).list(recursive: true)) {
              if (entity is File && entity.path.contains('libzstd')) {
                if (await File('$root/internal/$name').exists()) {
                  await File('$root/internal/$name').delete();
                }
                return;
              }
            }
            for (final file in [
              Directory('$root/internal/zstd'),
              File('$root/internal/.zstd.tar.gz'),
              File('$root/internal/$name'),
            ]) {
              if (await file.exists()) await file.delete(recursive: true);
            }
            await download(
              client,
              path,
              '$root/internal/$name',
              size,
              hash,
              index,
              length,
            );
            await decompress('$root/internal/$name', root);
            if (await File('$root/internal/$name').exists()) {
              await File('$root/internal/$name').delete();
            }
            await File('$root/internal/.zstd.tar.gz').create();
          }
        }
        return;
      }
      if (name.endsWith('.zst') &&
          await File('$root/internal/.$name').exists() &&
          await File('$root/internal/${name.replaceAll('.zst', '')}')
              .exists()) return;
      if (!name.endsWith('.zst') &&
          await File('$root/internal/.$name').exists() &&
          await File('$root/internal/$name').exists()) {
        if (await File('$root/internal/$name').length() == size) return;
        for (final file in [
          File('$root/internal/$name'),
          File('$root/internal/.$name'),
        ]) {
          await file.delete();
        }
      }
      if (await File('$root/internal/$name').exists()) {
        await File('$root/internal/$name').delete();
      }
      await File('$root/internal/$name').parent.create(recursive: true);
      await download(
        client,
        path,
        '$root/internal/$name',
        size,
        hash,
        index,
        length,
      );
      if (name.endsWith('.tar.gz') || name.endsWith('.tgz')) {
        await decompress('$root/internal/$name', root);
        if (await File('$root/internal/$name').exists()) {
          await File('$root/internal/$name').delete();
        }
      }
      if (name.endsWith('.zst')) {
        final decoder = Zstd.load('$root/internal');
        try {
          await decoder.decompress(
            '$root/internal/$name',
            '$root/internal/${name.replaceAll('.zst', '')}',
          );
        } finally {
          decoder.dispose();
        }
        if (await File('$root/internal/${name.replaceAll('.zst', '')}')
            .length() <
            (await File('$root/internal/$name').length() * 1.5).toInt()) {
          await File('$root/internal/${name.replaceAll('.zst', '')}').delete();
          throw Exception('Decompression verification failed for $name');
        }
        if (await File('$root/internal/$name').exists()) {
          await File('$root/internal/$name').delete();
        }
      }
      await File('$root/internal/.$name').create();
    } catch (error) {
      developer.log(
        'Process error for $name: $error',
        error: error,
        stackTrace: StackTrace.current,
        name: 'DashboardScreen.setUp',
        level: 1000,
      );
      rethrow;
    }
  }

  Future<void> download(
      Minio client,
      String key,
      String target,
      int bytes,
      String? hash,
      int index,
      int length,
      ) async {
    if (bytes <= 0) throw Exception('Invalid file size: $bytes');
    RandomAccessFile? writer;
    try {
      int read = 0;
      writer = await File(target).open(mode: FileMode.write);
      await for (final chunk in await client.getObject(
        main.env['MINIO_BUCKET'] ?? 'internal',
        key,
      )) {
        int retry = 0;
        while (retry <= 3) {
          try {
            await writer.writeFrom(chunk);
            read += chunk.length;
            break;
          } catch (error) {
            if (++retry > 3) rethrow;
            await Future.delayed(Duration(milliseconds: 100 * retry));
          }
        }
        progress = (index / length) + ((read / bytes) / length);
      }
      progress = ((index + 1) / length);
      await writer.flush();
      await writer.close();
      writer = null;
      if (!await File(target).exists()) {
        throw Exception('File disappeared after download');
      }
      if (await File(target).length() != bytes) {
        await File(target).delete();
        throw Exception(
          'Size mismatch: expected $bytes, got ${await File(target).length()}',
        );
      }
      if (hash != null &&
          hash.isNotEmpty &&
          !hash.replaceAll('"', '').toLowerCase().contains('-') &&
          hash.replaceAll('"', '').toLowerCase().length == 32) {
        final output = AccumulatorSink<Digest>();
        final sink = md5.startChunkedConversion(output);
        await for (final chunk in File(target).openRead()) {
          sink.add(chunk);
        }
        sink.close();
        if (output.events.isEmpty) {
          throw Exception('Hash computation produced no output');
        }
        if (output.events.first.toString() !=
            hash.replaceAll('"', '').toLowerCase()) {
          await File(target).delete();
          throw Exception('Hash verification failed');
        }
      }
    } catch (error) {
      developer.log(
        'Download error for $key: $error',
        error: error,
        stackTrace: StackTrace.current,
        name: 'DashboardScreen.download',
        level: 1000,
      );
      rethrow;
    } finally {
      await writer?.close();
    }
  }

  Future<void> decompress(String source, String root) async {
    if (mounted) setState(() => progress = 0.01);
    try {
      if (!await File(source).exists()) {
        throw Exception('Archive file not found: $source');
      }
      final bytes = <int>[];
      await for (final part in File(source).openRead()) {
        bytes.addAll(part);
      }
      if (bytes.isEmpty) throw Exception('Archive file is empty: $source');
      for (final file in TarDecoder().decodeBytes(
        GZipDecoder().decodeBytes(bytes),
      )) {
        if (file.isFile) {
          await File('$root/internal/${file.name}').create(recursive: true);
          await File('$root/internal/${file.name}')
              .writeAsBytes(file.content as List<int>);
        }
      }
    } catch (error) {
      developer.log(
        'Extract error: $error',
        error: error,
        stackTrace: StackTrace.current,
        name: 'DashboardScreen.decompress',
        level: 1000,
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      if (progress < 1.0) {
        return Scaffold(
          body: Stack(
            children: [
              Center(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    final value = progress >= 0.99
                        ? controller.value
                        : controller.value % 1.0;
                    if (progress >= 0.99) {
                      return Opacity(
                        opacity: value >= 0.5
                            ? 1.0 -
                            Curves.easeOut.transform(
                              ((value - 0.5) / 0.5).clamp(0.0, 1.0),
                            )
                            : 1.0,
                        child: Transform.scale(
                          scale: value >= 0.3 && value < 0.6
                              ? Curves.easeOut.transform(
                            ((value - 0.3) / 0.3).clamp(0.0, 1.0),
                          ) *
                              30
                              : value >= 0.6
                              ? 30.0
                              : 1.0,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }
                    return SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: List.generate(4, (position) {
                          return Transform.translate(
                            offset: Offset(
                              (position == 0 || position == 3 ? -20.0 : 20.0) *
                                  (value < 0.15
                                      ? Curves.easeOut.transform(
                                    (value / 0.15).clamp(0.0, 1.0),
                                  )
                                      : value >= 0.55
                                      ? 1.0 -
                                      Curves.easeIn.transform(
                                        ((value - 0.55) / 0.15)
                                            .clamp(
                                          0.0,
                                          1.0,
                                        ),
                                      )
                                      : 1.0) +
                                  ((position + 1) % 4 == 0 ||
                                      (position + 1) % 4 == 3
                                      ? -20.0
                                      : 20.0) *
                                      (value < 0.15
                                          ? Curves.easeOut.transform(
                                        (value / 0.15).clamp(0.0, 1.0),
                                      )
                                          : value >= 0.55
                                          ? 1.0 -
                                          Curves.easeIn.transform(
                                            ((value - 0.55) / 0.15)
                                                .clamp(
                                              0.0,
                                              1.0,
                                            ),
                                          )
                                          : 1.0) *
                                      (value >= 0.15 && value < 0.5
                                          ? Curves.easeInOut.transform(
                                        ((value - 0.15) / 0.35).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                      )
                                          : 0.0) -
                                  (position == 0 || position == 3
                                      ? -20.0
                                      : 20.0) *
                                      (value < 0.15
                                          ? Curves.easeOut.transform(
                                        (value / 0.15).clamp(0.0, 1.0),
                                      )
                                          : value >= 0.55
                                          ? 1.0 -
                                          Curves.easeIn.transform(
                                            ((value - 0.55) / 0.15)
                                                .clamp(
                                              0.0,
                                              1.0,
                                            ),
                                          )
                                          : 1.0) *
                                      (value >= 0.15 && value < 0.5
                                          ? Curves.easeInOut.transform(
                                        ((value - 0.15) / 0.35).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                      )
                                          : 0.0),
                              (position == 0 || position == 1 ? -20.0 : 20.0) *
                                  (value < 0.15
                                      ? Curves.easeOut.transform(
                                    (value / 0.15).clamp(0.0, 1.0),
                                  )
                                      : value >= 0.55
                                      ? 1.0 -
                                      Curves.easeIn.transform(
                                        ((value - 0.55) / 0.15)
                                            .clamp(
                                          0.0,
                                          1.0,
                                        ),
                                      )
                                      : 1.0) +
                                  ((position + 1) % 4 == 0 ||
                                      (position + 1) % 4 == 1
                                      ? -20.0
                                      : 20.0) *
                                      (value < 0.15
                                          ? Curves.easeOut.transform(
                                        (value / 0.15).clamp(0.0, 1.0),
                                      )
                                          : value >= 0.55
                                          ? 1.0 -
                                          Curves.easeIn.transform(
                                            ((value - 0.55) / 0.15)
                                                .clamp(
                                              0.0,
                                              1.0,
                                            ),
                                          )
                                          : 1.0) *
                                      (value >= 0.15 && value < 0.5
                                          ? Curves.easeInOut.transform(
                                        ((value - 0.15) / 0.35).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                      )
                                          : 0.0) -
                                  (position == 0 || position == 1
                                      ? -20.0
                                      : 20.0) *
                                      (value < 0.15
                                          ? Curves.easeOut.transform(
                                        (value / 0.15).clamp(0.0, 1.0),
                                      )
                                          : value >= 0.55
                                          ? 1.0 - Curves.easeIn.transform(
                                        ((value - 0.55) / 0.15).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                      )
                                          : 1.0) *
                                      (value >= 0.15 && value < 0.5
                                          ? Curves.easeInOut.transform(
                                        ((value - 0.15) / 0.35).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                      )
                                          : 0.0),
                            ),
                            child: Container(
                              width: 16.0 +
                                  16.0 *
                                      (1.0 -
                                          (value < 0.15
                                              ? Curves.easeOut.transform(
                                            (value / 0.15).clamp(
                                              0.0,
                                              1.0,
                                            ),
                                          )
                                              : value >= 0.55
                                              ? 1.0 -
                                              Curves.easeIn.transform(
                                                ((value - 0.55) / 0.15)
                                                    .clamp(0.0, 1.0),
                                              )
                                              : 1.0)) +
                                  8.0 *
                                      (1.0 -
                                          (value < 0.15
                                              ? Curves.easeOut.transform(
                                            (value / 0.15).clamp(
                                              0.0,
                                              1.0,
                                            ),
                                          )
                                              : value >= 0.55
                                              ? 1.0 -
                                              Curves.easeIn.transform(
                                                ((value - 0.55) / 0.15)
                                                    .clamp(0.0, 1.0),
                                              )
                                              : 1.0)) *
                                      (value >= 0.55 && value < 0.65
                                          ? Curves.elasticOut.transform(
                                        ((value - 0.55) / 0.1).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                      )
                                          : value >= 0.65
                                          ? 1.0
                                          : 0.0),
                              height: 16.0 +
                                  16.0 *
                                      (1.0 -
                                          (value < 0.15
                                              ? Curves.easeOut.transform(
                                            (value / 0.15).clamp(
                                              0.0,
                                              1.0,
                                            ),
                                          )
                                              : value >= 0.55
                                              ? 1.0 -
                                              Curves.easeIn.transform(
                                                ((value - 0.55) / 0.15)
                                                    .clamp(0.0, 1.0),
                                              )
                                              : 1.0)) +
                                  8.0 *
                                      (1.0 -
                                          (value < 0.15
                                              ? Curves.easeOut.transform(
                                            (value / 0.15).clamp(
                                              0.0,
                                              1.0,
                                            ),
                                          )
                                              : value >= 0.55
                                              ? 1.0 -
                                              Curves.easeIn.transform(
                                                ((value - 0.55) / 0.15)
                                                    .clamp(0.0, 1.0),
                                              )
                                              : 1.0)) *
                                      (value >= 0.55 && value < 0.65
                                          ? Curves.elasticOut.transform(
                                        ((value - 0.55) / 0.1).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                      )
                                          : value >= 0.65
                                          ? 1.0
                                          : 0.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: progress >= 0.99 && controller.value >= 0.5
                          ? 1.0 -
                          Curves.easeOut.transform(
                            ((controller.value - 0.5) / 0.5).clamp(
                              0.0,
                              1.0,
                            ),
                          )
                          : 1.0,
                      child: LinearProgressIndicator(value: progress),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: PageView(
          controller: pages,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            if (index < 0 || index >= Menu.values.length) {
              developer.log(
                'Invalid page index: $index',
                name: 'DashboardScreen.onPageChanged',
                level: 900,
              );
              return;
            }
            if (mounted) {
              setState(() => screen = Menu.values[index]);
            }
          },
          children: [
            Builder(
              key: const ValueKey('contacts'),
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Network')),
                body: const Center(child: Text('Network Page')),
              ),
            ),
            Builder(
              key: const ValueKey('chats'),
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Discover')),
                body: const Center(child: Text('Discover Page')),
              ),
            ),
            Builder(
              key: const ValueKey('settings'),
              builder: (context) => const SettingsPage()
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: screen.index,
          onDestinationSelected: (selected) {
            pages.animateToPage(
              selected,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(PhosphorIconsRegular.users),
              selectedIcon: Icon(PhosphorIconsFill.users),
              label: 'Contacts',
            ),
            NavigationDestination(
              icon: Icon(PhosphorIconsRegular.chatCircle),
              selectedIcon: Icon(PhosphorIconsFill.chatCircle),
              label: 'Chats',
            ),
            NavigationDestination(
              icon: Icon(PhosphorIconsRegular.gear),
              selectedIcon: Icon(PhosphorIconsFill.gear),
              label: 'Settings',
            ),
          ],
        ),
      );
    } catch (error) {
      developer.log(
        'Build error: $error',
        error: error,
        stackTrace: StackTrace.current,
        name: 'DashboardScreen.build',
        level: 1000,
      );
      return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
      timer?.cancel();
      controller.dispose();
      pages.dispose();
      super.dispose();
    } catch (error) {
      developer.log(
        'Dispose error: $error',
        error: error,
        stackTrace: StackTrace.current,
        name: 'DashboardScreen.dispose',
        level: 1000,
      );
    }
  }
}

class AccumulatorSink<T> implements Sink<T> {
  final List<T> events = [];

  @override
  void add(T event) => events.add(event);

  @override
  void close() {}
}
*/
