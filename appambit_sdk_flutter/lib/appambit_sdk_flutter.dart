
import 'appambit_sdk_flutter_platform_interface.dart';

class AppambitSdkFlutter {
  Future<String?> getPlatformVersion() {
    return AppambitSdkFlutterPlatform.instance.getPlatformVersion();
  }
}
