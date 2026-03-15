import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Helper for building GetPage with common transitions. Not used by app_pages; kept for consistency.
class PageTransitions {
  PageTransitions._();

  static const Duration duration = Duration(milliseconds: 350);

  static GetPage fade(Widget page, {String? name}) {
    return GetPage(
      name: name ?? '/',
      page: () => page,
      transition: Transition.fade,
    );
  }

  static GetPage slideLeft(Widget page, {String? name}) {
    return GetPage(
      name: name ?? '/',
      page: () => page,
      transition: Transition.leftToRight,
    );
  }

  static GetPage slideUp(Widget page, {String? name}) {
    return GetPage(
      name: name ?? '/',
      page: () => page,
      transition: Transition.downToUp,
    );
  }

  static GetPage zoom(Widget page, {String? name}) {
    return GetPage(
      name: name ?? '/',
      page: () => page,
      transition: Transition.zoom,
    );
  }
}
