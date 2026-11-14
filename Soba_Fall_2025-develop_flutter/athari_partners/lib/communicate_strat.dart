import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunicateStrategyPage extends StatefulWidget {
  final VoidCallback onSaveAndContinue;

  const CommunicateStrategyPage({super.key, required this.onSaveAndContinue});

  @override
  State<CommunicateStrategyPage> createState() =>
      _CommunicateStrategyPageState();
}

class _CommunicateStrategyPageState extends State<CommunicateStrategyPage> {
  String? companyId;

  // Table controllers
  final List<List<TextEditingController>> _tableControllers = List.generate(
    4,
    (_) => List.generate(5, (_) => TextEditingController()),
  );

  // Frequency options for dropdown
  final List<String> _frequencyOptions = [
    'Weekly',
    'Biweekly',
    'Monthly',
    'Quarterly',
    'As needed',
  ];

  // Selected frequencies
  final List<String?> _selectedFrequency = List.generate(4, (_) => null);

  bool _listenersAdded = false;

  @override
  void initState() {
    super.initState();
    _loadCompanyId();
  }

  @override
  void dispose() {
    for (var row in _tableControllers) {
      for (var c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _loadCompanyId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (userSnap.exists && userSnap.data() != null) {
      setState(() {
        companyId = userSnap['companyId'];
      });
      await _loadData();
    }
  }

  Future<void> _loadData() async {
    if (companyId == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('executeAndMonitor')
        .doc('communicateStrategy');

    final docSnap = await docRef.get();
    if (docSnap.exists && docSnap.data() != null) {
      final data = docSnap.data()!;
      for (int i = 0; i < 4; i++) {
        _tableControllers[i][1].text = data['row${i}_keyMessages'] ?? '';
        _tableControllers[i][2].text = data['row${i}_channels'] ?? '';
        _selectedFrequency[i] = data['row${i}_frequency'];
        _tableControllers[i][4].text = data['row${i}_owner'] ?? '';
      }
      setState(() {});
    }

    // Add listeners AFTER loading to avoid overwriting database with blanks.
    _addAutoUpdateListeners();
  }

  // AUTO UPDATE IMPLEMENTATION
  void _addAutoUpdateListeners() {
    if (_listenersAdded) return;
    _listenersAdded = true;

    for (int i = 0; i < 4; i++) {
      _tableControllers[i][1].addListener(() {
        _autoSaveField(i, "keyMessages", _tableControllers[i][1].text);
      });

      _tableControllers[i][2].addListener(() {
        _autoSaveField(i, "channels", _tableControllers[i][2].text);
      });

      _tableControllers[i][4].addListener(() {
        _autoSaveField(i, "owner", _tableControllers[i][4].text);
      });
    }
  }

  Future<void> _autoSaveField(int row, String field, String value) async {
    if (companyId == null) return;

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('executeAndMonitor')
        .doc('communicateStrategy')
        .set({"row${row}_${field}": value}, SetOptions(merge: true));
  }

  Future<void> _autoSaveDropdown(int row, String? value) async {
    if (companyId == null) return;

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('executeAndMonitor')
        .doc('communicateStrategy')
        .set({"row${row}_frequency": value}, SetOptions(merge: true));
  }

  // Manual save still exists (you asked only for auto-update, not removal of this)
  Future<void> _saveData() async {
    if (companyId == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('executeAndMonitor')
        .doc('communicateStrategy');

    final data = <String, dynamic>{};

    for (int i = 0; i < 4; i++) {
      data['row${i}_keyMessages'] = _tableControllers[i][1].text;
      data['row${i}_channels'] = _tableControllers[i][2].text;
      data['row${i}_frequency'] = _selectedFrequency[i];
      data['row${i}_owner'] = _tableControllers[i][4].text;
    }

    await docRef.set(data, SetOptions(merge: true));
  }

  Widget _infoBanner(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Text(text, style: TextStyle(color: Colors.blue.shade900)),
    );
  }

  Widget _communicationTable(BuildContext context) {
    final headerStyle = TextStyle(
      fontWeight: FontWeight.w700,
      color: Colors.grey.shade700,
    );

    final placeholders = [
      [
        'Leadership Team',
        'Complete strategic plan, KPIs, targets, responsibilities',
        'Strategy sessions, executive dashboard',
        'Weekly',
        'CEO',
      ],
      [
        'All Employees',
        'Vision, mission, values, key focus areas',
        'Town halls, intranet, team meetings',
        'Quarterly',
        'CEO/Department Heads',
      ],
      [
        'Board/Investors',
        'Strategic plan, financial targets, progress updates',
        'Board meetings, investor reports',
        'Quarterly',
        'CEO/CFO',
      ],
      [
        'Key Customers/Partners',
        'Relevant initiatives, value proposition',
        'Meetings, newsletter, website',
        'As needed',
        'Sales/Marketing',
      ],
    ];

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(160),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(2.5),
            3: FixedColumnWidth(110),
            4: FixedColumnWidth(120),
          },
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade200),
          ),
          children: [
            // HEADER ROW
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade50),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('AUDIENCE', style: headerStyle),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('KEY MESSAGES', style: headerStyle),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('COMMUNICATION CHANNELS', style: headerStyle),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('FREQUENCY', style: headerStyle),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('OWNER', style: headerStyle),
                ),
              ],
            ),

            // BODY ROWS
            for (int i = 0; i < placeholders.length; i++)
              TableRow(
                children: [
                  // FIXED AUDIENCE (non-interactable)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(placeholders[i][0]),
                  ),

                  // KEY MESSAGES (auto update)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _tableControllers[i][1],
                      decoration: InputDecoration(
                        hintText: placeholders[i][1],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                      maxLines: 2,
                    ),
                  ),

                  // CHANNELS (auto update)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _tableControllers[i][2],
                      decoration: InputDecoration(
                        hintText: placeholders[i][2],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                      maxLines: 2,
                    ),
                  ),

                  // FREQUENCY DROPDOWN (auto update)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedFrequency[i],
                      items: _frequencyOptions
                          .map(
                            (freq) => DropdownMenuItem(
                              value: freq,
                              child: Text(
                                freq,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFrequency[i] = value;
                        });
                        _autoSaveDropdown(i, value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Select',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ),

                  // OWNER (auto update)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _tableControllers[i][4],
                      decoration: InputDecoration(
                        hintText: placeholders[i][4],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
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

  Widget _toolkitCard(
    BuildContext context,
    int index,
    String title,
    String body,
  ) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade50,
              child: Text(
                '$index',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(body, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {},
              child: const Text('Download Template'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Communicate Strategy',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _infoBanner(
            context,
            'Effective communication is critical for successful strategy implementation. Plan how you\'ll share your strategic plan with different stakeholders.',
          ),
          const SizedBox(height: 6),
          const Text(
            'Communication Plan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _communicationTable(context),
          const SizedBox(height: 20),
          const Text(
            'Communication Toolkit',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _toolkitCard(
                    context,
                    1,
                    'Executive Summary',
                    'A concise 1–2 page document outlining the strategic plan for leadership and board members.',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _toolkitCard(
                    context,
                    2,
                    'Presentation Deck',
                    'A slide deck for presenting the strategic plan to various stakeholders.',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _toolkitCard(
                    context,
                    3,
                    'Employee Brief',
                    'A simplified version of the strategic plan for all employees.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              OutlinedButton(onPressed: () {}, child: const Text('Back')),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  await _saveData();
                  widget.onSaveAndContinue();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B7BEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save & Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              // ElevatedButton(
              // onPressed: () async {
              //   await _saveData();
              //   widget.onSaveAndContinue();
              // },
              //   child: const Text('Save & Continue'),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
