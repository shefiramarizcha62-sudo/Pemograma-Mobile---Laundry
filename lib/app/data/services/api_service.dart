import 'package:dio/dio.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio dio;

  ApiService._internal() {
    dio = Dio(BaseOptions(
      baseUrl: 'https://68fc553a96f6ff19b9f4d297.mockapi.io/api/v1/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ))
      ..interceptors.add(LogInterceptor(
        request: true,
        responseBody: true,
        logPrint: (obj) => print('🟣 [API LOG] $obj'),
      ));
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters,
      ProgressCallback? onReceiveProgress}) async {
    return dio.get(path,
        queryParameters: queryParameters, onReceiveProgress: onReceiveProgress);
  }
}
