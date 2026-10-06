import 'package:flutter/material.dart';

import '../../widgets/pin_code_dialog.dart';
import '../parent/parent_home_screen.dart';
import 'exchange_box_screen.dart';
import 'mission_screen.dart';
import 'passby_check_screen.dart';
import 'rare_spot_map_screen.dart';
import 'seal_book_screen.dart';
import 'seal_dictionary_screen.dart';
import 'seal_exchange_screen.dart';

class ChildHomeScreen extends StatefulWidget {
  final String childId;
  final String name;
  final int battery;
  final int coins;

  const ChildHomeScreen({
    super.key,
    required this.childId,
    this.name = 'ななし',
    this.battery = 0,
    this.coins = 0,
  });

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  static const Color _purple = Color(0xFF8C63C7);
  static const Color _darkPurple = Color(0xFF654391);
  static const Color _background = Color(0xFFF5F0FC);
  static const Color _softPurple = Color(0xFFE9DDF8);

  late int _coins;

  @override
  void initState() {
    super.initState();
    _coins = widget.coins;
  }

  Future<void> _switchToParentMenu() async {
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PinCodeDialog(correctPin: '1234'),
    );
    if (success == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ParentHomeScreen()),
      );
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Expanded(child: _buildMenuGrid()),
              const SizedBox(height: 14),
              _buildExchangeButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _softPurple, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A654391),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: _softPurple,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    color: _darkPurple,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _statusPill(
            icon: widget.battery > 20 ? Icons.battery_full_rounded : Icons.battery_alert_rounded,
            value: '${widget.battery}%',
            color: widget.battery > 20 ? const Color(0xFF5BAA78) : Colors.redAccent,
          ),
          const SizedBox(width: 8),
          _statusPill(
            icon: Icons.monetization_on_rounded,
            value: '$_coins枚',
            color: const Color(0xFFFFB53D),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _switchToParentMenu,
            style: TextButton.styleFrom(
              foregroundColor: _purple,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
            child: const Text(
              'メニューきりかえ',
              style: TextStyle(
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    final items = <_HomeMenuItem>[
      _HomeMenuItem(
        title: 'すれちがい\nかくにん',
        icon: Icons.people_alt_rounded,
        accent: const Color(0xFFFF8FA3),
        onTap: () => _open(PassbyCheckScreen(deviceId: widget.childId)),
      ),
      _HomeMenuItem(
        title: 'レアシール\nスポット',
        icon: Icons.location_on_rounded,
        accent: const Color(0xFFFFB15C),
        onTap: () => _open(const RareSpotScreen()),
      ),
      _HomeMenuItem(
        title: 'ウィークリー\nミッション',
        icon: Icons.flag_rounded,
        accent: const Color(0xFF72B88D),
        onTap: () => _open(
          MissionScreen(
            childId: widget.childId,
            onRewardClaimed: (reward) {
              if (mounted) setState(() => _coins += reward);
            },
          ),
        ),
      ),
      _HomeMenuItem(
        title: 'シールずかん',
        icon: Icons.auto_stories_rounded,
        accent: const Color(0xFF6FA8DC),
        onTap: () => _open(SealDictionaryScreen(deviceId: widget.childId)),
      ),
      _HomeMenuItem(
        title: 'シール帳づくり',
        icon: Icons.menu_book_rounded,
        accent: _purple,
        onTap: () => _open(SealBookScreen(deviceId: widget.childId)),
      ),
      _HomeMenuItem(
        title: 'シールパック\nこうかん',
        icon: Icons.redeem_rounded,
        accent: const Color(0xFFD779B9),
        onTap: () => _open(
          SealExchangeScreen(
            deviceId: widget.childId,
            initialCoins: _coins,
            onCoinsChanged: (value) => setState(() => _coins = value),
          ),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 3 : 2;
        const spacing = 14.0;
        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: constraints.maxHeight < 480 ? 132 : 158,
          ),
          itemBuilder: (context, index) => _menuCard(items[index]),
        );
      },
    );
  }

  Widget _menuCard(_HomeMenuItem item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: item.accent.withValues(alpha: 0.35), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12654391),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 145;
              final iconSize = compact ? 42.0 : 54.0;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: item.accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.icon,
                      color: item.accent,
                      size: compact ? 25 : 30,
                    ),
                  ),
                  SizedBox(height: compact ? 5 : 10),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF45384F),
                      fontSize: compact ? 13 : 15,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ],
              );
              },
            ),
          ),
      ),
    );
  }

  Widget _buildExchangeButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton.icon(
        onPressed: () => _open(ExchangeBoxScreen(deviceId: widget.childId)),
        style: FilledButton.styleFrom(
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          elevation: 4,
          shadowColor: _purple.withValues(alpha: 0.35),
        ),
        icon: const Icon(Icons.mail_rounded),
        label: const Text(
          'こうかんボックス',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _HomeMenuItem {
  final String title;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _HomeMenuItem({
    required this.title,
    required this.icon,
    required this.accent,
    required this.onTap,
  });
}
