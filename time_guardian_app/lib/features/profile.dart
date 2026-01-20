// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:time_guardian/main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:time_guardian/auth/login_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();

  String? _gender;
  String? _avatarUrl;

  bool _loading = true;
  bool _uploading = false;

  Uint8List? _imageBytes;
  String? _fileExtension;

  final _supabase = Supabase.instance.client;

  Future<void> _getProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      _usernameController.text = data['username'] ?? '';
      _ageController.text = data['age']?.toString() ?? '';
      _bioController.text = data['bio'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _countryController.text = data['country'] ?? '';
      _gender = data['gender'];
      _avatarUrl = data['avatar_url'];
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load profile")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('profiles').upsert({
        'id': user.id,
        'username': _usernameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
        'country': _countryController.text.trim(),
        'gender': _gender,
        'updated_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile updated")));
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Update failed: $e")));
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    _imageBytes = await image.readAsBytes();
    _fileExtension = image.name.split('.').last;

    await _uploadImage();
  }

  Future<void> _uploadImage() async {
    if (_imageBytes == null) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _uploading = true);

    final path =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$_fileExtension';

    try {
      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            path,
            _imageBytes!,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$_fileExtension',
            ),
          );

      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(path);

      await _supabase
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', user.id);

      setState(() => _avatarUrl = imageUrl);
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Image upload failed")));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: InkWell(
                    onTap: _pickImage,
                    child: _uploading
                        ? const CircularProgressIndicator()
                        : CircleAvatar(
                            radius: 50,
                            backgroundImage: _avatarUrl != null
                                ? NetworkImage(_avatarUrl!)
                                : null,
                            child: _avatarUrl == null
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: "Username"),
                ),
                TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Age"),
                ),
                TextField(
                  controller: _bioController,
                  decoration: const InputDecoration(labelText: "Bio"),
                  maxLines: 2,
                ),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: "Phone"),
                ),
                TextField(
                  controller: _countryController,
                  decoration: const InputDecoration(labelText: "Country"),
                ),

                DropdownButtonFormField<String>(
                  value: _gender,
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text("Male")),
                    DropdownMenuItem(value: 'Female', child: Text("Female")),
                    DropdownMenuItem(value: 'Other', child: Text("Other")),
                  ],
                  onChanged: (value) {
                    setState(() => _gender = value);
                  },
                  decoration: const InputDecoration(labelText: "Gender"),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateProfile,
                  child: const Text("Update Profile"),
                ),
                TextButton(
                  onPressed: _signOut,
                  child: const Text(
                    "Sign Out",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
    );
  }
}
