import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:ivy_path/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleActivation() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthProvider>().login(
      _codeController.text,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
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
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ),
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
                    if (auth.error != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          auth.error!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
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
                                if (value.length != 22) {
                                  return 'Activation code must be 22 characters';
                                }
                                return null;
                              },
                            ).animate().fadeIn().slideX(
                              begin: 0.2,
                              duration: const Duration(milliseconds: 500),
                              delay: const Duration(milliseconds: 400),
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
                            ).animate().fadeIn().slideX(
                              begin: -0.2,
                              duration: const Duration(milliseconds: 500),
                              delay: const Duration(milliseconds: 600),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn().scale(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 300),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleActivation,
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Continue'),
                      ),
                    ).animate().fadeIn().slideY(
                      begin: 0.2,
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 800),
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
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 1000),
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