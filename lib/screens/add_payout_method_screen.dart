import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_models.dart';
import '../providers/payout_method_provider.dart';
import '../utils/app_theme.dart';
import '../utils/payout_security.dart';
import '../utils/secure_logger.dart';

class AddPayoutMethodScreen extends ConsumerStatefulWidget {
  const AddPayoutMethodScreen({super.key});

  @override
  ConsumerState<AddPayoutMethodScreen> createState() =>
      _AddPayoutMethodScreenState();
}

class _AddPayoutMethodScreenState extends ConsumerState<AddPayoutMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'bank_transfer'; // 'bank_transfer' or 'upi'

  // Bank transfer fields
  final _accountHolderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();

  // UPI fields
  final _upiIdController = TextEditingController();

  @override
  void dispose() {
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  Future<void> _savePayoutMethod() async {
    if (!_formKey.currentState!.validate()) return;

    // Log security event (sanitized)
    SecureLogger.logSecurityEvent(
      'Payout method update attempted',
      context: {'type': _selectedType},
    );

    // Sanitize inputs before sending
    final method = _selectedType == 'upi'
        ? PayoutMethod(
            type: 'upi',
            accountHolderName: _accountHolderController.text.trim(),
            upiId: PayoutSecurity.sanitizeUpiId(_upiIdController.text),
          )
        : PayoutMethod(
            type: 'bank_transfer',
            accountHolderName: _accountHolderController.text.trim(),
            bankName: _bankNameController.text.trim(),
            accountNumber: PayoutSecurity.sanitizeAccountNumber(
              _accountNumberController.text,
            ),
            ifscCode: PayoutSecurity.sanitizeIfscCode(_ifscCodeController.text),
          );

    final success = await ref
        .read(payoutMethodProvider.notifier)
        .updatePayoutMethod(method);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payout method saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final payoutMethodState = ref.watch(payoutMethodProvider);

    return SecureScreen(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Add Payout Method'),
          backgroundColor: AppTheme.surface,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Type Selection
              _buildTypeSelector(),
              const SizedBox(height: 24),

              // Common Field - Account Holder Name
              _buildTextField(
                controller: _accountHolderController,
                label: 'Account Holder Name',
                hint: 'Enter name as per bank records',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter account holder name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Type-specific fields
              if (_selectedType == 'upi') ...[
                _buildTextField(
                  controller: _upiIdController,
                  label: 'UPI ID',
                  hint: 'example@upi',
                  icon: Icons.payment_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter UPI ID';
                    }
                    final sanitized = PayoutSecurity.sanitizeUpiId(value);
                    if (!PayoutSecurity.isValidUpiId(sanitized)) {
                      return 'Enter valid UPI ID (e.g., name@upi)';
                    }
                    return null;
                  },
                ),
              ] else ...[
                _buildTextField(
                  controller: _bankNameController,
                  label: 'Bank Name',
                  hint: 'e.g., State Bank of India',
                  icon: Icons.account_balance_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter bank name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _accountNumberController,
                  label: 'Account Number',
                  hint: 'Enter your account number',
                  icon: Icons.account_circle_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter account number';
                    }
                    final sanitized = PayoutSecurity.sanitizeAccountNumber(
                      value,
                    );
                    if (!PayoutSecurity.isValidAccountNumber(sanitized)) {
                      return 'Enter valid account number (9-18 digits)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _ifscCodeController,
                  label: 'IFSC Code',
                  hint: 'e.g., SBIN0001234',
                  icon: Icons.confirmation_number_outlined,
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter IFSC code';
                    }
                    final sanitized = PayoutSecurity.sanitizeIfscCode(value);
                    if (!PayoutSecurity.isValidIfscCode(sanitized)) {
                      return 'Enter valid IFSC code (e.g., SBIN0001234)';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 32),

              // Error Message
              if (payoutMethodState.updateErrorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          payoutMethodState.updateErrorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: payoutMethodState.isUpdating
                      ? null
                      : _savePayoutMethod,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: payoutMethodState.isUpdating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Payout Method',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Info Card
              _buildInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeOption(
              title: 'Bank Transfer',
              icon: Icons.account_balance,
              isSelected: _selectedType == 'bank_transfer',
              onTap: () => setState(() => _selectedType = 'bank_transfer'),
            ),
          ),
          Expanded(
            child: _buildTypeOption(
              title: 'UPI',
              icon: Icons.payment,
              isSelected: _selectedType == 'upi',
              onTap: () => setState(() => _selectedType = 'upi'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.textPrimary : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization? textCapitalization,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization ?? TextCapitalization.none,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.blue[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'Secure & Verified',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('Your bank details are encrypted and stored securely'),
          const SizedBox(height: 8),
          _buildInfoItem('We verify your account before processing payouts'),
          const SizedBox(height: 8),
          _buildInfoItem('You can update these details anytime from settings'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}
