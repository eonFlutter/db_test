import 'package:db_demo/generated/json/base/json_convert_content.dart';
import 'package:db_demo/json_model.dart';

JsonModel $JsonModelFromJson(Map<String, dynamic> json) {
  final JsonModel jsonModel = JsonModel();
  final String? valueNo = jsonConvert.convert<String>(json['valueNo']);
  if (valueNo != null) {
    jsonModel.valueNo = valueNo;
  }
  final String? other = jsonConvert.convert<String>(json['other']);
  if (other != null) {
    jsonModel.other = other;
  }
  return jsonModel;
}

Map<String, dynamic> $JsonModelToJson(JsonModel entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['valueNo'] = entity.valueNo;
  data['other'] = entity.other;
  return data;
}

extension JsonModelExtension on JsonModel {
  JsonModel copyWith({
    String? valueNo,
    String? other,
  }) {
    return JsonModel()
      ..valueNo = valueNo ?? this.valueNo
      ..other = other ?? this.other;
  }
}