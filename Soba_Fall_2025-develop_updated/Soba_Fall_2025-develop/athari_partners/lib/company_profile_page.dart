import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'auth_config.dart';
import 'services/company_membership_service.dart';
import 'services/company_profile_service.dart';
import 'services/company_role.dart';
import 'services/plan_progress_service.dart';
import 'utils/currency_input.dart';

class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({
    super.key,
    this.embedded = false,
    this.onSaveAndContinue,
  });

  final bool embedded;
  final Future<void> Function()? onSaveAndContinue;

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _companyName = TextEditingController();
  final _industry = TextEditingController();
  final _website = TextEditingController();
  final _description = TextEditingController();
  final _addressLine1 = TextEditingController();
  final _addressLine2 = TextEditingController();
  final _city = TextEditingController();
  final _stateRegion = TextEditingController();
  final _postalCode = TextEditingController();
  final _country = TextEditingController();
  final _financialPeriod = TextEditingController();
  final _financialRevenue = TextEditingController();
  final _financialGrossMarginDollar = TextEditingController();
  final _financialGrossMarginPct = TextEditingController();
  final _financialEbitdaDollar = TextEditingController();
  final _financialEbitdaPct = TextEditingController();
  final _financialCashBalance = TextEditingController();

  String? _companyId;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingLogo = false;
  String? _loadError;
  String _companySize = '';
  String _fiscalYearEnd = '';
  String _logoUrl = '';
  Uint8List? _pendingLogoBytes;
  String? _pendingLogoFileName;
  bool _removeLogo = false;
  final List<_ManagementMemberEntry> _managementTeam = [];
  String? _companyRole;
  String _inviteCode = '';
  List<CompanyMember> _members = const [];

  bool get _isOwner => CompanyRole.isOwner(_companyRole);

  @override
  void dispose() {
    _companyName.dispose();
    _industry.dispose();
    _website.dispose();
    _description.dispose();
    _addressLine1.dispose();
    _addressLine2.dispose();
    _city.dispose();
    _stateRegion.dispose();
    _postalCode.dispose();
    _country.dispose();
    _financialPeriod.dispose();
    _financialRevenue.dispose();
    _financialGrossMarginDollar.dispose();
    _financialGrossMarginPct.dispose();
    _financialEbitdaDollar.dispose();
    _financialEbitdaPct.dispose();
    _financialCashBalance.dispose();
    _disposeManagementTeam();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _bind(CompanyProfileData data) {
    _companyName.text = data.companyName;
    _industry.text = data.industry;
    _website.text = data.website;
    _description.text = data.description;
    _addressLine1.text = data.addressLine1;
    _addressLine2.text = data.addressLine2;
    _city.text = data.city;
    _stateRegion.text = data.stateRegion;
    _postalCode.text = data.postalCode;
    _country.text = data.country;
    _companySize = data.companySize;
    _fiscalYearEnd = data.fiscalYearEnd;
    _logoUrl = data.logoUrl;
    _pendingLogoBytes = data.logoBytes;
    _pendingLogoFileName = data.logoBytes != null ? 'logo.png' : null;
    _removeLogo = false;
    _bindFinancials(data.recentFinancials);
    _bindManagementTeam(data.managementTeam);
  }

  void _disposeManagementTeam() {
    for (final entry in _managementTeam) {
      entry.dispose();
    }
    _managementTeam.clear();
  }

  void _bindManagementTeam(List<ManagementTeamMember> members) {
    _disposeManagementTeam();
    if (members.isEmpty) {
      _managementTeam.add(_ManagementMemberEntry.empty());
      return;
    }
    for (final member in members) {
      _managementTeam.add(_ManagementMemberEntry.fromMember(member));
    }
  }

  List<ManagementTeamMember> _readManagementTeam() {
    return _managementTeam
        .map(
          (entry) => ManagementTeamMember(
            title: entry.title,
            fullName: entry.nameController.text.trim(),
            email: entry.emailController.text.trim(),
          ),
        )
        .where(
          (m) =>
              m.title.isNotEmpty ||
              m.fullName.isNotEmpty ||
              m.email.isNotEmpty,
        )
        .toList();
  }

  void _addManagementMember() {
    setState(() => _managementTeam.add(_ManagementMemberEntry.empty()));
  }

  void _removeManagementMember(int index) {
    if (_managementTeam.length <= 1) {
      setState(() {
        _managementTeam[index].nameController.clear();
        _managementTeam[index].emailController.clear();
        _managementTeam[index].title = '';
      });
      return;
    }
    setState(() {
      _managementTeam[index].dispose();
      _managementTeam.removeAt(index);
    });
  }

  String? _emailValidator(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return null;
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return valid ? null : 'Enter a valid email address';
  }

  void _bindFinancials(CompanyRecentFinancials financials) {
    String currencyDisplay(String raw) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return '';
      return formatCurrencyText(trimmed);
    }

    _financialPeriod.text = financials.periodLabel;
    _financialRevenue.text = currencyDisplay(financials.revenue);
    _financialGrossMarginDollar.text = currencyDisplay(financials.grossMarginDollar);
    _financialGrossMarginPct.text = financials.grossMarginPct;
    _financialEbitdaDollar.text = currencyDisplay(financials.ebitdaDollar);
    _financialEbitdaPct.text = financials.ebitdaPct;
    _financialCashBalance.text = currencyDisplay(financials.cashBalance);
  }

  CompanyRecentFinancials _readFinancials() {
    return CompanyRecentFinancials(
      periodLabel: _financialPeriod.text.trim(),
      revenue: _financialRevenue.text.trim(),
      grossMarginDollar: _financialGrossMarginDollar.text.trim(),
      grossMarginPct: _financialGrossMarginPct.text.trim(),
      ebitdaDollar: _financialEbitdaDollar.text.trim(),
      ebitdaPct: _financialEbitdaPct.text.trim(),
      cashBalance: _financialCashBalance.text.trim(),
    );
  }

  CompanyProfileData _readForm() {
    return CompanyProfileData(
      companyName: _companyName.text.trim(),
      logoUrl: _logoUrl,
      industry: _industry.text.trim(),
      website: _website.text.trim(),
      companySize: _companySize,
      fiscalYearEnd: _fiscalYearEnd,
      description: _description.text.trim(),
      addressLine1: _addressLine1.text.trim(),
      addressLine2: _addressLine2.text.trim(),
      city: _city.text.trim(),
      stateRegion: _stateRegion.text.trim(),
      postalCode: _postalCode.text.trim(),
      country: _country.text.trim(),
      recentFinancials: _readFinancials(),
      managementTeam: _readManagementTeam(),
      logoBytes: _pendingLogoBytes,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      _companyId = await loadCompanyIdForCurrentUser();
      final data = await CompanyProfileService.load(_companyId);
      final role = await CompanyMembershipService.loadCompanyRoleForCurrentUser();
      final members = await CompanyMembershipService.listMembers(_companyId);
      var inviteCode = '';
      if (CompanyRole.isOwner(role) && _companyId != null && _companyId!.isNotEmpty) {
        inviteCode = await CompanyMembershipService.getOrCreateInviteCode(_companyId!);
      }
      if (mounted) {
        setState(() {
          _bind(data);
          _companyRole = role;
          _members = members;
          _inviteCode = inviteCode;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickLogo() async {
    setState(() => _uploadingLogo = true);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 88,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pendingLogoBytes = bytes;
        _pendingLogoFileName = file.name;
        _removeLogo = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  void _clearLogo() {
    setState(() {
      _pendingLogoBytes = null;
      _pendingLogoFileName = null;
      _logoUrl = '';
      _removeLogo = true;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await CompanyProfileService.save(
        companyId: _companyId,
        profile: _readForm(),
        pendingLogoBytes: _pendingLogoBytes,
        pendingLogoFileName: _pendingLogoFileName,
        removeLogo: _removeLogo,
      );
      if (!mounted) return;
      if (!skipFirebasePersistence && _companyId != null) {
        await PlanProgressService.cacheProgress(_companyId!);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company profile saved'),
          backgroundColor: Color(0xFF15803D),
        ),
      );
      if (widget.embedded) {
        await widget.onSaveAndContinue?.call();
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save profile: $e'),
            backgroundColor: const Color(0xFFB45309),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _req(String? v, String label) {
    if ((v ?? '').trim().isEmpty) return '$label is required';
    return null;
  }

  Widget _labeled(String label, Widget field, {bool mandatory = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mandatory ? '$label *' : label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  Widget _logoPreview() {
    final hasPending = _pendingLogoBytes != null && !_removeLogo;
    final hasRemote = _logoUrl.trim().isNotEmpty && !_removeLogo;

    Widget image;
    if (hasPending) {
      image = Image.memory(
        _pendingLogoBytes!,
        fit: BoxFit.cover,
        width: 96,
        height: 96,
      );
    } else if (hasRemote) {
      image = Image.network(
        _logoUrl,
        fit: BoxFit.cover,
        width: 96,
        height: 96,
        errorBuilder: (_, __, ___) => _logoPlaceholder(),
      );
    } else {
      image = _logoPlaceholder();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.grey.shade100,
            ),
            child: image,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Company logo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'PNG or JPG, square works best. Shown on your strategic plan and exports.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _uploadingLogo ? null : _pickLogo,
                    icon: _uploadingLogo
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_outlined, size: 18),
                    label: const Text('Upload logo'),
                  ),
                  if (hasPending || hasRemote)
                    TextButton(
                      onPressed: _clearLogo,
                      child: const Text('Remove'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _logoPlaceholder() {
    return Center(
      child: Icon(Icons.business_outlined, size: 40, color: Colors.grey.shade500),
    );
  }

  Widget _financialField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool currency = false,
    bool percent = false,
  }) {
    return _labeled(
      label,
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          if (currency) CurrencyInputFormatter(),
          if (percent) PercentInputFormatter(),
        ],
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: hint,
          suffixText: percent ? '%' : null,
        ),
      ),
      mandatory: false,
    );
  }

  Widget _financialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Company Financials',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter your most recent key financial metrics (latest fiscal year, TTM, or YTD).',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        _labeled(
          'Reporting period',
          TextFormField(
            controller: _financialPeriod,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'e.g. FY 2024, TTM, YTD',
            ),
          ),
          mandatory: false,
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _financialField(
                label: 'Revenue \$',
                controller: _financialRevenue,
                hint: '0.00',
                currency: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _financialField(
                label: 'EBITDA \$',
                controller: _financialEbitdaDollar,
                hint: '0.00',
                currency: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _financialField(
                label: 'Gross margin \$',
                controller: _financialGrossMarginDollar,
                hint: '0.00',
                currency: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _financialField(
                label: 'Gross margin %',
                controller: _financialGrossMarginPct,
                hint: '0.00',
                percent: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _financialField(
                label: 'EBITDA margin %',
                controller: _financialEbitdaPct,
                hint: '0.00',
                percent: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _financialField(
                label: 'Cash on hand \$',
                controller: _financialCashBalance,
                hint: '0.00',
                currency: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _managementTeamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Management Team',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add leadership contacts with title, full name, and email.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _addManagementMember,
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Add member'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _managementTeam.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Team member ${i + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    if (_managementTeam.length > 1)
                      IconButton(
                        tooltip: 'Remove member',
                        onPressed: () => _removeManagementMember(i),
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.grey.shade700,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _labeled(
                  'Title',
                  DropdownButtonFormField<String>(
                    key: ValueKey('mgmt-title-$i-${_managementTeam[i].title}'),
                    initialValue: _managementTeam[i].title.isEmpty
                        ? null
                        : _managementTeam[i].title,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select title',
                    ),
                    items: CompanyProfileService.managementTitleOptions
                        .map(
                          (title) => DropdownMenuItem(
                            value: title,
                            child: Text(title),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _managementTeam[i].title = value ?? '');
                    },
                  ),
                  mandatory: false,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _labeled(
                        'Full name',
                        TextFormField(
                          controller: _managementTeam[i].nameController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Jane Doe',
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        mandatory: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _labeled(
                        'Email address',
                        TextFormField(
                          controller: _managementTeam[i].emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'name@company.com',
                          ),
                          validator: _emailValidator,
                        ),
                        mandatory: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _collaborationSection() {
    final roleLabel = CompanyRole.label(_companyRole);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Team & access',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            Chip(
              label: Text(roleLabel),
              backgroundColor: _isOwner
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFEFF6FF),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _isOwner
                    ? const Color(0xFF166534)
                    : const Color(0xFF1D4ED8),
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _isOwner
              ? 'You are the primary owner. Share the invite code so teammates can '
                  'join and collaborate on the strategic plan.'
              : 'You are connected as a collaborator. You can edit plan content; '
                  'only the primary owner can approve each roadmap step.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.45),
        ),
        if (_isOwner && _inviteCode.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collaborator invite code',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _inviteCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy invite code',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invite code copied')),
                        );
                      },
                      icon: const Icon(Icons.copy_outlined),
                    ),
                  ],
                ),
                Text(
                  'Teammates enter this code when creating an account to join your company.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
        if (_members.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Connected users',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          ..._members.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                tileColor: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                leading: CircleAvatar(
                  backgroundColor: member.role == CompanyRole.owner
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFEFF6FF),
                  child: Icon(
                    member.role == CompanyRole.owner
                        ? Icons.verified_user_outlined
                        : Icons.person_outline,
                    size: 20,
                    color: member.role == CompanyRole.owner
                        ? const Color(0xFF166534)
                        : const Color(0xFF1D4ED8),
                  ),
                ),
                title: Text(
                  member.displayName.isNotEmpty
                      ? member.displayName
                      : member.email,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  [
                    if (member.email.isNotEmpty &&
                        member.displayName.isNotEmpty)
                      member.email,
                    CompanyRole.label(member.role),
                  ].join(' · '),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFormCard() {
    const blue = Color(0xFF2563EB);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  widget.embedded
                      ? 'Step 0 — set your organization foundation. Your company name and logo '
                          'appear on strategic plan outputs; other fields help tailor planning context.'
                      : 'Set your organization details once. Your company name and logo '
                          'appear on strategic plan outputs; other fields help tailor '
                          'planning context.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _logoPreview(),
              const SizedBox(height: 20),
              _labeled(
                'Company name',
                TextFormField(
                  controller: _companyName,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Organization legal or trade name',
                  ),
                  validator: (v) => _req(v, 'Company name'),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _labeled(
                      'Industry',
                      TextFormField(
                        controller: _industry,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'e.g. SaaS, Manufacturing',
                        ),
                      ),
                      mandatory: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _labeled(
                      'Website',
                      TextFormField(
                        controller: _website,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'https://…',
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      mandatory: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _labeled(
                      'Company size',
                      DropdownButtonFormField<String>(
                        key: ValueKey(_companySize),
                        initialValue:
                            _companySize.isEmpty ? null : _companySize,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select size',
                        ),
                        items: CompanyProfileService.companySizeOptions
                            .map(
                              (o) => DropdownMenuItem(
                                value: o,
                                child: Text(o),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _companySize = v ?? ''),
                      ),
                      mandatory: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _labeled(
                      'Fiscal year end',
                      DropdownButtonFormField<String>(
                        key: ValueKey(_fiscalYearEnd),
                        initialValue: _fiscalYearEnd.isEmpty
                            ? null
                            : _fiscalYearEnd,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Month',
                        ),
                        items: CompanyProfileService.fiscalYearEndOptions
                            .map(
                              (o) => DropdownMenuItem(
                                value: o,
                                child: Text(o),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _fiscalYearEnd = v ?? ''),
                      ),
                      mandatory: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _labeled(
                'Company description',
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Brief overview of what your company does',
                  ),
                ),
                mandatory: false,
              ),
              const SizedBox(height: 20),
              _financialsSection(),
              const SizedBox(height: 20),
              _managementTeamSection(),
              const SizedBox(height: 20),
              Text(
                'Headquarters',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              _labeled(
                'Street address',
                TextFormField(
                  controller: _addressLine1,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '123 Main Street',
                  ),
                ),
                mandatory: false,
              ),
              const SizedBox(height: 14),
              _labeled(
                'Suite / unit (optional)',
                TextFormField(
                  controller: _addressLine2,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Suite 400',
                  ),
                ),
                mandatory: false,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _labeled(
                      'City',
                      TextFormField(
                        controller: _city,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                      mandatory: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _labeled(
                      'State / region',
                      TextFormField(
                        controller: _stateRegion,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'TX',
                        ),
                      ),
                      mandatory: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _labeled(
                      'Postal code',
                      TextFormField(
                        controller: _postalCode,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                      mandatory: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _labeled(
                      'Country',
                      TextFormField(
                        controller: _country,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'United States',
                        ),
                      ),
                      mandatory: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _collaborationSection(),
              const SizedBox(height: 22),
              Row(
                children: [
                  if (!widget.embedded)
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.embedded
                                ? (_isOwner ? 'Save & Continue' : 'Save draft')
                                : 'Save profile',
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      if (widget.embedded) {
        return const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      final errorBody = Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
      if (widget.embedded) return errorBody;
      return Scaffold(
        appBar: AppBar(title: const Text('Company Profile')),
        body: Center(child: errorBody),
      );
    }

    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: _buildFormCard(),
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Company Profile'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: content,
        ),
      ),
    );
  }
}

class _ManagementMemberEntry {
  _ManagementMemberEntry({
    required this.title,
    required this.nameController,
    required this.emailController,
  });

  String title;
  final TextEditingController nameController;
  final TextEditingController emailController;

  factory _ManagementMemberEntry.empty() {
    return _ManagementMemberEntry(
      title: '',
      nameController: TextEditingController(),
      emailController: TextEditingController(),
    );
  }

  factory _ManagementMemberEntry.fromMember(ManagementTeamMember member) {
    return _ManagementMemberEntry(
      title: member.title,
      nameController: TextEditingController(text: member.fullName),
      emailController: TextEditingController(text: member.email),
    );
  }

  void dispose() {
    nameController.dispose();
    emailController.dispose();
  }
}
