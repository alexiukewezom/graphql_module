part of 'graphql_module.dart';

enum _RefreshTokenStatus { refreshing, ready, rotten }

class GraphModuleState {
  final _RefreshTokenStatus refreshTokenStatus;
  final Map<String, String> headers;
  final String baseUrl;
  final String? wsUrl;

  GraphModuleState({
    this.refreshTokenStatus = _RefreshTokenStatus.ready,
    required this.baseUrl,
    this.headers = const {},
    this.wsUrl,
  });

  GraphModuleState copyWith({
    _RefreshTokenStatus? refreshTokenStatus,
    Map<String, String>? headers,
    String? baseUrl,
    String? wsUrl,
  }) {
    return GraphModuleState(
      refreshTokenStatus: refreshTokenStatus ?? this.refreshTokenStatus,
      headers: headers ?? this.headers,
      baseUrl: baseUrl ?? this.baseUrl,
      wsUrl: wsUrl ?? this.wsUrl,
    );
  }
}
