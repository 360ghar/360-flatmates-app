/// One entry of `error.details.fields` on a 422 response.
class ApiFieldError {
  const ApiFieldError({
    required this.field,
    required this.msg,
    required this.type,
  });

  /// The field with its source prefix, for example `body.price` or
  /// `query.limit`.
  final String field;
  final String msg;
  final String type;

  /// [field] without the `body.` prefix, as the forms name their inputs.
  String get formField =>
      field.startsWith('body.') ? field.substring('body.'.length) : field;
}

/// The backend error body: `{"error": {"code", "message", "details"}}`.
///
/// Every non-2xx JSON response from the API has this shape. A 422 carries the
/// field errors in `details.fields` (always present, possibly empty).
class ApiErrorEnvelope {
  const ApiErrorEnvelope({
    required this.code,
    required this.message,
    this.details = const {},
    this.fields = const [],
  });

  final String code;
  final String message;
  final Map<String, dynamic> details;
  final List<ApiFieldError> fields;

  /// The envelope in [body], or null when [body] is not an error envelope
  /// (an HTML gateway page, an empty body, a different JSON shape).
  static ApiErrorEnvelope? tryParse(Object? body) {
    if (body is! Map) return null;
    final error = body['error'];
    if (error is! Map) return null;
    final code = error['code'];
    final message = error['message'];
    if (code is! String || message is! String) return null;
    final rawDetails = error['details'];
    final details = rawDetails is Map
        ? Map<String, dynamic>.from(rawDetails)
        : const <String, dynamic>{};
    final rawFields = details['fields'];
    final fields = <ApiFieldError>[];
    if (rawFields is List) {
      for (final item in rawFields) {
        if (item is! Map) continue;
        final field = item['field'];
        final msg = item['msg'];
        if (field is! String || msg is! String) continue;
        fields.add(
          ApiFieldError(
            field: field,
            msg: msg,
            type: item['type']?.toString() ?? '',
          ),
        );
      }
    }
    return ApiErrorEnvelope(
      code: code,
      message: message,
      details: details,
      fields: fields,
    );
  }
}
