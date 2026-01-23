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


// const BASEURL = 'http://13.127.143.122:9799/api/v1/';
const BASEURL = 'http://3.109.110.211/api/v1/';

