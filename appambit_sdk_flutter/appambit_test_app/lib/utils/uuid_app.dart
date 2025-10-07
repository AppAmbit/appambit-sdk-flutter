import 'dart:math';
class UuidApp {
  

static String generateUuidV4() {
  final Random random = Random();
  final List<int> bytes = List<int>.generate(16, (_) => random.nextInt(256));

  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < 16; i++) {
    buffer.write(bytes[i].toRadixString(16).padLeft(2, '0'));
    if (i == 3 || i == 5 || i == 7 || i == 9) {
      buffer.write('-');
    }
  }
  return buffer.toString();
}
}