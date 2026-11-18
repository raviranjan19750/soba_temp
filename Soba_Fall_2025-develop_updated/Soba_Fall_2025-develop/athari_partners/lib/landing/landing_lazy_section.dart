import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Defers building heavy landing sections until they are near the viewport.
class LandingLazySection extends StatefulWidget {
  const LandingLazySection({
    super.key,
    required this.scrollController,
    required this.builder,
    this.placeholderHeight = 480,
    this.loadMargin = 600,
  });

  final ScrollController scrollController;
  final Widget Function(BuildContext context) builder;
  final double placeholderHeight;
  final double loadMargin;

  @override
  State<LandingLazySection> createState() => _LandingLazySectionState();
}

class _LandingLazySectionState extends State<LandingLazySection> {
  final GlobalKey _anchorKey = GlobalKey();
  bool _shouldBuild = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_evaluateVisibility);
    SchedulerBinding.instance.addPostFrameCallback((_) => _evaluateVisibility());
  }

  @override
  void didUpdateWidget(LandingLazySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_evaluateVisibility);
      widget.scrollController.addListener(_evaluateVisibility);
    }
    _evaluateVisibility();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_evaluateVisibility);
    super.dispose();
  }

  void _evaluateVisibility() {
    if (_shouldBuild || !mounted) return;

    final anchorContext = _anchorKey.currentContext;
    if (anchorContext == null) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _evaluateVisibility());
      return;
    }

    final box = anchorContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final top = box.localToGlobal(Offset.zero).dy;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final visible = top < viewportHeight + widget.loadMargin;

    if (visible) {
      setState(() => _shouldBuild = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldBuild) {
      return widget.builder(context);
    }

    return SizedBox(
      key: _anchorKey,
      height: widget.placeholderHeight,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
