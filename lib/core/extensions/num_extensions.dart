extension NumExtensions on num {
  /// Delay in milliseconds for animations.
  Future<void> get delay => Future.delayed(Duration(milliseconds: toInt()));
}
