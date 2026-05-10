import 'package:dio/dio.dart';
import '../../errors/error_presenter.dart';

final class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appFailure = ErrorPresenter.fromDio(err, err.stackTrace);

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: appFailure,
        message: err.message,
        stackTrace: err.stackTrace,
      ),
    );
  }
}
