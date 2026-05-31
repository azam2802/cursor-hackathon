import 'package:firebase_auth/firebase_auth.dart';

/// Maps [FirebaseAuthException] codes to user-facing Russian messages.
String authErrorMessage(FirebaseAuthException exception) {
  switch (exception.code) {
    case 'invalid-email':
      return 'Некорректный email';
    case 'user-disabled':
      return 'Аккаунт заблокирован';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Неверный email или пароль';
    case 'email-already-in-use':
      return 'Этот email уже зарегистрирован';
    case 'weak-password':
      return 'Пароль слишком слабый (минимум 6 символов)';
    case 'too-many-requests':
      return 'Слишком много попыток. Попробуйте позже';
    case 'operation-not-allowed':
      return 'Этот способ входа не включён в Firebase';
    case 'network-request-failed':
      return 'Ошибка сети. Проверьте подключение';
    default:
      return 'Ошибка входа. Попробуйте ещё раз';
  }
}
