library graphql_module;

import 'dart:async';

import 'package:get/get.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql/client.dart';
// ignore: implementation_imports
import 'package:graphql/src/core/_base_options.dart';

import 'package:web_socket_channel/io.dart';

import 'models/app_response.dart';
part 'state.dart';

class GraphModuleRefreshEngine {
  final Future<String?> Function() getRefreshToken;
  final Future<AppResponse> Function() sendRefresh;
  GraphModuleRefreshEngine({
    required this.getRefreshToken,
    required this.sendRefresh,
  });
}

class GraphModule extends Cubit<GraphModuleState> {
  final Function? onTokenRot;
  final Future<Map<String, String>> Function() getHeaders;
  final GraphModuleRefreshEngine? refreshEngine;
  final Function(OperationException? exception)? handleError;

  late GraphQLClient graphClient;

  GraphModule({
    required String baseUrl,
    String? wsUrl,
    this.onTokenRot,
    required this.getHeaders,
    this.refreshEngine,
    this.handleError,
  }) : super(GraphModuleState(baseUrl: baseUrl, wsUrl: wsUrl));

  static GraphModule get module => Get.find<GraphModule>();

  Future<GraphModule> init() async {
    await update();
    return this;
  }

  Future<void> update() async {
    emit(state.copyWith(headers: await getHeaders()));

    Link link = HttpLink(state.baseUrl, defaultHeaders: state.headers);

    if (state.wsUrl != null) {
      link = Link.split(
        (request) => request.isSubscription,
        WebSocketLink(
          state.wsUrl!,
          config: SocketClientConfig(
            connectFn: (url, protocols) => IOWebSocketChannel.connect(
              url,
              protocols: protocols,
              headers: state.headers,
            ),
          ),
        ),
        link,
      );
    }
    graphClient = GraphQLClient(
      cache: GraphQLCache(),
      link: link,
      defaultPolicies: DefaultPolicies(
        mutate: Policies(
          fetch: FetchPolicy.networkOnly,
        ),
        query: Policies(
          fetch: FetchPolicy.networkOnly,
        ),
      ),
    );
  }

  Future<AppResponse<dynamic>> request(
    BaseOptions options, {
    bool force = false,
    bool secondRequest = false,
    bool showError = true,
  }) async {
    print(runtimeType.toString() + ": request ...");
    if (!force && state.refreshTokenStatus == _RefreshTokenStatus.refreshing) {
      return _addToStack(options);
    } else {
      if (options is MutationOptions) {
        final response = await graphClient.mutate(options);
        if (!response.hasException) {
          return AppResponse(data: response.data, success: true);
        } else {
          if ((response.exception?.graphqlErrors.isNotEmpty ?? false) &&
              response.exception!.graphqlErrors.first.message ==
                  "Unauthorized" &&
              !secondRequest) {
            _refreshToken();
            return _addToStack(options);
          }
        }
        if (handleError != null && showError) handleError!(response.exception);

        return AppResponse(
          data: response.data,
          success: false,
          graphErrors: response.exception?.graphqlErrors ?? [],
        );
      } else if (options is QueryOptions) {
        final response = await graphClient.query(options);
        if (!response.hasException) {
          return AppResponse(data: response.data, success: true);
        } else {
          if ((response.exception?.graphqlErrors.isNotEmpty ?? false) &&
              response.exception!.graphqlErrors.first.message ==
                  "Unauthorized" &&
              !secondRequest) {
            _refreshToken();
            return _addToStack(options);
          }
        }
        if (handleError != null && showError) handleError!(response.exception);
        return AppResponse(
          data: response.data,
          success: false,
          graphErrors: response.exception?.graphqlErrors ?? [],
        );
      }
      return AppResponse(
        data: null,
        graphErrors: [
          const GraphQLError(message: 'Something error'),
        ],
        success: false,
      );
    }
  }

  Future<AppResponse<dynamic>> _addToStack(BaseOptions options) async {
    print(runtimeType.toString() + ": _addToStack...");

    if (state.refreshTokenStatus == _RefreshTokenStatus.ready) {
      return request(options);
    }

    await for (var state in stream) {
      if (state.refreshTokenStatus == _RefreshTokenStatus.ready) {
        return request(options, secondRequest: true);
      }
    }

    return AppResponse(
      data: null,
      success: false,
      graphErrors: [
        GraphQLError(message: 'Something error'),
      ],
    );
  }

  void _refreshToken() async {
    print(runtimeType.toString() + ": _refreshToken...");

    if (state.refreshTokenStatus == _RefreshTokenStatus.refreshing) return;

    emit(state.copyWith(refreshTokenStatus: _RefreshTokenStatus.refreshing));

    String? refreshToken;
    refreshToken = await refreshEngine!.getRefreshToken();

    if (refreshToken == null) {
      print(runtimeType.toString() + ": _refreshToken - null...");
      emit(state.copyWith(refreshTokenStatus: _RefreshTokenStatus.rotten));

      if (onTokenRot != null) onTokenRot!();
    } else {
      final response = await refreshEngine!.sendRefresh();
      update();

      emit(state.copyWith(
        refreshTokenStatus: response.success
            ? _RefreshTokenStatus.ready
            : _RefreshTokenStatus.rotten,
      ));
      print(runtimeType.toString() +
          ": refreshToken - success: ${response.success} ...");

      if (!response.success) if (onTokenRot != null) onTokenRot!();
    }
  }
}
