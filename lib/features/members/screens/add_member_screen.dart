// lib/features/members/screens/add_member_screen.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/member_model.dart';
import '../../../theme/app_colors.dart';
import '../../../shared/constants/app_spacing.dart';
import '../../../shared/widgets/wafferly_text_field.dart';
import '../../../shared/widgets/wafferly_dropdown.dart';
import '../../../shared/widgets/wafferly_date_picker.dart';
import '../../../shared/widgets/wafferly_button.dart';
import '../../../shared/widgets/wafferly_form_section.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final notesController = TextEditingController();

  String relationship = "me";
  String? gender;
  DateTime? birthday;

  final List<Map<String, String>> relationships = [
    {"id": "me", "name": "Me"},
    {"id": "spouse", "name": "Spouse"},
    {"id": "son", "name": "Son"},
    {"id": "daughter", "name": "Daughter"},
    {"id": "father", "name": "Father"},
    {"id": "mother", "name": "Mother"},
    {"id": "brother", "name": "Brother"},
    {"id": "sister", "name": "Sister"},
    {"id": "other", "name": "Other"},
    {"id": "custom", "name": "+ Add Custom Relationship"},
  ];

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    notesController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Name required";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
      return "Invalid email format";
    }
    return null;
  }

  Future<void> _showCustomRelationshipDialog() async {
    final controller = TextEditingController();
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (_) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text(
              "Relationship",
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: WafferlyTextField(
              controller: controller,
              label: "Relationship",
              hint: "Enter relationship",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              WafferlyButton(
                onPressed: () => Navigator.pop(context, controller.text),
                title: "Save",
                fullWidth: false,
              ),
            ],
          );
        },
      );

      final relation = result?.trim();
      if (relation != null && relation.isNotEmpty) {
        final uniqueId =
            "${relation.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}";
        setState(() {
          relationships.insert(relationships.length - 1, {
            "id": uniqueId,
            "name": relation,
          });
          relationship = uniqueId;
        });
      }
    } finally {
      controller.dispose();
    }
  }

  void _saveMember() {
    if (_formKey.currentState!.validate()) {
      final name = nameController.text.trim();
      final phone = phoneController.text.trim();
      final email = emailController.text.trim();
      final notes = notesController.text.trim();

      final member = MemberModel(
        id: const Uuid().v4(),
        name: name,
        relationshipId: relationship,
        birthday: birthday,
        gender: gender,
        phone: phone.isEmpty ? null : phone,
        email: email.isEmpty ? null : email,
        notes: notes.isEmpty ? null : notes,
        isOwner: relationship == "me",
      );

      Navigator.pop(context, member);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Add Member")),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Avatar Section
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.card,
                    child: Icon(
                      Icons.person,
                      size: 34,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Basic Information
              WafferlyFormSection(
                title: "Basic Information",
                children: [
                  WafferlyTextField(
                    controller: nameController,
                    label: "Name",
                    hint: "Enter member name",
                    validator: _validateName,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  WafferlyDropdown<String>(
                    value: relationship,
                    label: "Relationship",
                    items: relationships.map((e) {
                      return DropdownMenuItem(
                        value: e["id"],
                        child: Text(e["name"]!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == "custom") {
                        _showCustomRelationshipDialog();
                        return;
                      }
                      setState(() {
                        relationship = value!;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  WafferlyDropdown<String>(
                    value: gender,
                    label: "Gender",
                    items: const [
                      DropdownMenuItem(value: "Male", child: Text("Male")),
                      DropdownMenuItem(value: "Female", child: Text("Female")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        gender = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  WafferlyDatePicker(
                    selectedDate: birthday,
                    label: "Birthday",
                    onDateSelected: (date) {
                      setState(() {
                        birthday = date;
                      });
                    },
                  ),
                ],
              ),

              // Personal Information
              WafferlyFormSection(
                title: "Personal Information (Optional)",
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  WafferlyTextField(
                    controller: emailController,
                    label: "Email",
                    hint: "Enter email address",
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  WafferlyTextField(
                    controller: notesController,
                    label: "Notes",
                    hint: "Additional notes...",
                    minLines: 3,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Save Button
              WafferlyButton(
                onPressed: _saveMember,
                title: "Save Member",
                icon: Icons.save,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
