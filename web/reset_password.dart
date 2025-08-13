import 'dart:js_interop';
import 'dart:js_util' as js_util; // Add this
import 'package:web/web.dart' as web;

// Interop classes: unchanged
@JS('firebase.auth')
external FirebaseAuth get firebaseAuth;

@JS()
@staticInterop
class FirebaseAuth {}

extension FirebaseAuthExtension on FirebaseAuth {
  external JSPromise confirmPasswordReset(String oobCode, String newPassword);
}

@JS()
@staticInterop
class JSPromise {}

extension on JSPromise {
  external JSPromise then(
      JSFunction onFulfilled, [
        JSFunction? onRejected,
      ]);
}

@JS('undefined')
external JSAny get jsUndefined;

// Convert a Dart function to JSFunction
JSFunction allowJS(Function fn) => js_util.allowInterop(fn) as JSFunction;

void main() {
  final url = Uri.parse(web.window.location.href);
  final mode = url.queryParameters['mode'];
  final oobCode = url.queryParameters['oobCode'];

  final container = web.document.querySelector('#container');

  if (mode == 'resetPassword' && oobCode != null) {
    final input = web.HTMLInputElement()
      ..type = 'password'
      ..placeholder = 'Enter new password'
      ..style.width = '100%'
      ..style.marginBottom = '10px';

    final button = web.HTMLButtonElement()
      ..textContent = 'Reset Password'
      ..style.marginTop = '10px';

    final title = web.document.createElement('h2')..textContent = 'Reset Your Password';

    button.addEventListener(
      'click',
      allowJS(() {
        final newPassword = input.value ?? '';
        if (newPassword.length < 6) {
          web.window.alert('Password must be at least 6 characters.');
          return;
        }

        firebaseAuth.confirmPasswordReset(oobCode, newPassword).then(
          allowJS(() {
            web.window.alert('Password reset successful!');
            web.window.location.href = '/';
            return jsUndefined;
          }),
          allowJS((error) {
            // Try to get the error message property
            var errorMsg = js_util.getProperty(error, 'message') ?? error.toString();
            web.window.alert('Reset failed: $errorMsg');
            return jsUndefined;
          }),
        );
      }),
    );

    if (container != null) {
      while (container.firstChild != null) {
        container.removeChild(container.firstChild!);
      }
    }
// (Optional) clear any existing content
    container?.appendChild(title);
    container?.appendChild(input);
    container?.appendChild(button);
  } else {
    container?.textContent = 'Invalid or missing password reset link.';
  }
}
