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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

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
            padding: const EdgeInsets.symmetric(horizontal: FitoraSpacing.xl, vertical: FitoraSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle(textTheme, 'PERSONAL INFO'),
                _buildCard(
                  child: Column(
                    children: [
                      _buildTextField('Full Name', _nameController, TextInputType.name, Icons.person_rounded, validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Name cannot be blank';
                        return null;
                      }),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Age', _ageController, TextInputType.number, Icons.cake_rounded)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Height (cm)', _heightController, const TextInputType.numberWithOptions(decimal: true), Icons.height_rounded)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField('Weight (kg)', _weightController, const TextInputType.numberWithOptions(decimal: true), Icons.monitor_weight_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: FitoraSpacing.xxl),

                _buildSectionTitle(textTheme, 'GOALS & PREFERENCES'),
                _buildCard(
                  child: Column(
                    children: [
                      _buildDropdown<PersonalizationGoal>('Primary Goal', _goal, PersonalizationGoal.values, (v) => v.label, (v) => setState(() => _goal = v), Icons.flag_rounded),
                      const SizedBox(height: 16),
                      _buildDropdown<ExperienceLevel>('Activity Level', _experienceLevel, ExperienceLevel.values, (v) => v.label, (v) => setState(() => _experienceLevel = v), Icons.directions_run_rounded),
                      const SizedBox(height: 16),
                      _buildDropdown<WorkoutPreference>('Workout Preference', _workoutPreference, WorkoutPreference.values, (v) => v.label, (v) => setState(() => _workoutPreference = v), Icons.fitness_center_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: FitoraSpacing.xxl),
                
                _buildSectionTitle(textTheme, 'WELLNESS FOCUS'),
                _buildCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: WellnessInterest.values.map((interest) {
                      final isSelected = _interests.contains(interest);
                      return FilterChip(
                        label: Text(interest.label),
                        selected: isSelected,
                        showCheckmark: false,
                        selectedColor: FitoraColors.mintGreen.withValues(alpha: 0.2),
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? FitoraColors.mintGreen : Colors.transparent,
                          ),
                        ),
                        labelStyle: textTheme.labelMedium?.copyWith(
                          color: isSelected ? FitoraColors.mintGreen : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                        onSelected: (selected) {
                          ref.read(hapticServiceProvider).selectionClick();
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
                ),
                const SizedBox(height: 48),
                
                Semantics(
                  button: true,
                  label: 'Save Profile Changes',
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FitoraColors.mintGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: FitoraColors.mintGreen.withValues(alpha: 0.4),
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2220).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(TextTheme textTheme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 8),
      child: Text(
        title,
        style: textTheme.labelSmall?.copyWith(
          color: Colors.white54,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType type, IconData icon, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white30, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: FitoraColors.mintGreen)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: FitoraColors.errorRed)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown<T>(String label, T? value, List<T> items, String Function(T) labelBuilder, void Function(T?) onChanged, IconData icon) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(labelBuilder(e), style: const TextStyle(color: Colors.white)))).toList(),
      onChanged: onChanged,
      dropdownColor: const Color(0xFF1A2220),
      icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white54),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white30, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
