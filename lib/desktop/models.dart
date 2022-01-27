import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@Freezed(unionKey: 'kind')
class RpcResponse with _$RpcResponse {
  factory RpcResponse.success(Map<String, dynamic> body) = Success;
  factory RpcResponse.signal(String status, Map<String, dynamic> body) = Signal;
  factory RpcResponse.error(
      String status, String message, Map<String, dynamic> body) = RpcError;

  factory RpcResponse.fromJson(Map<String, dynamic> json) =>
      _$RpcResponseFromJson(json);
}

@freezed
class RpcState with _$RpcState {
  const factory RpcState(String version) = _RpcState;
}
