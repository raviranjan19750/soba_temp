import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Collects account + company details before the user enters Catalyst Planning.
///
/// On **Save and continue**, all fields are written to `users/{uid}` (top-level
/// copies for convenience plus nested `accountProfile` as the full snapshot)
/// and the same organization fields are merged onto `companies/{companyId}` so
/// workspace data stays aligned.
class AccountProfilePage extends StatefulWidget {
  const AccountProfilePage({
    super.key,
    required this.user,
    required this.onCompleted,
  });

  final User user;
  final VoidCallback onCompleted;

  @override
  State<AccountProfilePage> createState() => _AccountProfilePageState();
}

class _AccountProfilePageState extends State<AccountProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _jobTitle = TextEditingController();
  final _companyName = TextEditingController();
  final _addressLine1 = TextEditingController();
  final _addressLine2 = TextEditingController();
  final _city = TextEditingController();
  final _stateRegion = TextEditingController();
  final _postalCode = TextEditingController();
  final _country = TextEditingController();
  final _phone = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _jobTitle.dispose();
    _companyName.dispose();
    _addressLine1.dispose();
    _addressLine2.dispose();
    _city.dispose();
    _stateRegion.dispose();
    _postalCode.dispose();
    _country.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  void _applyPersonalFromMap(Map<String, dynamic> m) {
    _firstName.text = (m['firstName'] as String?)?.trim() ?? '';
    _lastName.text = (m['lastName'] as String?)?.trim() ?? '';
    if (_firstName.text.isEmpty && _lastName.text.isEmpty) {
      final dn = (m['displayName'] as String?)?.trim() ?? '';
      if (dn.isNotEmpty) {
        final parts = dn.split(RegExp(r'\s+'));
        _firstName.text = parts.first;
        if (parts.length > 1) {
          _lastName.text = parts.sublist(1).join(' ');
        }
      }
    }
    _jobTitle.text = (m['jobTitle'] as String?)?.trim() ?? '';
    _phone.text = (m['phone'] as String?)?.trim() ?? '';
  }

  void _applyOrganizationFromMap(Map<String, dynamic> org) {
    _companyName.text = (org['companyName'] as String?)?.trim() ?? '';
    _addressLine1.text = (org['addressLine1'] as String?)?.trim() ?? '';
    _addressLine2.text = (org['addressLine2'] as String?)?.trim() ?? '';
    _city.text = (org['city'] as String?)?.trim() ?? '';
    _stateRegion.text = (org['stateRegion'] as String?)?.trim() ?? '';
    _postalCode.text = (org['postalCode'] as String?)?.trim() ?? '';
    _country.text = (org['country'] as String?)?.trim() ?? '';
  }

  Future<void> _prefill() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final uid = widget.user.uid;
      final userSnap = await firestore.collection('users').doc(uid).get();
      final u = userSnap.data() ?? {};

      final apRaw = u['accountProfile'];
      final ap = apRaw is Map
          ? Map<String, dynamic>.from(apRaw as Map)
          : null;
      Map<String, dynamic>? orgMap;
      final orgFromProfile = ap?['organization'];
      if (orgFromProfile is Map) {
        orgMap = Map<String, dynamic>.from(orgFromProfile as Map);
      }

      _applyPersonalFromMap(u);
      if (_firstName.text.isEmpty && _lastName.text.isEmpty) {
        final dn = (widget.user.displayName ?? u['displayName'] as String? ?? '')
            .trim();
        if (dn.isNotEmpty) {
          final parts = dn.split(RegExp(r'\s+'));
          _firstName.text = parts.first;
          if (parts.length > 1) {
            _lastName.text = parts.sublist(1).join(' ');
          }
        }
      }
      if (ap != null) {
        void overlay(String key, TextEditingController c) {
          final v = ap[key];
          if (v is String && v.trim().isNotEmpty) c.text = v.trim();
        }

        overlay('firstName', _firstName);
        overlay('lastName', _lastName);
        overlay('jobTitle', _jobTitle);
        overlay('phone', _phone);
        final apDn = (ap['displayName'] as String?)?.trim();
        if (apDn != null &&
            apDn.isNotEmpty &&
            _firstName.text.isEmpty &&
            _lastName.text.isEmpty) {
          final parts = apDn.split(RegExp(r'\s+'));
          _firstName.text = parts.first;
          if (parts.length > 1) {
            _lastName.text = parts.sublist(1).join(' ');
          }
        }
      }

      if (orgMap != null && orgMap.isNotEmpty) {
        _applyOrganizationFromMap(orgMap);
      } else {
        final companyId = u['companyId']?.toString();
        if (companyId != null && companyId.isNotEmpty) {
          final companySnap =
              await firestore.collection('companies').doc(companyId).get();
          final c = companySnap.data() ?? {};
          _applyOrganizationFromMap(Map<String, dynamic>.from(c));
        }
      }

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = e.toString();
        });
      }
    }
  }

  String? _req(String? v, String label) {
    if ((v ?? '').trim().isEmpty) return '$label is required';
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final uid = widget.user.uid;
      final userRef = firestore.collection('users').doc(uid);
      final userSnap = await userRef.get();
      final companyId = userSnap.data()?['companyId']?.toString();
      if (companyId == null || companyId.isEmpty) {
        throw StateError('Missing companyId on user profile.');
      }

      final first = _firstName.text.trim();
      final last = _lastName.text.trim();
      final displayName = '$first $last'.trim();
      final jobTitle = _jobTitle.text.trim();
      final phone = _phone.text.trim();
      final companyName = _companyName.text.trim();
      final addressLine1 = _addressLine1.text.trim();
      final addressLine2 = _addressLine2.text.trim();
      final city = _city.text.trim();
      final stateRegion = _stateRegion.text.trim();
      final postalCode = _postalCode.text.trim();
      final country = _country.text.trim();

      final organization = <String, dynamic>{
        'companyName': companyName,
        'addressLine1': addressLine1,
        'city': city,
        'stateRegion': stateRegion,
        'postalCode': postalCode,
        'country': country,
      };
      if (addressLine2.isNotEmpty) {
        organization['addressLine2'] = addressLine2;
      }

      final email = (widget.user.email ?? userSnap.data()?['email'] as String? ?? '')
          .trim();

      final accountProfile = <String, dynamic>{
        'email': email,
        'firstName': first,
        'lastName': last,
        'displayName': displayName,
        'jobTitle': jobTitle,
        'phone': phone,
        'companyId': companyId,
        'organization': organization,
        'savedAt': FieldValue.serverTimestamp(),
      };

      final batch = firestore.batch();
      batch.set(
        userRef,
        {
          if (email.isNotEmpty) 'email': email,
          'firstName': first,
          'lastName': last,
          'displayName': displayName,
          'jobTitle': jobTitle,
          'phone': phone,
          'accountProfileCompleted': true,
          'accountProfileCompletedAt': FieldValue.serverTimestamp(),
          'accountProfile': accountProfile,
        },
        SetOptions(merge: true),
      );

      final companyRef = firestore.collection('companies').doc(companyId);
      final companyPayload = <String, dynamic>{
        'companyName': companyName,
        'addressLine1': addressLine1,
        'city': city,
        'stateRegion': stateRegion,
        'postalCode': postalCode,
        'country': country,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (addressLine2.isEmpty) {
        companyPayload['addressLine2'] = FieldValue.delete();
      } else {
        companyPayload['addressLine2'] = addressLine2;
      }

      batch.set(
        companyRef,
        companyPayload,
        SetOptions(merge: true),
      );

      await batch.commit();

      if (displayName.isNotEmpty) {
        await widget.user.updateDisplayName(displayName);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved. You can begin your Catalyst plan.'),
          backgroundColor: Color(0xFF15803D),
        ),
      );
      widget.onCompleted();
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

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2563EB);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _loadError = null;
                      _loading = true;
                    });
                    _prefill();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Complete your account profile'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () => FirebaseAuth.instance.signOut(),
            child: const Text('Sign out'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
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
                            border: Border.all(
                              color: const Color(0xFFBFDBFE),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 22,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Why we ask again',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Colors.grey.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Registration captured your name, email, and company. '
                                'Here we collect your role, legal entity name, and business '
                                'address so your workspace, records, and any future billing '
                                'stay aligned. Fields below are pre-filled when we already '
                                'have them from signup.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Complete the fields below, then continue into the Catalyst planning steps.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _labeled(
                                'First name',
                                TextFormField(
                                  controller: _firstName,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Jane',
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) => _req(v, 'First name'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _labeled(
                                'Last name',
                                TextFormField(
                                  controller: _lastName,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Doe',
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) => _req(v, 'Last name'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _labeled(
                          'Job title',
                          TextFormField(
                            controller: _jobTitle,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'e.g. Chief Operating Officer',
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => _req(v, 'Job title'),
                          ),
                        ),
                        const SizedBox(height: 14),
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
                        _labeled(
                          'Street address',
                          TextFormField(
                            controller: _addressLine1,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: '123 Main Street',
                            ),
                            validator: (v) => _req(v, 'Street address'),
                          ),
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
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) => _req(v, 'City'),
                                ),
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
                                  validator: (v) => _req(v, 'State / region'),
                                ),
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
                                  validator: (v) => _req(v, 'Postal code'),
                                ),
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
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) => _req(v, 'Country'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _labeled(
                          'Phone (optional)',
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: '+1 …',
                            ),
                          ),
                          mandatory: false,
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                              : const Text('Save and continue'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
