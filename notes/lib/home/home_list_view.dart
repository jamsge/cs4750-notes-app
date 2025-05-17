import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../add_note/note_editor_view.dart';
import '../settings/settings_view.dart';
import 'sample_item.dart';
import '../services/database_service.dart';

/// Displays a list of FileSystemItems from Firestore.
class HomeListView extends StatelessWidget {
  const HomeListView({
    super.key,
    this.currentPath = const [],
    this.currentFirestorePath = const [],
  });

  static const routeName = '/home';

  final List<String> currentPath;
  final List<String> currentFirestorePath;

  @override
  Widget build(BuildContext context) {
    final databaseService = DatabaseService();

    debugPrint('Building HomeListView with:');
    debugPrint(' - currentPath: ${currentPath.join('/')}');
    debugPrint(' - currentFirestorePath: ${currentFirestorePath.join('/')}');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_buildAppBarTitle()),
            if (currentPath.length > 1)
              Text(
                currentPath.join(' / '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: currentPath.isEmpty
            ? databaseService.getRootItemsStream()
            : databaseService.getFolderContentsStream(path: currentFirestorePath),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['type'] == 'folder') {
              return Folder(
                id: doc.id,
                name: data['name'],
                path: currentPath,
              );
            } else {
              return Note(
                id: doc.id,
                name: data['name'],
                content: data['content'] ?? '',
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0),
                path: currentPath,
              );
            }
          }).toList();

          return ListView.builder(
            restorationId: 'HomeListView',
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) {
              final item = items[index];

              return Column(
                children: [
                  ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.name),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (String value) async {
                        if (value == 'delete') {
                          // Handle deletion
                          final databaseService = DatabaseService();
                          try {
                            await databaseService.deleteUserData(
                                path: "${currentFirestorePath.join('/')}/${item.runtimeType.toString().toLowerCase()}s/${item.id}");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${item.name} deleted')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete: $e')),
                            );
                          }
                        } else if (value == 'rename') {
                          _showRenameDialog(context, item);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'rename',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Rename'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (item is Folder) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeListView(
                              currentPath: [...currentPath, item.name],
                              currentFirestorePath: [
                                ...currentFirestorePath,
                                'folders',
                                item.id,
                              ],
                            ),
                          ),
                        );
                      } else if (item is Note) {
                        String notePath = "${currentFirestorePath.join('/')}/notes/${item.id}";
                        debugPrint("Opening note: ${notePath}");
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NotePage(notePath)),
                        );
                      }
                    },
                  ),
                  const Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Colors.grey,
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add_folder',
            onPressed: () => _showAddDialog(context, isFolder: true),
            child: const Icon(Icons.create_new_folder),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_note',
            onPressed: () => _showAddDialog(context, isFolder: false),
            child: const Icon(Icons.description),
          ),
          const SizedBox(height: 16),
        ],
      ),

    );
  }

  String _buildAppBarTitle() {
    if (currentPath.isEmpty) return 'Notes';
    return currentPath.last;
  }

  void _showAddDialog(BuildContext context, {required bool isFolder}) {
    final textController = TextEditingController();
    final databaseService = DatabaseService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${isFolder ? 'Folder' : 'Note'}'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter ${isFolder ? 'folder' : 'note'} name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                try {
                  if (isFolder) {
                    await databaseService.createFolder(
                      path: currentFirestorePath.join('/'),
                      name: name,
                    );
                  } else {
                    await databaseService.createNote(
                      path: currentFirestorePath.join('/'),
                      name: name,
                    );
                  }
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, FileSystemItem item) {
    final textController = TextEditingController(text: item.name);
    final databaseService = DatabaseService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Item'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter new name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = textController.text.trim();
              if (newName.isNotEmpty && newName != item.name) {
                try {
                  await databaseService.updateDocumentName(
                    path: "${currentFirestorePath.join('/')}/${item.runtimeType.toString().toLowerCase()}s/${item.id}",
                    newName: newName,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Renamed to $newName')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to rename: $e')),
                  );
                }
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}