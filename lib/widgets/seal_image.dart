import 'dart:convert';

import 'package:flutter/material.dart';

import '../api_service.dart';
import '../models/seal.dart';

class SealImage extends StatelessWidget {
  final Seal seal;
  final double size;
  final BoxFit fit;

  const SealImage({
    super.key,
    required this.seal,
    this.size = 56,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final path = seal.imagePath.trim();
    if (path.isEmpty) return _fallback();

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    if (path.startsWith('data:image/') && path.contains(';base64,')) {
      try {
        final bytes = base64Decode(path.split(';base64,').last);
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (_, __, ___) => _fallback(),
        );
      } catch (_) {
        return _fallback();
      }
    }

    final parsed = Uri.tryParse(path);
    if (parsed == null) return _fallback();
    final normalizedPath = path.replaceFirst(RegExp(r'^/+'), '');
    final url = parsed.hasScheme
        ? parsed.toString()
        : '${ApiService.baseUrl}/users/images/$normalizedPath';

    return Image.network(
      url,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() => Icon(
        Icons.stars_rounded,
        size: size,
        color: Colors.pinkAccent,
      );
}
