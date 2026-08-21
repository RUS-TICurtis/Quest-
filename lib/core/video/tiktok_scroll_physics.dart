import 'package:flutter/material.dart';

/// Custom [PageScrollPhysics] that replicates TikTok's scroll feel.
///
/// Spring tuning:
///   mass = 1     → light, responsive (high mass = swipe carries through pages)
///   stiffness = 100 → snappy return to nearest page
///   damping = 1   → critically damped, no overshoot or oscillation
///
/// DO NOT increase mass above ~2 or the momentum from a normal swipe
/// will carry through multiple pages (the original bug).
class TikTokScrollPhysics extends PageScrollPhysics {
  const TikTokScrollPhysics({super.parent});

  @override
  TikTokScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      TikTokScrollPhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring =>
      SpringDescription(mass: 0.3, stiffness: 40.0, damping: 10.4);

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // If we're out of bounds, use the parent's simulation (usually clamping/spring-back)
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    // Find the current and target pages
    final double page = position.pixels / position.viewportDimension;
    final int currentPage = page.floor();
    final double fraction = page - currentPage;
    final int targetPage;

    // Lowered velocity threshold to 200.0 to make light flick gestures effortlessly turn pages.
    if (velocity.abs() > 70.0) {
      targetPage = velocity < 0.0 ? page.floor() : page.ceil();
    } else {
      // Slow releases snap based on residual velocity direction and a highly responsive 15% threshold:
      // Dragging forward (velocity >= 0) commits to next page if past 15%.
      // Dragging backward (velocity < 0) commits to previous page if past 15% (fraction < 85%).
      if (velocity > 0.0) {
        targetPage = fraction > 0.15 ? currentPage + 1 : currentPage;
      } else if (velocity < 0.0) {
        targetPage = fraction < 0.85 ? currentPage : currentPage + 1;
      } else {
        // Zero velocity case (pure release with no movement energy): snap to nearest boundary.
        targetPage = page.round();
      }
    }

    final double targetPixels = targetPage * position.viewportDimension;
    if (targetPixels == position.pixels) {
      return null;
    }

    // Return a physics simulation that explicitly respects the drag release velocity
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      targetPixels,
      velocity,
      tolerance: toleranceFor(position),
    );
  }
}
