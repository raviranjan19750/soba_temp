import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();

  // controllers
  final companyName = TextEditingController();
  final locationCtrl = TextEditingController();
  final employeesCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final customersCtrl = TextEditingController();
  final productCtrl = TextEditingController();
  final valuePropCtrl = TextEditingController();
  final divisionsCtrl = TextEditingController();
  final revenueCtrl = TextEditingController();
  final marginCtrl = TextEditingController();
  final incomeCtrl = TextEditingController();
  final ebitdaCtrl = TextEditingController();

  String? industry;

  @override
  void dispose() {
    companyName.dispose();
    locationCtrl.dispose();
    employeesCtrl.dispose();
    descriptionCtrl.dispose();
    customersCtrl.dispose();
    productCtrl.dispose();
    valuePropCtrl.dispose();
    divisionsCtrl.dispose();
    revenueCtrl.dispose();
    marginCtrl.dispose();
    incomeCtrl.dispose();
    ebitdaCtrl.dispose();
    super.dispose();
  }

  // ---------- UI helpers ----------
  Widget _sp(double h) => SizedBox(height: h);
  TextStyle get _h1 => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );
  TextStyle get _muted =>
      const TextStyle(fontSize: 16, color: Color(0xFF6B7280));
  TextStyle get _labelStyle => const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: Color(0xFF374151),
  );

  // Company logo (ensure pubspec.yaml has: assets: - assets/logos/athari_logo.png)
  Widget _logo() => Image.asset(
    'assets/logos/athari_logo.png', // <-- put your logo file here
    height: 60,
    fit: BoxFit.contain,
    errorBuilder: (_, __, ___) =>
        const Icon(Icons.apartment, size: 80, color: Color(0xFF2563EB)),
  );

  Widget _stepHeader() {
    Widget pill(int n, String label, {bool active = false}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF2563EB) : Colors.white,
              border: Border.all(
                color: active
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE5E7EB),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$n',
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: active ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      );
    }

    Widget line() => Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );

    return Row(
      children: [
        pill(1, 'Company Profile', active: true),
        line(),
        pill(2, 'Team Members'),
        line(),
        pill(3, 'Getting Started'),
      ],
    );
  }

  // Input decoration WITHOUT internal label (we show bold label above)
  InputDecoration _decNoLabel({String? hint, Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix == null
          ? null
          : Padding(padding: const EdgeInsets.only(left: 8), child: prefix),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    );
  }

  Widget _twoCol(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= 900;
        if (isWide) {
          return Row(
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right),
            ],
          );
        }
        return Column(children: [left, const SizedBox(height: 16), right]);
      },
    );
  }

  // Bold label ABOVE the field
  Widget LabeledField({required String label, required Widget field}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with logo on top-left
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _logo(),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome to Athari Partners', style: _h1),
                          _sp(6),
                          Text(
                            "Let's set up your account and get you started",
                            style: _muted,
                          ),
                        ],
                      ),
                    ],
                  ),

                  _sp(24),
                  _stepHeader(),
                  _sp(18),

                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Set Up Company Profile',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            _sp(18),

                            // Company + Location
                            _twoCol(
                              LabeledField(
                                label: 'Company Name *',
                                field: TextFormField(
                                  controller: companyName,
                                  decoration: _decNoLabel(),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                              LabeledField(
                                label: 'Location *',
                                field: TextFormField(
                                  controller: locationCtrl,
                                  decoration: _decNoLabel(
                                    hint: 'City, Country',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                            ),
                            _sp(14),

                            // Industry + Employees
                            _twoCol(
                              LabeledField(
                                label: 'Industry *',
                                field: DropdownButtonFormField<String>(
                                  value: industry,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Technology',
                                      child: Text('Technology'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Finance',
                                      child: Text('Finance'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Healthcare',
                                      child: Text('Healthcare'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Manufacturing',
                                      child: Text('Manufacturing'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Retail',
                                      child: Text('Retail'),
                                    ),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => industry = v),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Required'
                                      : null,
                                  decoration: _decNoLabel(
                                    hint: 'Select industry',
                                  ),
                                ),
                              ),
                              LabeledField(
                                label: 'Number of Employees *',
                                field: TextFormField(
                                  controller: employeesCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _decNoLabel(),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                            ),
                            _sp(14),

                            // Description
                            LabeledField(
                              label: 'Description of Business *',
                              field: TextFormField(
                                controller: descriptionCtrl,
                                maxLines: 3,
                                decoration: _decNoLabel(
                                  hint: 'Describe what your company does...',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            _sp(14),

                            // Customers + Product/Service
                            _twoCol(
                              LabeledField(
                                label: 'Customers *',
                                field: TextFormField(
                                  controller: customersCtrl,
                                  decoration: _decNoLabel(
                                    hint: 'Who are your primary customers?',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                              LabeledField(
                                label: 'Product/Service *',
                                field: TextFormField(
                                  controller: productCtrl,
                                  decoration: _decNoLabel(
                                    hint: 'Main products or services',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                            ),
                            _sp(14),

                            // Value prop
                            LabeledField(
                              label: 'Value Proposition *',
                              field: TextFormField(
                                controller: valuePropCtrl,
                                maxLines: 2,
                                decoration: _decNoLabel(
                                  hint:
                                      'What unique value do you provide to customers?',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            _sp(14),

                            // Divisions + Annual Revenue
                            _twoCol(
                              LabeledField(
                                label: 'Divisions',
                                field: TextFormField(
                                  controller: divisionsCtrl,
                                  decoration: _decNoLabel(
                                    hint: 'Separate with commas',
                                  ),
                                ),
                              ),
                              LabeledField(
                                label: 'Annual Revenue *',
                                field: TextFormField(
                                  controller: revenueCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _decNoLabel(
                                    prefix: const Padding(
                                      padding: EdgeInsets.only(
                                        left: 8,
                                        right: 6,
                                      ),
                                      child: Text('\$'),
                                    ),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                            ),
                            _sp(14),

                            // Gross Margin + Net Income
                            _twoCol(
                              LabeledField(
                                label: 'Gross Margin',
                                field: TextFormField(
                                  controller: marginCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _decNoLabel(
                                    prefix: const Padding(
                                      padding: EdgeInsets.only(
                                        left: 8,
                                        right: 6,
                                      ),
                                      child: Text('%'),
                                    ),
                                  ),
                                ),
                              ),
                              LabeledField(
                                label: 'Net Income',
                                field: TextFormField(
                                  controller: incomeCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _decNoLabel(
                                    prefix: const Padding(
                                      padding: EdgeInsets.only(
                                        left: 8,
                                        right: 6,
                                      ),
                                      child: Text('\$'),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _sp(14),

                            // EBITDA
                            LabeledField(
                              label: 'EBITDA',
                              field: TextFormField(
                                controller: ebitdaCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _decNoLabel(
                                  prefix: const Padding(
                                    padding: EdgeInsets.only(left: 8, right: 6),
                                    child: Text('\$'),
                                  ),
                                ),
                              ),
                            ),
                            _sp(18),

                            // Upload box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 26),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFD1D5DB),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.file_upload_outlined,
                                    size: 32,
                                    color: Color(0xFF6B7280),
                                  ),
                                  SizedBox(height: 8),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Upload financial documents',
                                          style: TextStyle(
                                            color: Color(0xFF2563EB),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' or drag and drop',
                                          style: TextStyle(
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'PDF, Excel, or CSV up to 10MB',
                                    style: TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _sp(22),

                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: () {
                                  final ok =
                                      _formKey.currentState?.validate() ??
                                      false;
                                  if (ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Company Profile saved. Proceeding to Team Members…',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Next'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
