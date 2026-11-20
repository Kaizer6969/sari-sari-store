/// Non-web / test fallback (no-op so unit & widget tests pass cleanly)
void playTruckHornImpl() {
  // No-op in headless VM tests
}

/// Fallback customer speech for unit tests
void speakCustomerTextImpl(
  String text, {
  double pitch = 1.0,
  double rate = 1.0,
  String? personaId,
  String? clipType,
}) {
  // No-op in headless VM tests
}
