import 'package:json_annotation/json_annotation.dart';

part 'dto.g.dart';

@JsonSerializable()
class VersionDto {
  late String version;

  VersionDto({required this.version});

  factory VersionDto.fromJson(Map<String, dynamic> json) => _$VersionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VersionDtoToJson(this);
}

@JsonSerializable()
class OpenToolDto {
  late String openToolId;
  late String description;

  OpenToolDto({required this.openToolId, required this.description});

  factory OpenToolDto.fromJson(Map<String, dynamic> json) => _$OpenToolDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OpenToolDtoToJson(this);
}
