import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../auth/auth_notifier.dart';
import '../../auth/auth_status.dart';
import '../../widgets/pill_logo.dart';
import '../../l10n/app_localizations.dart';
import '../onboarding/role_selection_screen.dart';

/// Signup screen for PillCare - creates new user accounts.
class SignupScreen extends StatefulWidget {
  static const routeName = '/signup';

  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  DateTime? _birthDate;
  int? _selectedDay;
  int? _selectedMonth;
  int? _selectedYear;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.loc.t('fillAllFields'))));
      return;
    }

    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.t('pleaseSelectBirthDate'))),
      );
      return;
    }

    if (_birthDate!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.t('birthDateFutureError'))),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.t('passwordTooShort'))),
      );
      return;
    }

    final auth = context.read<AuthNotifier>();
    setState(() => _isLoading = true);

    final success = await auth.signUp(
      name,
      email,
      password,
      birthDate: _birthDate!,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastEmail', email);
      if (!mounted) return;
      // Immediately take new users to role selection and block back navigation
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        (route) => false,
      );
    } else {
      if (!mounted) return;
      final msg =
          context.read<AuthNotifier>().lastErrorMessage ??
          context.loc.t('signupError');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _updateBirthDate() {
    if (_selectedDay != null &&
        _selectedMonth != null &&
        _selectedYear != null) {
      try {
        final date = DateTime(_selectedYear!, _selectedMonth!, _selectedDay!);
        setState(() => _birthDate = date);
      } catch (e) {
        // Invalid date combination (e.g., Feb 30)
        setState(() => _birthDate = null);
      }
    } else {
      setState(() => _birthDate = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = context.watch<AuthNotifier>().status;
    final isBusy = _isLoading || authStatus == AuthStatus.authenticating;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      body: Stack(
        children: [
          const _Blob(color: Color(0xFFBFE6FF), size: 220, top: -60, left: -70),
          const _Blob(
            color: Color(0xFFFFD9D6),
            size: 200,
            bottom: -40,
            left: 40,
          ),
          const _Blob(
            color: Color(0xFFCCF2EA),
            size: 240,
            bottom: -70,
            right: -60,
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      const Center(
                        child: PillLogoAnimated(
                          size: 90,
                          showHalo: false,
                          showBadgeCircle: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'PillCare',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF24948C),
                              ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        context.loc.t('joinUs'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2B2D31),
                            ),
                      ),
                      const SizedBox(height: 24),
                      _RoundedInput(
                        controller: _nameController,
                        hintText: context.loc.t('name'),
                        enabled: !isBusy,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 14),
                      _RoundedInput(
                        controller: _emailController,
                        hintText: context.loc.t('email'),
                        enabled: !isBusy,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _RoundedInput(
                        controller: _passwordController,
                        hintText: context.loc.t('password'),
                        enabled: !isBusy,
                        obscureText: true,
                      ),
                      const SizedBox(height: 14),
                      _BirthDateDropdowns(
                        selectedDay: _selectedDay,
                        selectedMonth: _selectedMonth,
                        selectedYear: _selectedYear,
                        enabled: !isBusy,
                        onDayChanged: (day) {
                          setState(() => _selectedDay = day);
                          _updateBirthDate();
                        },
                        onMonthChanged: (month) {
                          setState(() => _selectedMonth = month);
                          _updateBirthDate();
                        },
                        onYearChanged: (year) {
                          setState(() => _selectedYear = year);
                          _updateBirthDate();
                        },
                      ),
                      const SizedBox(height: 22),
                      isBusy
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              key: const Key('signupButton'),
                              onPressed: _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                backgroundColor: const Color(0xFF23C3AE),
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: Text(context.loc.t('signUp')),
                            ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.loc.t('haveAccount'),
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          TextButton(
                            key: const Key('loginLink'),
                            onPressed: isBusy
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: Text(
                              context.loc.t('signIn'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2B2D31),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundedInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _RoundedInput({
    required this.controller,
    required this.hintText,
    required this.enabled,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xFF23C3AE), width: 1.5),
        ),
      ),
    );
  }
}

class _BirthDateDropdowns extends StatelessWidget {
  final int? selectedDay;
  final int? selectedMonth;
  final int? selectedYear;
  final bool enabled;
  final ValueChanged<int?> onDayChanged;
  final ValueChanged<int?> onMonthChanged;
  final ValueChanged<int?> onYearChanged;

  const _BirthDateDropdowns({
    required this.selectedDay,
    required this.selectedMonth,
    required this.selectedYear,
    required this.enabled,
    required this.onDayChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List.generate(120, (i) => now.year - i);
    final locale = Localizations.localeOf(context).toString();
    final months = List.generate(12, (i) {
      final monthNumber = i + 1;
      final name = DateFormat.MMMM(
        locale,
      ).format(DateTime(2000, monthNumber, 1));
      return {'value': monthNumber, 'name': name};
    });
    final days = List.generate(31, (i) => i + 1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cake_outlined,
                color: Color(0xFF23C3AE),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                context.loc.t('birthDate'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Day dropdown
              Expanded(
                flex: 2,
                child: _DropdownField(
                  label: context.loc.t('day'),
                  value: selectedDay,
                  items: days,
                  enabled: enabled,
                  onChanged: onDayChanged,
                  itemBuilder: (day) => '$day',
                ),
              ),
              const SizedBox(width: 12),
              // Month dropdown
              Expanded(
                flex: 3,
                child: _DropdownField<int>(
                  label: context.loc.t('month'),
                  value: selectedMonth,
                  items: months.map((m) => m['value'] as int).toList(),
                  enabled: enabled,
                  onChanged: onMonthChanged,
                  itemBuilder: (monthValue) {
                    final monthName =
                        months.firstWhere(
                              (m) => m['value'] == monthValue,
                              orElse: () => {'name': '$monthValue'},
                            )['name']
                            as String;
                    return monthName;
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Year dropdown
              Expanded(
                flex: 2,
                child: _DropdownField(
                  label: context.loc.t('year'),
                  value: selectedYear,
                  items: years,
                  enabled: enabled,
                  onChanged: onYearChanged,
                  itemBuilder: (year) => '$year',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final bool enabled;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemBuilder;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.enabled,
    required this.onChanged,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text(
                label,
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemBuilder(item),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: enabled ? onChanged : null,
              icon: Icon(
                Icons.arrow_drop_down,
                color: enabled ? Colors.grey[700] : Colors.grey[400],
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              menuMaxHeight: 300,
              style: TextStyle(color: Colors.grey[800], fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  const _Blob({
    required this.color,
    required this.size,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final blob = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.35),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
    );

    if (top != null || left != null || right != null || bottom != null) {
      return Positioned(
        top: top,
        left: left,
        right: right,
        bottom: bottom,
        child: blob,
      );
    }

    return blob;
  }
}
