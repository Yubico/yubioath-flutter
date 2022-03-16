import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
class FidoState with _$FidoState {
  const FidoState._();

  factory FidoState({
    required Map<String, dynamic> info,
    required bool locked,
  }) = _FidoState;

  factory FidoState.fromJson(Map<String, dynamic> json) =>
      _$FidoStateFromJson(json);

  bool get hasPin => info['options']['clientPin'] == true;
}
