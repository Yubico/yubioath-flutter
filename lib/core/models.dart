import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';

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

@freezed
class Pair<T1, T2> with _$Pair<T1, T2> {
  factory Pair(T1 first, T2 second) = _Pair<T1, T2>;
}
