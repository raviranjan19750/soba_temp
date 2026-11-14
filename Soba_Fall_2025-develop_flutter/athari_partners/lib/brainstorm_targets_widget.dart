import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BrainstormTargetsWidget extends StatefulWidget {
  final Function(List<String>)? onSave;
  final List<String>? initialIdeas;

  const BrainstormTargetsWidget({Key? key, this.onSave, this.initialIdeas})
    : super(key: key);

  @override
  State<BrainstormTargetsWidget> createState() =>
      _BrainstormTargetsWidgetState();
}

class _BrainstormTargetsWidgetState extends State<BrainstormTargetsWidget> {
  final TextEditingController _newIdeaController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late List<String> _ideas;

  @override
  void initState() {
    super.initState();
    // Initialize with provided ideas or defaults
    _ideas =
        widget.initialIdeas ??
        [
          'Expand product line to include enterprise solutions',
          'Develop strategic partnerships with complementary businesses',
          'Increase marketing budget by 25% to reach new market segments',
        ];
    _loadCompanyId();
  }

  String? _companyId;

  Future<void> _loadCompanyId() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        _companyId = userDoc['companyId'];
        await _loadBrainTargets();
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _loadBrainTargets() async {
    if (_companyId == null) {
      return;
    }
    final brainRef = await FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('strategicPlanning')
        .doc('brainstorm_targets');

    final brainSnap = await brainRef.get();

    if (brainSnap.exists && brainSnap.data() != null) {
      final data = brainSnap.data();
      if (data != null) {
        final raw = data['brainstorm_targets'];
        if (raw is List) {
          _ideas = List<String>.from(raw.map((e) => e?.toString() ?? ''));
        }
        setState(() {});
      }
    }
  }

  Future<void> _saveBrainTargets() async {
    if (_companyId == null) {
      return;
    }

    final brainRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('strategicPlanning')
        .doc('brainstorm_targets');

    await brainRef.set({
      'brainstorm_targets': _ideas.toList(),
    }, SetOptions(merge: true));
  }

  Future<void> _addIdeaToFirestore(String idea) async {
    if (_companyId == null) return;
    final brainRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('strategicPlanning')
        .doc('brainstorm_targets');
    await brainRef.set({
      'brainstorm_targets': FieldValue.arrayUnion([idea]),
    }, SetOptions(merge: true));
  }

  Future<void> _removeIdeaFromFirestore(String idea) async {
    if (_companyId == null) return;
    final brainRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId)
        .collection('strategicPlanning')
        .doc('brainstorm_targets');
    await brainRef.set({
      'brainstorm_targets': FieldValue.arrayRemove([idea]),
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _newIdeaController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addIdea() {
    if (_newIdeaController.text.trim().isNotEmpty) {
      setState(() {
        _ideas.add(_newIdeaController.text.trim());
        final added = _newIdeaController.text.trim();
        _newIdeaController.clear();
        // persist immediately using arrayUnion
        _addIdeaToFirestore(added);
      });
    }
  }

  void _removeIdea(int index) {
    final removed = _ideas[index];
    setState(() {
      _ideas.removeAt(index);
    });
    // persist removal
    _removeIdeaFromFirestore(removed);
  }

  void _handleSaveAndContinue() {
    // Save full list as a backup and then call callback
    _saveBrainTargets();
    if (widget.onSave != null) {
      widget.onSave!(_ideas);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Brainstorm: What\'s Needed to Achieve Your Targets',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),

          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD2E3FC), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF4B7BEC),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3C4043),
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text:
                              'This is a facilitated brainstorming session to identify what your business needs to achieve its financial targets. Consider insights from your ',
                        ),
                        TextSpan(
                          text: 'market analysis',
                          style: TextStyle(
                            color: Color(0xFF4B7BEC),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ', '),
                        TextSpan(
                          text: 'competitive landscape',
                          style: TextStyle(
                            color: Color(0xFF4B7BEC),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ', and '),
                        TextSpan(
                          text: 'internal capabilities assessment',
                          style: TextStyle(
                            color: Color(0xFF4B7BEC),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Add new idea input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newIdeaController,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      hintText: 'Add a new idea...',
                      hintStyle: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                    onSubmitted: (_) => _addIdea(),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(4),
                  child: Material(
                    color: const Color(0xFF4B7BEC),
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      onTap: _addIdea,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Ideas list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _ideas.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return IdeaItem(
                idea: _ideas[index],
                onDelete: () => _removeIdea(index),
              );
            },
          ),

          const SizedBox(height: 24),

          // Save & Continue Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _handleSaveAndContinue,
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
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class IdeaItem extends StatelessWidget {
  final String idea;
  final VoidCallback onDelete;

  const IdeaItem({Key? key, required this.idea, required this.onDelete})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              idea,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1A1A1A),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 20, color: Colors.grey.shade500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Example usage
class BrainstormScreen extends StatelessWidget {
  const BrainstormScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrainstormTargetsWidget(
        onSave: (ideas) {
          // Handle save action
          print('Saved ideas: $ideas');
          // Navigate to next screen or save to database
        },
      ),
    );
  }
}
