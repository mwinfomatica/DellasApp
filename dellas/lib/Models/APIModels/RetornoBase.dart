class RetornoBaseModel {
  bool? error = false;
  String? message = "";
  Object? data = Object();

  RetornoBaseModel(
      { this.error,  this.message,  this.data});

  RetornoBaseModel.fromJson(Map<String, dynamic> json) {
    this.error = json['error'];
    this.message = json['message'];
    this.data = json['data'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['error'] = this.error;
    data['message'] = this.message;
    data['data'] = this.data;
    return data;
  }
}
