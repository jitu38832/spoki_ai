class CommonResponse {
  final bool? success;
  final String? message;

  CommonResponse({
    this.success,
    this.message,
  });

  CommonResponse.fromJson(Map<String, dynamic> json)
      : success = json['success'] as bool?,
        message = json['message'] as String?;

  Map<String, dynamic> toJson() => {
    'success' : success,
    'message' : message
  };
}