import 'package:get/get.dart';

import '../controllers/login_controller.dart';
import '../services/demo_login_service.dart';
import '../services/firebase_account_service.dart';
import '../services/login_permissions_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(LoginPermissions(), permanent: true);
    Get.put(DemoLoginService(), permanent: true);
    Get.put(FirebaseAccountService(), permanent: true);
    Get.put(LoginController(), permanent: true);
  }
}
