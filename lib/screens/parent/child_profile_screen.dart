import 'package:flutter/material.dart';

import '../../api_service.dart';
import '../../models/device.dart';
import '../child/child_home_screen.dart';
import 'child_register_screen.dart';

class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({super.key});

  @override
  State<ChildProfileScreen> createState() =>
      _ChildProfileScreenState();
}

class _ChildProfileScreenState
    extends State<ChildProfileScreen> {
  late Future<List<Device>> _devicesFuture;

  @override
  void initState() {
    super.initState();
    _refreshDevices();
  }

  /// 子機一覧をAPIから再取得する
  void _refreshDevices() {
    setState(() {
      _devicesFuture = ApiService.fetchUserDevices();
    });
  }

  /// 子機名を変更するダイアログを表示する
  Future<void> _showRenameDialog(
    Device device,
  ) async {
    final controller = TextEditingController(
      text: device.name == 'string'
          ? ''
          : device.name,
    );

    String? errorMessage;

    final newName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'こどもの名前を変更',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'デバイスID：${device.id}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction:
                        TextInputAction.done,
                    onSubmitted: (_) {
                      final name =
                          controller.text.trim();

                      if (name.isEmpty) {
                        setDialogState(() {
                          errorMessage =
                              '名前を入力してください';
                        });
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                        name,
                      );
                    },
                    decoration: InputDecoration(
                      labelText: '新しい表示名',
                      hintText: '例：たろう',
                      errorText: errorMessage,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name =
                        controller.text.trim();

                    if (name.isEmpty) {
                      setDialogState(() {
                        errorMessage =
                            '名前を入力してください';
                      });
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      name,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('変更する'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (newName == null || newName.isEmpty) {
      return;
    }

    if (newName == device.name) {
      return;
    }

    try {
      // PATCH /users/device で名前を更新する
      await ApiService.updateChildName(
        deviceId: device.id,
        name: newName,
      );

      if (!mounted) {
        return;
      }

      // 更新後の子機一覧を取得する
      _refreshDevices();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '名前を「$newName」に変更しました',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '名前の変更に失敗しました: $error',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 90,
        leading: TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 16,
            color: Colors.grey,
          ),
          label: const Text(
            '戻る',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Device>>(
          future: _devicesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'デバイス一覧の取得に失敗しました\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refreshDevices,
                      child: const Text('再試行'),
                    ),
                  ],
                ),
              );
            }

            final devices =
                snapshot.data ?? const <Device>[];

            final existingIds = devices
                .map((device) => device.id)
                .where((id) => id.isNotEmpty)
                .toList();

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: ListView.separated(
                      itemCount: devices.length,
                      separatorBuilder: (
                        context,
                        index,
                      ) {
                        return const SizedBox(
                          height: 12,
                        );
                      },
                      itemBuilder: (
                        context,
                        index,
                      ) {
                        final device =
                            devices[index];

                        return InkWell(
                          // 普通に押すと子ども画面へ移動
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChildHomeScreen(
                                  childId:
                                      device.id,
                                  name:
                                      device.name,
                                  battery: device
                                      .battery
                                      .round(),
                                  coins:
                                      device.coins,
                                ),
                              ),
                            );
                          },

                          // 長押しすると名前変更
                          onLongPress: () {
                            _showRenameDialog(
                              device,
                            );
                          },

                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            decoration:
                                const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color:
                                      Colors.black38,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 32,
                                ),

                                Expanded(
                                  child: Text(
                                    device.name,
                                    textAlign:
                                        TextAlign.center,
                                    style:
                                        const TextStyle(
                                      fontSize: 24,
                                      fontWeight:
                                          FontWeight.bold,
                                      letterSpacing: 2,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),

                                const Tooltip(
                                  message:
                                      '長押しで名前を変更',
                                  child: Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  InkWell(
                    onTap: () async {
                      final result =
                          await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChildRegisterScreen(
                            existingDevices:
                                existingIds,
                          ),
                        ),
                      );

                      if (result == true) {
                        _refreshDevices();
                      }
                    },
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            size: 20,
                            color: Colors.black87,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '新しい子機を登録する',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}