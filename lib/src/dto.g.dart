// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VersionDto _$VersionDtoFromJson(Map<String, dynamic> json) => VersionDto(
      version: json['version'] as String,
    );

Map<String, dynamic> _$VersionDtoToJson(VersionDto instance) =>
    <String, dynamic>{
      'version': instance.version,
    };

OpenToolDto _$OpenToolDtoFromJson(Map<String, dynamic> json) => OpenToolDto(
      openToolId: json['openToolId'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$OpenToolDtoToJson(OpenToolDto instance) =>
    <String, dynamic>{
      'openToolId': instance.openToolId,
      'description': instance.description,
    };

TaskIdDto _$TaskIdDtoFromJson(Map<String, dynamic> json) => TaskIdDto(
      taskId: json['taskId'] as String,
    );

Map<String, dynamic> _$TaskIdDtoToJson(TaskIdDto instance) => <String, dynamic>{
      'taskId': instance.taskId,
    };
