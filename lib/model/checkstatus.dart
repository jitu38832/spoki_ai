class CheckStatusResponse {
  final bool key;

  CheckStatusResponse({
    required this.key,
  });

  factory CheckStatusResponse.fromJson(Map<String, dynamic> json) {
    return CheckStatusResponse(
      key: json['key'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
    };
  }
}
