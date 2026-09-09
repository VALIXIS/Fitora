import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/features/personalization/domain/personalization_models.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/features/auth/providers/auth_providers.dart';
import 'package:fitora/core/services/haptic_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  PersonalizationGoal? _goal;
  ExperienceLevel? _experienceLevel;
  WorkoutPreference? _workoutPreference;
  Set<WellnessInterest> _interests = {};

  @override
  void initState() {
    super.initState();
    final profile = ref.read(personalizationControllerProvider).profile;
    final authSession = ref.read(authStateProvider);
    
    // Resolve initial name (Auth -> Profile -> '')
    final initialName = authSession.user?.displayName ?? profile.name ?? '';
    
    _nameController = TextEditingController(text: initialName);
    _ageController = TextEditingController(text: profile.age?.toString() ?? '');
    _heightController = TextEditingController(text: profile.heightCm?.toString() ?? '');
    _weightController = TextEditingController(text: profile.weightKg?.toString() ?? '');

    _goal = profile.goal;
    _experienceLevel = profile.experienceLevel;
    _workoutPreference = profile.workoutPreference;
    _interests = Set.from(profile.interests);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final age = int.tryParse(_ageController.text.trim());
      final height = double.tryParse(_heightController.text.trim());
      final weight = double.tryParse(_weightController.text.trim());
      
      final currentProfile = ref.read(personalizationControllerProvider).profile;
      
      final updatedProfile = currentProfile.copyWith(
        name: name.isNotEmpty ? name : null,
        age: age,
        heightCm: height,
        weightKg: weight,
        goal: _goal,
        experienceLevel: _experienceLevel,
        workoutPreference: _workoutPreference,
        interests: _interests,
      );

      ref.read(personalizationControllerProvider.notifier).updateProfile(updatedProfile);
      ref.read(hapticServiceProvider).buttonPress();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: FitoraColors.mintGreen),
                SizedBox(width: 12),
                Text('Profile updated successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: const Color(0xFF161E1C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop(); // Return to Profile
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1312),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Edit Profile', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(FitoraSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle(textTheme, 'PERSONAL INFO'),
                _buildTextField('Name', _nameController, TextInputType.name, validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name cannot be blank';
                  return null;
                }),
                const SizedBox(height: FitoraSpacing.md),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Age', _ageController, TextInputType.number)),
                    const SizedBox(width: FitoraSpacing.md),
                    Expanded(child: _buildTextField('Height (cm)', _heightController, TextInputType.numberWithOptions(decimal: true))),
                    const SizedBox(width: FitoraSpacing.md),
                    Expanded(child: _buildTextField('Weight (kg)', _weightController, TextInputType.numberWithOptions(decimal: true))),
                  ],
                ),
                const SizedBox(height: FitoraSpacing.xxl),

                _buildSectionTitle(textTheme, 'GOALS & PREFERENCES'),
                _buildDropdown<PersonalizationGoal>('Primary Goal', _goal, PersonalizationGoal.values, (v) => v.label, (v) => setState(() => _goal = v)),
                const SizedBox(height: FitoraSpacing.md),
                _buildDropdown<ExperienceLevel>('Activity Level', _experienceLevel, ExperienceLevel.values, (v) => v.label, (v) => setState(() => _experienceLevel = v)),
                const SizedBox(height: FitoraSpacing.md),
                _buildDropdown<WorkoutPreference>('Workout Preference', _workoutPreference, WorkoutPreference.values, (v) => v.label, (v) => setState(() => _workoutPreference = v)),
                const SizedBox(height: FitoraSpacing.xxl),
                
                _buildSectionTitle(textTheme, 'WELLNESS FOCUS'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: WellnessInterest.values.map((interest) {
                    final isSelected = _interests.contains(interest);
                    return ChoiceChip(
                      label: Text(interest.label),
                      selected: isSelected,
                      selectedColor: FitoraColors.lavender.withValues(alpha: 0.2),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      labelStyle: textTheme.labelSmall?.copyWith(
                        color: isSelected ? FitoraColors.lavender : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _interests.add(interest);
                          } else {
                            _interests.remove(interest);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 48), // Replace xxxl with 48
                
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FitoraColors.mintGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(TextTheme textTheme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType type, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FitoraColors.mintGreen),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(String label, T? value, List<T> items, String Function(T) labelBuilder, void Function(T?) onChanged) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      dropdownColor: const Color(0xFF1A2221),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(labelBuilder(item)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
