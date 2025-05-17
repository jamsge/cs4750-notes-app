import 'package:flutter/material.dart';

abstract class FileSystemItem {
  final String id;
  final String name;
  final IconData icon;
  final List<String> path;

  const FileSystemItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.path,
  });
}

class Folder extends FileSystemItem {
  const Folder({
    required String id,
    required String name,
    required List<String> path,
  }) : super(
    id: id,
    name: name,
    icon: Icons.folder,
    path: path,
  );
}

class Note extends FileSystemItem {
  final String content;
  final DateTime createdAt;
  final String? summary;

  const Note({
    required String id,
    required String name,
    required this.content,
    required this.createdAt,
    required List<String> path,
    this.summary
  }) : super(
    id: id,
    name: name,
    icon: Icons.description,
    path: path,
  );
}
