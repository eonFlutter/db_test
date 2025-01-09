import 'package:db_demo/generated/json/base/json_field.dart';
import 'package:db_demo/generated/json/json_model.g.dart';
import 'dart:convert';

import 'db/base_model.dart';
export 'package:db_demo/generated/json/json_model.g.dart';

@JsonSerializable()
class JsonModel extends BaseModel {
	late String valueNo = '';
	late String other = '';

	JsonModel();

	factory JsonModel.fromJson(Map<String, dynamic> json) => $JsonModelFromJson(json);

	Map<String, dynamic> toJson() => $JsonModelToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}


	// ----- about db -----
  @override
	fromMap(Map<String, dynamic> map) {
		JsonModel model = $JsonModelFromJson(map);
		model.id = map.containsKey('id') ? map['id'] as int? : null;
		return model;
	}

  @override
	String get tableName => 't_name'; // 表名

  @override
	Map<String, dynamic> toMap() {
		Map<String, dynamic> map = $JsonModelToJson(this);
		map['id'] = id;
		return map;
	}
}