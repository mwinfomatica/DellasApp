class RetornoConfBaixaModel {
  final bool error;
  final String message;

  RetornoConfBaixaModel({
    required this.error,
    required this.message,
  });

  factory RetornoConfBaixaModel.fromJson(Map<String, dynamic> json) {
    return RetornoConfBaixaModel(
      error: json['error'],
      message: json['message'],
    );
  }
}
