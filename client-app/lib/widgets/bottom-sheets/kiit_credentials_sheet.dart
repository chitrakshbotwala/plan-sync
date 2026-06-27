import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';
import 'package:provider/provider.dart';

/// Collects the student's KIIT portal registration number + password so the
/// app can fetch attendance. Credentials are saved to the device keystore and
/// never leave the device except as a login to the official KIIT portal.
class KiitCredentialsSheet extends StatefulWidget {
  const KiitCredentialsSheet({super.key});

  @override
  State<KiitCredentialsSheet> createState() => _KiitCredentialsSheetState();
}

class _KiitCredentialsSheetState extends State<KiitCredentialsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _regController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<AttendanceViewModel>();
    _regController.text = viewModel.registrationNumber ?? '';
  }

  @override
  void dispose() {
    _regController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _connect() {
    if (!_formKey.currentState!.validate()) return;
    final viewModel = context.read<AttendanceViewModel>();
    unawaited(viewModel.connect(
      registrationNumber: _regController.text.trim(),
      password: _passController.text,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    InputDecoration fieldDecoration(String hint, IconData iconData) =>
        InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 16,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(iconData,
                color: colorScheme.onSurface.withValues(alpha: 0.6), size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(),
          filled: true,
          fillColor: colorScheme.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.error, width: 2),
          ),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Text(
              'Connect KIIT Portal',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Sign in with your SAP portal credentials to pull your '
              'attendance.\nThey are stored securely on this device only.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.65),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _regController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
              decoration:
                  fieldDecoration('Roll number', Icons.badge_outlined),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter your roll number'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passController,
              obscureText: _obscure,
              style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
              decoration:
                  fieldDecoration('Password', Icons.lock_outline_rounded)
                      .copyWith(
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                    size: 22,
                  ),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter your password' : null,
              onFieldSubmitted: (_) => _connect(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                onPressed: _connect,
                child: Text(
                  'Connect & fetch attendance',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Plan Sync never sends your password anywhere except the '
                    'official KIIT portal',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
