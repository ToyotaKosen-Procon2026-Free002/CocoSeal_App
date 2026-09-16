import 'package:flutter/material.dart';
import '../../api_service.dart';
import 'child_register_screen.dart';
import '../child/child_home_screen.dart';

class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({super.key});

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  late Future<List<Map<String, dynamic>>?> _devicesFuture;

  @override
  void initState() {
    super.initState();
    _refreshDevices();
  }

  void _refreshDevices() {
    setState(() {
      _devicesFuture = ApiService.fetchUserDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey),
          label: const Text('戻る', style: TextStyle(color: Colors.grey, fontSize: 14)),
        ),
        leadingWidth: 90,
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>?>(
          future: _devicesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return const Center(child: Text('デバイス一覧の取得に失敗しました'));
            }

            final devices = snapshot.data!;
            final existingIds = devices
                .map((d) => (d['id'] ?? d['device_id'] ?? '') as String)
                .toList();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView.separated(
                      itemCount: devices.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        final String device_id = device['id'];
                        final String name = device['name'];

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChildHomeScreen(childId: device_id),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey, width: 1.0),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text('⚽', style: TextStyle(fontSize: 28)),
                                const SizedBox(width: 16),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChildRegisterScreen(existingDevices: existingIds),
                        ),
                      );
                      if (result == true) {
                        _refreshDevices();
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 24, color: Colors.black54),
                          SizedBox(width: 8),
                          Text(
                            '新しい子機を登録する',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}