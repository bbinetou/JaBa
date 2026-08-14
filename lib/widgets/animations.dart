import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Apparition en fondu + léger glissement vers le haut.
///
/// Appliquée avec un `delay` proportionnel à l'index, elle produit l'entrée
/// en cascade des cartes du feed : le contenu se pose à l'écran au lieu
/// d'apparaître d'un bloc.
class FadeInUp extends StatefulWidget {
  const FadeInUp({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.slow,
    this.offset = 24,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _animation =
      CurvedAnimation(parent: _controller, curve: AppMotion.emphasized);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _animation.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Bouton favori avec effet de « pop » : le cœur grossit brièvement quand on
/// l'active, ce qui donne un retour tactile là où une simple icône statique
/// laisserait douter que l'action a été prise en compte.
class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onToggle,
    this.size = 18,
    this.padding = 7,
    this.background,
  });

  final bool isFavorite;
  final VoidCallback onToggle;
  final double size;
  final double padding;
  final Color? background;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
    lowerBound: 0,
    upperBound: 0.35,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isFavorite) {
      _controller.forward().then((_) => _controller.reverse());
    }
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: 1 + _controller.value,
          child: child,
        ),
        child: Container(
          padding: EdgeInsets.all(widget.padding),
          decoration: BoxDecoration(
            color: widget.background ?? Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: AppMotion.fast,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              widget.isFavorite ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(widget.isFavorite),
              size: widget.size,
              color: AppColors.accent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compte à rebours qui se met à jour chaque seconde (validité du code OTP).
class CountdownText extends StatefulWidget {
  const CountdownText({super.key, required this.secondsLeft, required this.builder});

  final int Function() secondsLeft;
  final Widget Function(BuildContext context, int seconds) builder;

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;
  late int _seconds = widget.secondsLeft();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final value = widget.secondsLeft();
      if (!mounted) return;
      if (value != _seconds) setState(() => _seconds = value);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _seconds);
}

/// Rectangle animé façon « squelette », affiché pendant le rafraîchissement.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, this.height, this.width, this.radius = AppRadius.sm});

  final double? height;
  final double? width;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Color.lerp(
            AppColors.placeholder,
            AppColors.border,
            _controller.value,
          ),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
