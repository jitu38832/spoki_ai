import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> isInternetConnected() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult.contains(ConnectivityResult.mobile)) {
    return true;
  } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
    return true;
  }
  return false;
}
const String loginDesc = "Let's login with your Email Id";
const String registeredEmail = "Registered Email";
const String notConnected = "You are no connected to internet";
final RegExp emailRegex = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
);


// Live
// ignore: constant_identifier_names
const BASEURL = 'http://3.109.110.211/api/v1/';
// const BASEURL = 'http://13.127.143.122:9799/api/v1/';

// Development (local) — same /api/v1/ suffix as production; drop it if your server mounts routes at root
// const BASEURL = 'http://192.168.1.7:9799/api/v1/';

