import 'package:flutter/foundation.dart';
import 'package:graphql/client.dart';

class AppResponse<S> {
  final bool success;
  final int code;
  final S data;
  final List<GraphQLError> graphErrors;

  AppResponse({
    this.success = false,
    this.code = -1,
    required this.data,
    this.graphErrors = const [],
  });

  AppResponse<S> copyWith({
    bool? success,
    int? code,
    S? data,
    List<GraphQLError>? graphErrors,
  }) {
    return AppResponse<S>(
      success: success ?? this.success,
      code: code ?? this.code,
      data: data ?? this.data,
      graphErrors: graphErrors ?? this.graphErrors,
    );
  }

  AppResponse<S?> newGeneric<S>({
    bool? success,
    int? code,
    S? data,
    List<GraphQLError>? graphErrors,
  }) {
    return AppResponse<S?>(
      success: success ?? this.success,
      code: code ?? this.code,
      data: data,
      graphErrors: graphErrors ?? this.graphErrors,
    );
  }

  @override
  String toString() {
    return 'AppResponse(success: $success, code: $code, data: $data, graphErrors: $graphErrors)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppResponse<S> &&
        other.success == success &&
        other.code == code &&
        other.data == data &&
        listEquals(other.graphErrors, graphErrors);
  }

  @override
  int get hashCode {
    return success.hashCode ^
        code.hashCode ^
        data.hashCode ^
        graphErrors.hashCode;
  }
}
