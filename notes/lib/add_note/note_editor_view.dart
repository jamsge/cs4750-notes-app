import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/database_service.dart';
import 'dart:async';
import './note_actions_view.dart';

class NotePage extends StatefulWidget {
  final String notePath;

  const NotePage(this.notePath);

  @override
  _NotePageState createState() => _NotePageState();
}

enum SyncStatus { synced, modified, syncing, error }

class _NotePageState extends State<NotePage> {
  final TextEditingController _controller = TextEditingController();
  bool _isPreview = false;
  bool _isLoading = true;
  String _noteTitle = '';
  String _lastSavedContent = '';
  SyncStatus _syncStatus = SyncStatus.synced;
  Timer? _autoSaveTimer;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadNoteContent();

    // Add listener to detect changes in the text field
    _controller.addListener(_onTextChanged);
  }

  Future<void> _loadNoteContent() async {
    setState(() {
      _isLoading = true;
      _syncStatus = SyncStatus.syncing; // Set to syncing while loading
    });

    try {
      // Get note data using the new getNote function
      final noteData = await _databaseService.getNote(path: widget.notePath);

      setState(() {
        // Set the controller text to the note content
        String content = noteData['content'] ?? '';
        _controller.text = content;
        _lastSavedContent = content;
        // Save the note title for display
        _noteTitle = noteData['name'] ?? 'Untitled Note';
        _syncStatus = SyncStatus.synced; // Set to synced after successful load
      });
    } catch (e) {
      // Handle any errors
      setState(() {
        _syncStatus = SyncStatus.error; // Set to error if loading fails
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading note: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _autoSaveTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use note title or date as appBar title
    final String appBarTitle = _noteTitle.isNotEmpty
        ? _noteTitle
        : DateFormat('MM-dd-yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(child: Text(appBarTitle, overflow: TextOverflow.ellipsis)),
            // Sync status indicator
            _buildSyncStatusIcon(),
            SizedBox(width: 8), // Add some spacing
          ],
        ),
        actions: [
          // Toggle between edit and preview mode
          IconButton(
            icon: Icon(_isPreview ? Icons.edit : Icons.visibility),
            tooltip: _isPreview ? 'Edit' : 'Preview',
            onPressed: () {
              setState(() {
                _isPreview = !_isPreview;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.bolt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ActionsPage(
                  // noteContent: _controller.text,
                  notePath: widget.notePath,
                  // noteTitle: _noteTitle,
                )),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Markdown toolbar at the top of the body
          if (!_isPreview) _buildMarkdownToolbar(),

          // Main content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isPreview
                  ? Markdown(
                data: _controller.text,
                selectable: true,
              )
                  : TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Type your markdown here...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Monitor text changes and schedule auto-save
  void _onTextChanged() {
    // Skip if the content hasn't changed since last save
    if (_controller.text == _lastSavedContent) {
      return;
    }

    // Set the status to modified
    setState(() {
      _syncStatus = SyncStatus.modified;
    });

    // Cancel any previous timer
    _autoSaveTimer?.cancel();

    // Schedule a new save after 1.5 seconds of inactivity
    _autoSaveTimer = Timer(Duration(milliseconds: 1500), () {
      _saveNote();
    });
  }

  // Sync status indicator widget
  Widget _buildSyncStatusIcon() {
    switch (_syncStatus) {
      case SyncStatus.synced:
        return Icon(Icons.check, color: Colors.green, size: 20);
      case SyncStatus.modified:
        return Icon(Icons.edit, color: Colors.orange, size: 20);
      case SyncStatus.syncing:
        return Icon(Icons.sync, color: Colors.yellow, size: 20);
      case SyncStatus.error:
        return Icon(Icons.error_outline, color: Colors.red, size: 20);
    }
  }

  Future<void> _saveNote() async {
    // Don't save if content hasn't changed
    if (_controller.text == _lastSavedContent) {
      return;
    }

    setState(() {
      _syncStatus = SyncStatus.syncing;
    });

    try {
      // Save the current state of the note
      await _databaseService.updateNoteContent(
        path: widget.notePath,
        content: _controller.text,
      );

      // Update the last saved content
      _lastSavedContent = _controller.text;

      setState(() {
        _syncStatus = SyncStatus.synced;
      });
    } catch (e) {
      setState(() {
        _syncStatus = SyncStatus.error;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving note: $e'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _saveNote,
          ),
        ),
      );
    }
  }

  Widget _buildMarkdownToolbar() {
    return Container(
      color: Theme.of(context).cardColor,
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            IconButton(
              icon: Text('# ', style: TextStyle(fontWeight: FontWeight.bold)),
              tooltip: 'Header',
              onPressed: () => _insertMarkdown('# '),
            ),
            IconButton(
              icon: Icon(Icons.format_bold),
              tooltip: 'Bold',
              onPressed: () => _insertMarkdown('**bold text**'),
            ),
            IconButton(
              icon: Icon(Icons.format_italic),
              tooltip: 'Italic',
              onPressed: () => _insertMarkdown('*italic text*'),
            ),
            IconButton(
              icon: Icon(Icons.format_list_bulleted),
              tooltip: 'Bullet List',
              onPressed: () => _insertMarkdown('- '),
            ),
            IconButton(
              icon: Icon(Icons.format_list_numbered),
              tooltip: 'Numbered List',
              onPressed: () => _insertMarkdown('1. '),
            ),
            IconButton(
              icon: Icon(Icons.format_quote),
              tooltip: 'Quote',
              onPressed: () => _insertMarkdown('> '),
            ),
            IconButton(
              icon: Icon(Icons.code),
              tooltip: 'Code',
              onPressed: () => _insertMarkdown('`code`'),
            ),
            IconButton(
              icon: Icon(Icons.link),
              tooltip: 'Link',
              onPressed: () => _insertMarkdown('[link text](url)'),
            ),
          ],
        ),
      ),
    );
  }

  void _insertMarkdown(String markdown) {
    final text = _controller.text;
    final selection = _controller.selection;
    final newText = text.replaceRange(selection.start, selection.end, markdown);

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + markdown.length,
      ),
    );
  }
}
