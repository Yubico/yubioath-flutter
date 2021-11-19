import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
class Version with _$Version {
  const Version._();
  const factory Version(int major, int minor, int patch) = _Version;

  factory Version.fromJson(List<dynamic> values) {
    return Version(values[0], values[1], values[2]);
  }

  List<dynamic> toJson() => [major, minor, patch];

  @override
  String toString() {
    return '$major.$minor.$patch';
  }
}

@Freezed(unionKey: 'kind')
class RpcResponse with _$RpcResponse {
  factory RpcResponse.success(Map<String, dynamic> body) = Success;
  factory RpcResponse.signal(String status, Map<String, dynamic> body) = Signal;
  factory RpcResponse.error(
      String status, String message, Map<String, dynamic> body) = RpcError;

  factory RpcResponse.fromJson(Map<String, dynamic> json) =>
      _$RpcResponseFromJson(json);
}
