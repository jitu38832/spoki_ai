class ResponseData {
  int? statusCode;
  dynamic response;

  ResponseData({required this.statusCode, required this.response});
}

  class ErrorData {
  String message;
  int? code;

  ErrorData({required this.message,  this.code});
}