import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/database_service.dart';

class ActionsPage extends StatefulWidget {
  final String notePath;
  const ActionsPage({Key? key, required this.notePath}) : super(key: key);

  @override
  _ActionsPageState createState() => _ActionsPageState();
}

class _ActionsPageState extends State<ActionsPage> {
  String _summary = '';
  bool _isSummaryExpanded = false;
  bool _isLoading = true;
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadExistingSummary();
  }

  Future<void> _loadExistingSummary() async {
    try {
      final noteData = await _dbService.getNote(path: widget.notePath);
      if (noteData['summary'] != null && noteData['summary'].isNotEmpty) {
        setState(() {
          _summary = noteData['summary'];
          _isSummaryExpanded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading existing summary: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateSummary(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Call the Cloud Function
      final functions = FirebaseFunctions.instance;
      final result = await functions
          .httpsCallable('generateSummary')
          .call({'docPath': widget.notePath});

      // Close loading indicator
      Navigator.of(context).pop();

      // Update the summary in the state
      setState(() {
        _summary = result.data['summary'] ?? '';
        _isSummaryExpanded = true;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Summary generated successfully!')),
      );
    } catch (e) {
      // Close loading indicator if still open
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate summary: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Actions'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Generate Summary Option
            ListTile(
              leading: Icon(Icons.summarize),
              title: Text('Generate Summary'),
              onTap: () => _generateSummary(context),
            ),
            SizedBox(height: 16),
            ExpansionPanelList(
              elevation: 1,
              expandedHeaderPadding: EdgeInsets.zero,
              expansionCallback: (int index, bool isExpanded) {
                setState(() {
                  _isSummaryExpanded = !_isSummaryExpanded;
                });
              },
              children: [
                ExpansionPanel(
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return ListTile(
                      title: Text(
                        'Note Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _summary.isEmpty ? Colors.grey : null,
                        ),
                      ),
                    );
                  },
                  body: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal:0, vertical: 8.0),
                    child: _summary.isEmpty
                        ? Text(
                      'No summary available. Generate one using the button above.',
                      style: TextStyle(color: Colors.grey),
                    )
                        : Markdown(
                      data: _summary,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                    ),
                  ),
                  isExpanded: _isSummaryExpanded && _summary.isNotEmpty,
                  canTapOnHeader: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}