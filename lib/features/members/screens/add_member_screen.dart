// lib/features/members/screens/add_member_screen.dart

import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/member_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart'; // ✅ استيراد ResponsiveMetrics
import '../../../widgets/shared/wafferly_text_field.dart';
import '../../../shared/widgets/wafferly_dropdown.dart';
import '../../../shared/widgets/wafferly_date_picker.dart';
import '../../../shared/widgets/wafferly_button.dart';
import '../../../shared/widgets/wafferly_form_section.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/input_formatters.dart';

class AddMemberScreen extends StatefulWidget {
  final MemberModel? member;

  const AddMemberScreen({super.key, this.member});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  File? selectedImage;
  String? selectedAvatar;
  final picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final notesController = TextEditingController();

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

  String relationship = "spouse";

  final List<String> avatarOptions = const [
    'assets/avatars/other1.svg',
    'assets/avatars/other2.svg',
    'assets/avatars/other3.svg',
    'assets/avatars/other4.svg',
    'assets/avatars/other5.svg',
    'assets/avatars/other6.svg',
    'assets/avatars/other7.svg',
    'assets/avatars/other8.svg',
    'assets/avatars/other9.svg',
    'assets/avatars/other10.svg',
    'assets/avatars/other11.svg',
    'assets/avatars/other12.svg',
  ];

  @override
  void initState() {
    super.initState();

    final member = widget.member;

    if (member != null) {
      nameController.text = member.name;
      notesController.text = member.notes ?? '';
      relationship = member.relationshipId;
      gender = member.gender;
      birthday = member.birthday;
      selectedAvatar = member.avatarAsset;
      if (member.photoUrl != null) {
        selectedImage = File(member.photoUrl!);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
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

  Future<void> _showAvatarPicker() async {
    final metrics = ResponsiveMetrics.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(
              metrics.isCompactHeight ? metrics.space.sm : metrics.space.md,
            ), // ✅ 16
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Choose Avatar",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: metrics.typography.title, // 18
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: metrics.space.sm), // 16
                GridView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12.0, // ✅ value specific to this widget
                    mainAxisSpacing: 12.0,
                  ),
                  itemCount: avatarOptions.length,
                  itemBuilder: (context, index) {
                    final avatar = avatarOptions[index];
                    final isSelected = selectedAvatar == avatar;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedAvatar = avatar;
                          selectedImage = null;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: EdgeInsets.all(metrics.space.sm), // 8
                            child: SvgPicture.asset(
                              avatar,
                              width: 48, // ✅ fixed size for avatar picker
                              height: 48,
                              fit: BoxFit.contain,
                              theme: const SvgTheme(currentColor: Colors.white),
                              placeholderBuilder: (_) =>
                                  const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final metrics = ResponsiveMetrics.of(context);
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take Photo"),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (file != null) {
                    setState(() {
                      selectedImage = File(file.path);
                      selectedAvatar = null;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Choose From Gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (file != null) {
                    setState(() {
                      selectedImage = File(file.path);
                      selectedAvatar = null;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.face),
                title: const Text("Choose Avatar"),
                onTap: () {
                  Navigator.pop(context);
                  _showAvatarPicker();
                },
              ),
              if (selectedImage != null || selectedAvatar != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    "Remove Photo",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    setState(() {
                      selectedImage = null;
                      selectedAvatar = null;
                    });
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCustomRelationshipDialog() async {
    final metrics = ResponsiveMetrics.of(context);
    final controller = TextEditingController();
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (_) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            title: Text(
              "Relationship",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: metrics.typography.title, // 18
              ),
            ),
            content: WafferlyTextField(
              controller: controller,
              label: "Relationship",
              hint: "Enter relationship",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              WafferlyButton(
                widthFactor: .6,
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
      final notes = notesController.text.trim();

      final member = MemberModel(
        id: widget.member?.id ?? const Uuid().v4(),
        name: name,
        relationshipId: relationship,
        photoUrl: selectedImage?.path ?? widget.member?.photoUrl,
        avatarAsset: selectedAvatar ?? widget.member?.avatarAsset,
        birthday: birthday,
        gender: gender,
        notes: notes.isEmpty ? null : notes,
        isOwner: widget.member?.isOwner ?? false,
        isLinked: widget.member?.isLinked ?? false,
        accountId: widget.member?.accountId,
        isArchived: widget.member?.isArchived ?? false,
        archivedAt: widget.member?.archivedAt,
        transactionsCount: widget.member?.transactionsCount ?? 0,
        monthlySpent: widget.member?.monthlySpent ?? 0,
        goalsCount: widget.member?.goalsCount ?? 0,
      );

      Navigator.pop(context, member);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final isEditingOwner = widget.member?.isOwner == true;
    final availableRelationships = isEditingOwner
        ? relationships
        : relationships.where((e) => e["id"] != "me").toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.member == null ? "Add Member" : "Edit Member",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: metrics.typography.title,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.all(metrics.space.md), // 16
            children: [
              // Avatar Section
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: CircleAvatar(
                          radius: metrics.icon.avatar,
                          backgroundColor: AppColors.card,
                          backgroundImage: selectedImage != null
                              ? FileImage(selectedImage!)
                              : null,
                          child: selectedImage != null
                              ? null
                              : selectedAvatar != null
                              ? Padding(
                                  padding: EdgeInsets.all(
                                    metrics.isCompactHeight ? 8 : 10,
                                  ),
                                  child: SvgPicture.asset(
                                    selectedAvatar!,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : Icon(
                                  Icons.add_a_photo,
                                  size: metrics.icon.medium, // 24
                                  color: AppColors.textPrimary,
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: metrics.space.md), // 8
                    Text(
                      "Tap to add photo",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: metrics.text(12),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: metrics.space.md), // 16
              // Basic Information
              WafferlyFormSection(
                title: "Basic Information",
                children: [
                  WafferlyTextField(
                    controller: nameController,
                    label: "Name",
                    hint: "Enter member name",
                    validator: _validateName,
                    inputFormatters: [WafferlyInputFormatters.personName],
                  ),
                  SizedBox(height: metrics.space.sm), // 8
                  WafferlyDropdown<String>(
                    value: relationship,
                    label: "Relationship",
                    items: availableRelationships.map((e) {
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
                  SizedBox(height: metrics.space.sm), // 8
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
                  SizedBox(height: metrics.space.md), // 8
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
              SizedBox(height: metrics.space.xl), // 32
              // Save Button
              WafferlyButton(
                widthFactor: .6,
                onPressed: _saveMember,
                title: "Save Member",
                icon: Icons.save,
              ),
              SizedBox(height: metrics.space.md), // 16
            ],
          ),
        ),
      ),
    );
  }
}
