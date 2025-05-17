import 'package:flutter/material.dart';
import 'settings_controller.dart';
import '../signin/signin_page.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key, required this.controller}) : super(key: key);
  static const routeName = '/settings';
  final SettingsController controller;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final AuthService _auth = AuthService();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  bool _isDeleting = false;
  bool _isUpdatingName = false;

  @override
  void initState() {
    super.initState();
    _displayNameController.text =
        FirebaseAuth.instance.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Signed out successfully')));
      Navigator.of(context).pushNamedAndRemoveUntil(
        AuthScreen.routeName,
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }

  Future<void> _showReauthDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Account Deletion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'For security, please enter your password to confirm account deletion.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteAccount(user.email!, _passwordController.text);
              },
              child: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount(String email, String password) async {
    setState(() => _isDeleting = true);

    try {
      // First reauthenticate
      final reauthError = await _auth.reauthenticate(email, password);
      if (reauthError != null) {
        throw Exception(reauthError);
      }

      // Then delete account
      final deleteError = await _auth.deleteAccount();
      if (deleteError != null) {
        throw Exception(deleteError);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        AuthScreen.routeName,
        (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to delete account')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _showUpdateDisplayNameDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Display Name'),
          content: TextField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateDisplayName();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateDisplayName() async {
    if (_displayNameController.text.isEmpty) return;

    setState(() => _isUpdatingName = true);

    try {
      final error = await _auth.changeDisplayName(_displayNameController.text);
      if (error != null) {
        throw Exception(error);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name updated successfully')),
      );
      setState(() {}); // Refresh the UI
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to update display name')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingName = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProfileHeader(context, user),
          const SizedBox(height: 20),
          _buildThemeSection(context),
          const SizedBox(height: 20),
          _buildAccountActions(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User? user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Theme.of(context).primaryColor,
          child:
              user?.photoURL != null
                  ? ClipOval(
                    child: Image.network(
                      user!.photoURL!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                  : Text(
                    user?.displayName?.isNotEmpty == true
                        ? user!.displayName!.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 40, color: Colors.white),
                  ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                user?.displayName ?? 'Guest User',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Positioned(
                right:
                    MediaQuery.of(context).size.width *
                    0.25, // Adjust this value as needed
                child: IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showUpdateDisplayNameDialog(context),
                ),
              ),
            ],
          ),
        ),
        Text(
          user?.email ?? 'No email',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Theme',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Theme Mode'),
            DropdownButton<ThemeMode>(
              value: widget.controller.themeMode,
              onChanged: (newThemeMode) {
                widget.controller.updateThemeMode(newThemeMode);
              },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ListTile(
          title: const Text('Sign Out'),
          trailing: const Icon(Icons.logout),
          onTap: () => _signOut(context),
        ),
        ListTile(
          title:
              _isDeleting
                  ? const Text('Deleting Account...')
                  : const Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.red),
                  ),
          trailing:
              _isDeleting
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.delete, color: Colors.red),
          onTap: () => _showReauthDialog(context),
        ),
      ],
    );
  }
}
