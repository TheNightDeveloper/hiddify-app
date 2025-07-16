import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/core/http_client/http_client_provider.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';

part 'auth_repository.g.dart';

// مخزن احراز هویت
// Handles authentication data logic.
abstract class AuthRepository with AppLogger {
  Future<void> login(String username, String password);
  Future<void> logout();
  Future<bool> isAuthenticated();
}

class AuthRepositoryImpl extends AuthRepository {
  AuthRepositoryImpl(this.ref);
  final Ref ref;

  @override
  Future<void> login(String username, String password) async {
    loggy.debug("attempting to login with username: $username");
    final client = ref.read(httpClientProvider);

    try {
      // Log the exact request we're making
      loggy.debug("sending login request to: https://iam.axiomsoftwaregroup.website/service/api/v1/auth/email");
      loggy.debug("request body: {'Email': '$username', 'Password': '${password.substring(0, 2)}***'}");

      final response = await client.post("https://iam.axiomsoftwaregroup.website/service/api/v1/auth/email", data: {"Email": username, "Password": password});

      // Log the response
      loggy.debug("received response with status: ${response.statusCode}");
      loggy.debug("response body: ${response.data}");

      if (response.statusCode == 200) {
        loggy.info("login successful, cookies stored");
        return;
      }
      loggy.warning("login failed with status: ${response.statusCode}");
      throw Exception("Login failed: ${response.statusCode} - ${response.statusMessage}");
    } on DioException catch (e, stackTrace) {
      // Handle Dio-specific errors
      loggy.error("Dio error during login: ${e.type}", e, stackTrace);
      loggy.error("Error message: ${e.message}");
      if (e.response != null) {
        loggy.error("Response status: ${e.response?.statusCode}");
        loggy.error("Response data: ${e.response?.data}");
      }
      throw Exception("Network error: ${e.message}");
    } catch (e, stackTrace) {
      loggy.error("login request failed", e, stackTrace);
      throw Exception("Login failed: ${e.toString()}");
    }
  }

  @override
  Future<void> logout() async {
    loggy.debug("logging out and clearing cookies");
    await ref.read(httpClientProvider).clearCookies();
    // TODO: add any other cleanup logic if needed
  }

  @override
  Future<bool> isAuthenticated() async {
    loggy.debug("checking authentication status");
    // TODO: check for a valid session cookie
    loggy.debug("MOCK: isAuthenticated returning true");

    return true;
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl(ref);
}
