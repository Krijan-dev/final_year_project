import "dart:typed_data";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";

/// Loads and caches Android app launcher icons by package name.
class AppIconWidget extends ConsumerStatefulWidget {
  const AppIconWidget({
    super.key,
    required this.packageName,
    this.size = 44,
    this.borderRadius = 12,
  });

  final String packageName;
  final double size;
  final double borderRadius;

  @override
  ConsumerState<AppIconWidget> createState() => _AppIconWidgetState();
}

class _AppIconWidgetState extends ConsumerState<AppIconWidget> {
  static final Map<String, Uint8List> _cache = {};

  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AppIconWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packageName != widget.packageName) {
      _load();
    }
  }

  Future<void> _load() async {
    final pkg = widget.packageName;
    if (pkg.isEmpty) {
      setState(() {
        _bytes = null;
        _loading = false;
      });
      return;
    }

    final cached = _cache[pkg];
    if (cached != null) {
      setState(() {
        _bytes = cached;
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    final service = ref.read(usageStatsServiceProvider);
    final bytes = await service.getAppIcon(pkg);
    if (bytes != null) _cache[pkg] = bytes;
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(widget.borderRadius);

    if (_bytes != null) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.memory(
          _bytes!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(theme, radius),
        ),
      );
    }

    if (_loading) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: radius,
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return _fallback(theme, radius);
  }

  Widget _fallback(ThemeData theme, BorderRadius radius) {
    final initial = widget.packageName.isNotEmpty
        ? widget.packageName[0].toUpperCase()
        : "?";
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
