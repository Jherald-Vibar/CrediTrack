import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/client.dart';
import 'package:creditrack/providers/app_state.dart';
import 'package:provider/provider.dart';

class AddEditClientScreen extends StatefulWidget {
  final Client? client;
  const AddEditClientScreen({super.key, this.client});

  @override
  State<AddEditClientScreen> createState() => _AddEditClientScreenState();
}

class _AddEditClientScreenState extends State<AddEditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _addressCtrl;
  String? _imagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.client?.name ?? '');
    _contactCtrl = TextEditingController(text: widget.client?.contactNumber ?? '');
    _addressCtrl = TextEditingController(text: widget.client?.address ?? '');
    _imagePath = widget.client?.profileImagePath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (result != null) setState(() => _imagePath = result.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();

    if (widget.client == null) {
      await state.addClient(
        name: _nameCtrl.text.trim(),
        contactNumber: _contactCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        profileImagePath: _imagePath,
      );
    } else {
      await state.updateClient(widget.client!.copyWith(
        name: _nameCtrl.text.trim(),
        contactNumber: _contactCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        profileImagePath: _imagePath,
      ));
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.client != null;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isEdit ? 'Update Client' : 'New Client', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // --- MODERN PROFILE PHOTO PICKER ---
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue.shade50,
                        backgroundImage: _imagePath != null
                            ? FileImage(File(_imagePath!))
                            : null,
                        child: _imagePath == null
                            ? Icon(Icons.person_outline_rounded, size: 50, color: Colors.blue.shade300)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- FORM FIELDS ---
              _buildSectionHeader('Basic Information'),
              _buildInputCard([
                _buildTextField(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  capitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _contactCtrl,
                  label: 'Mobile Number',
                  icon: Icons.phone_android_rounded,
                  keyboard: TextInputType.phone,
                ),
              ]),
              
              const SizedBox(height: 24),
              _buildSectionHeader('Location'),
              _buildInputCard([
                _buildTextField(
                  controller: _addressCtrl,
                  label: 'Home Address',
                  icon: Icons.map_outlined,
                  maxLines: 2,
                ),
              ]),

              const SizedBox(height: 40),
              
              // --- SAVE BUTTON ---
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isEdit ? 'Update Profile' : 'Register Client', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODERN UI HELPERS ---

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  Widget _buildInputCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      textCapitalization: capitalization,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal, fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: Colors.blueGrey),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required field' : null,
    );
  }
}