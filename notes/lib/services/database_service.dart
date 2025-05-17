import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

class CombinedQuerySnapshot extends QuerySnapshot {
  final QuerySnapshot _first;
  final QuerySnapshot _second;

  CombinedQuerySnapshot(this._first, this._second);

  @override
  List<QueryDocumentSnapshot> get docs => [..._first.docs, ..._second.docs];

  @override
  List<DocumentChange> get docChanges => [
    ..._first.docChanges,
    ..._second.docChanges,
  ];

  @override
  SnapshotMetadata get metadata => _first.metadata;

  @override
  int get size => _first.size + _second.size;
}

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // Get reference to the user's root document
  DocumentReference get _userRootDoc {
    if (_currentUserId == null) throw 'User not authenticated';
    return _firestore.collection('userData').doc(_currentUserId);
  }

  // Creates a new folder at the specified path
  Future<String> createFolder({
    required String path,
    required String name,
  }) async {
    try {
      final folderData = {
        'name': name,
        'type': 'folder',
        'createdAt': FieldValue.serverTimestamp(),
        'uid': _currentUserId,
        'path': path,
      };

      DocumentReference docRef;

      if (path.isEmpty) {
        // Create in user's root folders collection
        docRef = await _userRootDoc.collection('folders').add(folderData);
      } else {
        // Parse the path and create in subcollection
        final pathParts = path.split('/');
        if (pathParts.length % 2 != 0) {
          throw 'Invalid path format. Should be collection/document/collection/document...';
        }

        DocumentReference currentRef = _userRootDoc
            .collection(pathParts[0])
            .doc(pathParts[1]);
        for (int i = 2; i < pathParts.length; i += 2) {
          currentRef = currentRef
              .collection(pathParts[i])
              .doc(pathParts[i + 1]);
        }

        docRef = await currentRef.collection('folders').add(folderData);
      }

      return docRef.id;
    } catch (e) {
      throw 'Failed to create folder: $e';
    }
  }

  Future<String> createNote({
    required String path,
    String name = "Untitled note",
    String content = ""
  }) async {
    try {
      final noteData = {
        'name': name,
        'type': 'note',
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'uid': _currentUserId,
        'path': path,
      };

      DocumentReference docRef;

      if (path.isEmpty) {
        // Create in user's root notes collection
        docRef = await _userRootDoc.collection('notes').add(noteData);
      } else {
        // Parse the path and create in subcollection
        final pathParts = path.split('/');
        if (pathParts.length % 2 != 0) {
          throw 'Invalid path format. Should be collection/document/collection/document...';
        }

        DocumentReference currentRef = _userRootDoc
            .collection(pathParts[0])
            .doc(pathParts[1]);
        for (int i = 2; i < pathParts.length; i += 2) {
          currentRef = currentRef
              .collection(pathParts[i])
              .doc(pathParts[i + 1]);
        }

        docRef = await currentRef.collection('notes').add(noteData);
      }

      return docRef.id;
    } catch (e) {
      throw 'Failed to create note: $e';
    }
  }

  // Gets a single note document by its path
  Future<Map<String, dynamic>> getNote({required String path}) async {
    try {
      if (path.isEmpty) {
        throw 'Invalid path: Path cannot be empty';
      }

      final pathParts = path.split('/').where((part) => part.isNotEmpty).toList();

      DocumentReference noteDoc;
      if (pathParts.length == 2) {
        // Note is in root collection
        noteDoc = _userRootDoc.collection(pathParts[0]).doc(pathParts[1]);
      } else {
        // Note is in nested collection
        DocumentReference currentRef = _userRootDoc
            .collection(pathParts[0])
            .doc(pathParts[1]);
        for (int i = 2; i < pathParts.length - 2; i += 2) {
          currentRef = currentRef
              .collection(pathParts[i])
              .doc(pathParts[i + 1]);
        }
        noteDoc = currentRef
            .collection(pathParts[pathParts.length - 2])
            .doc(pathParts.last);
      }

      // Verify the document exists and belongs to the current user
      final docSnapshot = await noteDoc.get();
      if (!docSnapshot.exists) {
        throw 'Note not found';
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      if (data['uid'] != _currentUserId) {
        throw 'Note not owned by current user';
      }

      return data;
    } catch (e) {
      debugPrint(e.toString());
      throw 'Failed to get note: $e';
    }
  }

// Updates the content of an existing note
  Future<void> updateNoteContent({
    required String path,
    required String content,
  }) async {
    try {
      if (path.isEmpty) {
        throw 'Invalid path: Path cannot be empty';
      }

      final pathParts = path.split('/').where((part) => part.isNotEmpty).toList();

      DocumentReference noteDoc;
      if (pathParts.length == 2) {
        // Note is in root collection
        noteDoc = _userRootDoc.collection(pathParts[0]).doc(pathParts[1]);
      } else {
        // Note is in nested collection
        DocumentReference currentRef = _userRootDoc
            .collection(pathParts[0])
            .doc(pathParts[1]);
        for (int i = 2; i < pathParts.length - 2; i += 2) {
          currentRef = currentRef
              .collection(pathParts[i])
              .doc(pathParts[i + 1]);
        }
        noteDoc = currentRef
            .collection(pathParts[pathParts.length - 2])
            .doc(pathParts.last);
      }

      // Verify the document exists and belongs to the current user before updating
      final docSnapshot = await noteDoc.get();
      if (!docSnapshot.exists) {
        throw 'Note not found';
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      if (data['uid'] != _currentUserId) {
        throw 'Note not owned by current user';
      }

      // Update the note content and updatedAt timestamp
      await noteDoc.update({
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update note content: $e';
    }
  }

  // Deletes an item at the specified path
  Future<void> deleteUserData({required String path}) async {
    try {
      debugPrint("deleting path ${path}");

      final pathParts = path.split('/').where((part) => part.isNotEmpty).toList();

      DocumentReference docToDelete;
      if (pathParts.length == 2) {
        // Deleting from root collection
        docToDelete = _userRootDoc.collection(pathParts[0]).doc(pathParts[1]);
      } else {
        // Deleting from nested collection
        DocumentReference currentRef = _userRootDoc
            .collection(pathParts[0])
            .doc(pathParts[1]);
        for (int i = 2; i < pathParts.length - 2; i += 2) {
          currentRef = currentRef
              .collection(pathParts[i])
              .doc(pathParts[i + 1]);
        }
        docToDelete = currentRef
            .collection(pathParts[pathParts.length - 2])
            .doc(pathParts.last);
      }

      // Verify the document belongs to the current user before deleting
      final docSnapshot = await docToDelete.get();
      if (docSnapshot.exists && docSnapshot.get('uid') == _currentUserId) {
        await docToDelete.delete();
      } else {
        throw 'Document not found or not owned by user';
      }
    } catch (e) {
      throw 'Failed to delete item: $e';
    }
  }

  Future<void> updateDocumentName({
    required String path,
    required String newName,
  }) async {
    try {
      debugPrint("updating name at path $path to $newName");

      final pathParts = path.split('/').where((part) => part.isNotEmpty).toList();

      DocumentReference docToUpdate;
      if (pathParts.length == 2) {
        // Updating in root collection
        docToUpdate = _userRootDoc.collection(pathParts[0]).doc(pathParts[1]);
      } else {
        // Updating in nested collection
        DocumentReference currentRef = _userRootDoc
            .collection(pathParts[0])
            .doc(pathParts[1]);
        for (int i = 2; i < pathParts.length - 2; i += 2) {
          currentRef = currentRef
              .collection(pathParts[i])
              .doc(pathParts[i + 1]);
        }
        docToUpdate = currentRef
            .collection(pathParts[pathParts.length - 2])
            .doc(pathParts.last);
      }

      // Verify the document belongs to the current user before updating
      final docSnapshot = await docToUpdate.get();
      if (docSnapshot.exists && docSnapshot.get('uid') == _currentUserId) {
        await docToUpdate.update({'name': newName});
      } else {
        throw 'Document not found or not owned by user';
      }
    } catch (e) {
      throw 'Failed to update document name: $e';
    }
  }

  // Get stream of root items (folders and notes)
  Stream<QuerySnapshot> getRootItemsStream() {
    if (_currentUserId == null) throw 'User not authenticated';

    // Combine folders and notes from root
    return CombineLatestStream.combine2(
      _userRootDoc.collection('folders').snapshots(),
      _userRootDoc.collection('notes').snapshots(),
      (foldersSnapshot, notesSnapshot) {
        return CombinedQuerySnapshot(foldersSnapshot, notesSnapshot);
      },
    );
  }

  /// Gets a stream of all items (both folders and notes) at the specified path
  /// Path should be in the format ['collection', 'docId', 'collection', 'docId', ...]
  Stream<QuerySnapshot> getFolderContentsStream({required List<String> path}) {
    if (path.isEmpty || path.length % 2 != 0) {
      throw 'Invalid path format';
    }

    // Build the document reference for the current path
    DocumentReference currentRef = _userRootDoc;
    for (int i = 0; i < path.length; i += 2) {
      currentRef = currentRef.collection(path[i]).doc(path[i + 1]);
    }

    // Get streams for both folders and notes in this location
    final foldersStream = currentRef.collection('folders').snapshots();
    final notesStream = currentRef.collection('notes').snapshots();

    // Combine them into a single stream
    return CombineLatestStream.combine2(foldersStream, notesStream, (
      foldersSnapshot,
      notesSnapshot,
    ) {
      return CombinedQuerySnapshot(foldersSnapshot, notesSnapshot);
    });
  }
}
