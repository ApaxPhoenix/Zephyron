import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appwrite/appwrite.dart';
import 'package:zephyron/main.dart';
import 'dart:developer' as developer;
import 'dart:async';

class MiddlewarePage extends StatefulWidget {
  const MiddlewarePage({super.key});

  @override
  State<MiddlewarePage> createState() => MiddlewarePageState();
}

class MiddlewarePageState extends State<MiddlewarePage> {
  final List<TextEditingController> controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> nodes = List.generate(6, (_) => FocusNode());
  bool loading = false;
  String? warning;
  bool disabled = false;
  int countdown = 0;
  Timer? timer;
  String? id;
  String? email;

  @override
  void initState() {
    super.initState();
    try {
      account
          .get()
          .then((user) {
            if (mounted) {
              if (user.emailVerification) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted)
                    Navigator.pushReplacementNamed(context, '/dashboard');
                });
              } else {
                setState(() {
                  email = user.email;
                });
              }
            }
          })
          .catchError((error) {
            developer.log(
              'Error: $error',
              error: error,
              name: 'MiddlewarePage.init',
            );
          });
    } catch (error) {
      developer.log('Error: $error', error: error, name: 'MiddlewarePage.init');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Verify Your Email',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enter the 6-digit verification code sent to your email.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 50,
                      child: TextField(
                        controller: controllers[index],
                        focusNode: nodes[index],
                        enabled: !loading,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        textInputAction: index < 5
                            ? TextInputAction.next
                            : TextInputAction.done,
                        maxLength: 1,
                        style: Theme.of(context).textTheme.headlineSmall,
                        decoration: const InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          try {
                            if (warning != null) setState(() => warning = null);

                            if (value.isEmpty) {
                              if (index > 0) nodes[index - 1].requestFocus();
                            } else if (value.length == 1) {
                              if (index < 5) {
                                nodes[index + 1].requestFocus();
                              } else {
                                nodes[index].unfocus();
                              }

                              if (controllers.every((c) => c.text.isNotEmpty) &&
                                  !loading &&
                                  id != null) {
                                final code = controllers
                                    .map((c) => c.text)
                                    .join();

                                setState(() {
                                  loading = true;
                                  warning = null;
                                });

                                account
                                    .createSession(userId: id!, secret: code)
                                    .then((_) {
                                      if (mounted) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (mounted)
                                                Navigator.pushReplacementNamed(
                                                  context,
                                                  '/dashboard',
                                                );
                                            });
                                      }
                                    })
                                    .catchError((error) {
                                      if (mounted) {
                                        if (error is AppwriteException &&
                                            error.type ==
                                                'user_session_already_exists') {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                if (mounted)
                                                  Navigator.pushReplacementNamed(
                                                    context,
                                                    '/dashboard',
                                                  );
                                              });
                                        } else if (error is AppwriteException) {
                                          setState(() {
                                            warning = switch (error.type) {
                                              'user_invalid_token' =>
                                                'Invalid verification code. Please try again.',
                                              _ =>
                                                'Verification failed. Please try again.',
                                            };
                                          });
                                          developer.log(
                                            'Error: $error',
                                            error: error,
                                            name: 'MiddlewarePage.verify',
                                          );
                                        } else {
                                          setState(
                                            () => warning =
                                                'An unexpected error occurred.',
                                          );
                                          developer.log(
                                            'Error: $error',
                                            error: error,
                                            name: 'MiddlewarePage.verify',
                                          );
                                        }
                                      }
                                    })
                                    .whenComplete(() {
                                      if (mounted)
                                        setState(() => loading = false);
                                    });
                              }
                            } else if (value.length > 1) {
                              controllers[index].text = value[0];
                              controllers[index].selection =
                                  TextSelection.fromPosition(
                                    TextPosition(offset: 1),
                                  );
                              if (index < 5) nodes[index + 1].requestFocus();
                            }
                          } catch (error) {
                            developer.log(
                              'Error: $error',
                              error: error,
                              name: 'MiddlewarePage.change',
                            );
                          }
                        },
                      ),
                    );
                  }),
                ),
                if (warning != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    warning!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: disabled
                      ? null
                      : () async {
                          if (disabled || email == null) return;

                          setState(() {
                            disabled = true;
                            countdown = 60;
                          });

                          try {
                            final token = await account.createEmailToken(
                              userId: ID.unique(),
                              email: email!,
                            );

                            if (!mounted) return;

                            setState(() => id = token.userId);

                            timer?.cancel();
                            timer = Timer.periodic(const Duration(seconds: 1), (
                              t,
                            ) {
                              try {
                                if (!mounted) {
                                  t.cancel();
                                  return;
                                }
                                if (countdown > 0) {
                                  setState(() => countdown--);
                                } else {
                                  t.cancel();
                                  setState(() => disabled = false);
                                }
                              } catch (error) {
                                developer.log(
                                  'Error: $error',
                                  error: error,
                                  name: 'MiddlewarePage.timer',
                                );
                                t.cancel();
                              }
                            });
                          } catch (error) {
                            if (!mounted) return;

                            setState(() => disabled = false);
                            if (error is AppwriteException) {
                              setState(() {
                                warning = switch (error.type) {
                                  'general_rate_limit_exceeded' =>
                                    'Too many requests. Please wait before trying again.',
                                  _ => 'Failed to send code. Please try again.',
                                };
                              });
                            } else {
                              setState(
                                () => warning = 'An unexpected error occurred.',
                              );
                            }
                            developer.log(
                              'Error: $error',
                              error: error,
                              name: 'MiddlewarePage.resend',
                            );
                          }
                        },
                  child: disabled
                      ? Text('Retry in $countdown seconds')
                      : const Text('Send Code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    try {
      timer?.cancel();
      for (var controller in controllers) {
        controller.dispose();
      }
      for (var node in nodes) {
        node.dispose();
      }
      super.dispose();
    } catch (error) {
      developer.log(
        'Error: $error',
        error: error,
        name: 'MiddlewarePage.dispose',
      );
    }
  }
}
