class FeeObject {
  final dynamic fast;
  final dynamic medium;
  final dynamic slow;

  FeeObject({this.fast, this.medium, this.slow});

  factory FeeObject.fromJson(Map<String, dynamic> json) {
    return FeeObject(
        fast: json['fast'], medium: json['average'], slow: json['slow']);
  }

  @override
  String toString() {
    return "{fast: $fast, medium: $medium, slow: $slow}";
  }
}
