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
    // Fire the scrape and let the Attendance screen render the loading state;
    // don't block the sheet open for the whole fetch.
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

    InputDecoration decoration(String hint, Widget icon) => InputDecoration(
          hintText: hint,
          prefixIcon: icon,
          hintStyle:
              TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
          filled: true,
          fillColor: colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect KIIT Portal',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in with your SAP portal credentials to pull your '
              'attendance. They are stored securely on this device only.',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _regController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(color: colorScheme.onSurface),
              decoration: decoration(
                'Registration number',
                Icon(Icons.badge_outlined, color: colorScheme.onSurface),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter your registration number'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passController,
              obscureText: _obscure,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: decoration(
                'Password',
                Icon(Icons.lock_outline_rounded,
                    color: colorScheme.onSurface),
              ).copyWith(
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter your password' : null,
              onFieldSubmitted: (_) => _connect(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor:
                      WidgetStatePropertyAll(colorScheme.primary),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 14),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                onPressed: _connect,
                child: Text(
                  'Connect & fetch attendance',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.lock_outline,
                    size: 14,
                    color: colorScheme.onSurface.withOpacity(0.5)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Plan Sync never sends your password anywhere except the '
                    'official KIIT portal.',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 11,
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
