import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ivy_path/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleActivation() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider.notifier);
    await auth.login(_codeController.text);
  }

  Future<void> _handleQRScan() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR code scanning coming soon!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'IvyPath',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn().slideY(
                      begin: -0.2,
                      duration: const Duration(milliseconds: 500),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Login with your activation code or scan QR code',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ).animate().fadeIn().slideY(
                      begin: -0.2,
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 200),
                    ),
                    const SizedBox(height: 48),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _codeController,
                              decoration: const InputDecoration(
                                labelText: 'Enter Activation Code',
                                prefixIcon: Icon(Icons.key),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your activation code';
                                }
                                if (value.length != 6) {
                                  return 'Activation code must be 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 24),
                            OutlinedButton.icon(
                              onPressed: _handleQRScan,
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('Scan QR Code'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: authState.when(
                        data: (_) => ElevatedButton(
                          onPressed: _handleActivation,
                          child: const Text('Continue'),
                        ),
                        loading: () => const ElevatedButton(
                          onPressed: null,
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, _) => Column(
                          children: [
                            Text(
                              error.toString(),
                              style: TextStyle(color: theme.colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _handleActivation,
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Help functionality coming soon!'),
                          ),
                        );
                      },
                      child: Text(
                        'Need Help?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}