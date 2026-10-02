import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/features/personalization/domain/personalization_models.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/features/auth/providers/auth_providers.dart';
import 'package:fitora/features/settings/providers/settings_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  late FocusNode _nameFocus;
  late FocusNode _ageFocus;
  late FocusNode _heightFocus;
  late FocusNode _weightFocus;

  late AnimationController _avatarAnimController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  // Unit systems
  bool _isWeightMetric = true; // true: kg, false: lbs
  bool _isHeightMetric = true; // true: cm, false: ft

  PersonalizationGoal? _goal;
  ExperienceLevel? _experienceLevel;
  WorkoutPreference? _workoutPreference;
  Set<WellnessInterest> _interests = {};

  @override
  void initState() {
    super.initState();

    final profile = ref.read(personalizationControllerProvider).profile;
    final authSession = ref.read(authStateProvider);
    final isMetricSetting = ref.read(settingsProvider).isMetric;

    _isWeightMetric = isMetricSetting;
    _isHeightMetric = isMetricSetting;

    // Resolve initial name (Auth -> Profile -> '')
    final initialName = authSession.user?.displayName ?? profile.name ?? '';

    // Unit conversions for initial presentation
    String initialHeight = '';
    if (profile.heightCm != null && profile.heightCm! > 0) {
      if (_isHeightMetric) {
        initialHeight = profile.heightCm!.toStringAsFixed(
          profile.heightCm! % 1 == 0 ? 0 : 1,
        );
      } else {
        final ft = profile.heightCm! / 30.48;
        initialHeight = ft.toStringAsFixed(1);
      }
    }

    String initialWeight = '';
    if (profile.weightKg != null && profile.weightKg! > 0) {
      if (_isWeightMetric) {
        initialWeight = profile.weightKg!.toStringAsFixed(
          profile.weightKg! % 1 == 0 ? 0 : 1,
        );
      } else {
        final lbs = profile.weightKg! * 2.20462;
        initialWeight = lbs.toStringAsFixed(1);
      }
    }

    _nameController = TextEditingController(text: initialName);
    _ageController = TextEditingController(text: profile.age?.toString() ?? '');
    _heightController = TextEditingController(text: initialHeight);
    _weightController = TextEditingController(text: initialWeight);

    _nameFocus = FocusNode();
    _ageFocus = FocusNode();
    _heightFocus = FocusNode();
    _weightFocus = FocusNode();

    _goal = profile.goal;
    _experienceLevel = profile.experienceLevel;
    _workoutPreference = profile.workoutPreference;
    _interests = Set.from(profile.interests);

    // Setup animated avatar glow ring
    _avatarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(
        parent: _avatarAnimController,
        curve: Curves.easeInOutSine,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _avatarAnimController,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _avatarAnimController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _nameFocus.dispose();
    _ageFocus.dispose();
    _heightFocus.dispose();
    _weightFocus.dispose();
    super.dispose();
  }

  void _onToggleWeightUnit(bool toMetric) {
    if (_isWeightMetric == toMetric) return;
    HapticFeedback.selectionClick();
    final currentText = _weightController.text.trim();
    final currentVal = double.tryParse(currentText);

    setState(() {
      _isWeightMetric = toMetric;
      if (currentVal != null && currentVal > 0) {
        if (toMetric) {
          // lbs to kg
          final kg = currentVal / 2.20462;
          _weightController.text = kg.toStringAsFixed(1);
        } else {
          // kg to lbs
          final lbs = currentVal * 2.20462;
          _weightController.text = lbs.toStringAsFixed(1);
        }
      }
    });
  }

  void _onToggleHeightUnit(bool toMetric) {
    if (_isHeightMetric == toMetric) return;
    HapticFeedback.selectionClick();
    final currentText = _heightController.text.trim();
    final currentVal = double.tryParse(currentText);

    setState(() {
      _isHeightMetric = toMetric;
      if (currentVal != null && currentVal > 0) {
        if (toMetric) {
          // ft to cm
          final cm = currentVal * 30.48;
          _heightController.text = cm.toStringAsFixed(0);
        } else {
          // cm to ft
          final ft = currentVal / 30.48;
          _heightController.text = ft.toStringAsFixed(1);
        }
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    // Success haptic feedback
    await HapticFeedback.mediumImpact();

    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());

    // Height normalization to cm
    double? heightCm;
    final rawHeight = double.tryParse(_heightController.text.trim());
    if (rawHeight != null && rawHeight > 0) {
      heightCm = _isHeightMetric ? rawHeight : rawHeight * 30.48;
    }

    // Weight normalization to kg
    double? weightKg;
    final rawWeight = double.tryParse(_weightController.text.trim());
    if (rawWeight != null && rawWeight > 0) {
      weightKg = _isWeightMetric ? rawWeight : rawWeight / 2.20462;
    }

    final currentProfile = ref.read(personalizationControllerProvider).profile;

    final updatedProfile = currentProfile.copyWith(
      name: name.isNotEmpty ? name : null,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      goal: _goal,
      experienceLevel: _experienceLevel,
      workoutPreference: _workoutPreference,
      interests: _interests,
    );

    ref.read(personalizationControllerProvider.notifier).updateProfile(updatedProfile);

    // Sync unit preference with settings
    final overallMetric = _isWeightMetric && _isHeightMetric;
    ref.read(settingsProvider.notifier).updateSetting('isMetric', overallMetric);

    if (!mounted) return;

    // Show modern toast / snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        backgroundColor: const Color(0xFF161E1C),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: FitoraColors.mintGreen.withValues(alpha: 0.4), width: 1.2),
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: FitoraColors.mintGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: FitoraColors.mintGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Profile updated successfully',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 2200),
      ),
    );

    // Safely pop fullscreen modal back to Profile
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    } else if (context.canPop()) {
      context.pop();
    }
  }

  void _safePop() {
    HapticFeedback.lightImpact();
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    } else if (context.canPop()) {
      context.pop();
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'F';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currentName = _nameController.text.trim();
    final initials = _getInitials(currentName);

    return Scaffold(
      backgroundColor: const Color(0xFF0E1312),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Semantics(
          label: 'Back to profile',
          button: true,
          child: IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            onPressed: _safePop,
          ),
        ),
        title: Text(
          'Edit Profile',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          Semantics(
            label: 'Save profile changes',
            button: true,
            child: TextButton(
              onPressed: _saveProfile,
              style: TextButton.styleFrom(
                minimumSize: const Size(60, 48),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  color: FitoraColors.mintGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: FitoraSpacing.xl,
              vertical: FitoraSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Animated Avatar Glow Ring
                _buildAvatarSection(initials),
                const SizedBox(height: 28),

                // 2. Personal Information Section
                _buildSectionHeader(textTheme, 'PERSONAL INFORMATION', Icons.person_rounded),
                const SizedBox(height: 12),
                _buildGlassInput(
                  label: 'Full Name',
                  hint: 'Enter your name',
                  controller: _nameController,
                  focusNode: _nameFocus,
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.name,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name cannot be blank';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildGlassInput(
                  label: 'Age',
                  hint: 'e.g. 28',
                  controller: _ageController,
                  focusNode: _ageFocus,
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final parsed = int.tryParse(v);
                      if (parsed == null || parsed < 13 || parsed > 120) {
                        return 'Enter a valid age (13-120)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // 3. Body Metrics with Unit Toggles
                _buildSectionHeader(textTheme, 'BODY METRICS', Icons.straighten_rounded),
                const SizedBox(height: 12),
                _buildMetricInputWithToggle(
                  label: 'Height',
                  hint: _isHeightMetric ? 'e.g. 175' : 'e.g. 5.9',
                  controller: _heightController,
                  focusNode: _heightFocus,
                  icon: Icons.height_rounded,
                  isMetric: _isHeightMetric,
                  metricUnit: 'cm',
                  imperialUnit: 'ft',
                  onToggleUnit: _onToggleHeightUnit,
                ),
                const SizedBox(height: 14),
                _buildMetricInputWithToggle(
                  label: 'Weight',
                  hint: _isWeightMetric ? 'e.g. 70.0' : 'e.g. 154.0',
                  controller: _weightController,
                  focusNode: _weightFocus,
                  icon: Icons.scale_rounded,
                  isMetric: _isWeightMetric,
                  metricUnit: 'kg',
                  imperialUnit: 'lbs',
                  onToggleUnit: _onToggleWeightUnit,
                ),
                const SizedBox(height: 28),

                // 4. Fitness Goals & Preferences
                _buildSectionHeader(textTheme, 'GOALS & PREFERENCES', Icons.flag_rounded),
                const SizedBox(height: 12),
                _buildGlassDropdown<PersonalizationGoal>(
                  label: 'Primary Goal',
                  value: _goal,
                  icon: Icons.track_changes_rounded,
                  items: PersonalizationGoal.values,
                  labelBuilder: (v) => v.label,
                  onChanged: (v) => setState(() => _goal = v),
                ),
                const SizedBox(height: 14),
                _buildGlassDropdown<ExperienceLevel>(
                  label: 'Activity Level',
                  value: _experienceLevel,
                  icon: Icons.trending_up_rounded,
                  items: ExperienceLevel.values,
                  labelBuilder: (v) => v.label,
                  onChanged: (v) => setState(() => _experienceLevel = v),
                ),
                const SizedBox(height: 14),
                _buildGlassDropdown<WorkoutPreference>(
                  label: 'Workout Preference',
                  value: _workoutPreference,
                  icon: Icons.fitness_center_rounded,
                  items: WorkoutPreference.values,
                  labelBuilder: (v) => v.label,
                  onChanged: (v) => setState(() => _workoutPreference = v),
                ),
                const SizedBox(height: 28),

                // 5. Wellness Focus
                _buildSectionHeader(textTheme, 'WELLNESS FOCUS', Icons.spa_rounded),
                const SizedBox(height: 12),
                _buildWellnessChips(textTheme),
                const SizedBox(height: 36),

                // 6. Action Button
                _buildSaveButton(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 1. Animated Avatar Glow Ring
  Widget _buildAvatarSection(String initials) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated breathing glow ring
          AnimatedBuilder(
            animation: _avatarAnimController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: FitoraColors.mintGreen.withValues(
                          alpha: 0.28 * (_pulseAnimation.value - 0.8),
                        ),
                        blurRadius: 26,
                        spreadRadius: 3,
                      ),
                      BoxShadow(
                        color: FitoraColors.calmCyan.withValues(
                          alpha: 0.22 * (_pulseAnimation.value - 0.8),
                        ),
                        blurRadius: 32,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Animated rotating gradient border ring
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: 108,
                  height: 108,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        FitoraColors.mintGreen,
                        FitoraColors.softEmerald,
                        FitoraColors.calmCyan,
                        FitoraColors.lavender,
                        FitoraColors.mintGreen,
                      ],
                    ),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF0E1312),
                    ),
                  ),
                ),
              );
            },
          ),

          // Inner Avatar Circle
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF1E2826), Color(0xFF121917)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),

          // Floating Edit Badge
          Positioned(
            right: 0,
            bottom: 2,
            child: Semantics(
              label: 'Change avatar picture',
              button: true,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      backgroundColor: const Color(0xFF161E1C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      content: const Text(
                        'Avatar upload will sync with Cloud Account',
                        style: TextStyle(color: Colors.white70),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [FitoraColors.mintGreen, FitoraColors.softEmerald],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFF0E1312),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: FitoraColors.mintGreen.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.black,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section Header with Icon
  Widget _buildSectionHeader(TextTheme textTheme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: FitoraColors.mintGreen.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          Text(
            title,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Sleek Glass Input with Animated Focus Glow
  Widget _buildGlassInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final isFocused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isFocused
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused
                  ? FitoraColors.mintGreen
                  : Colors.white.withValues(alpha: 0.08),
              width: isFocused ? 1.5 : 1.0,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: FitoraColors.mintGreen.withValues(alpha: 0.18),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            validator: validator,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: isFocused ? FitoraColors.mintGreen : Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              prefixIcon: Icon(
                icon,
                color: isFocused ? FitoraColors.mintGreen : Colors.white38,
                size: 20,
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        );
      },
    );
  }

  /// Metric Input with Integrated Segmented Unit Toggle (kg/lbs or cm/ft)
  Widget _buildMetricInputWithToggle({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required bool isMetric,
    required String metricUnit,
    required String imperialUnit,
    required void Function(bool) onToggleUnit,
  }) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final isFocused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isFocused
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused
                  ? FitoraColors.mintGreen
                  : Colors.white.withValues(alpha: 0.08),
              width: isFocused ? 1.5 : 1.0,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: FitoraColors.mintGreen.withValues(alpha: 0.18),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.only(left: 16, right: 10, top: 4, bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final val = double.tryParse(v);
                      if (val == null || val <= 0) {
                        return 'Enter a valid number';
                      }
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: TextStyle(
                      color: isFocused ? FitoraColors.mintGreen : Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    hintText: hint,
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                    prefixIcon: Icon(
                      icon,
                      color: isFocused ? FitoraColors.mintGreen : Colors.white38,
                      size: 20,
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Segmented Unit Toggle Pill
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildUnitSegment(
                      title: metricUnit,
                      isSelected: isMetric,
                      onTap: () => onToggleUnit(true),
                    ),
                    _buildUnitSegment(
                      title: imperialUnit,
                      isSelected: !isMetric,
                      onTap: () => onToggleUnit(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnitSegment({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        constraints: const BoxConstraints(minWidth: 38, minHeight: 32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? FitoraColors.mintGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: FitoraColors.mintGreen.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white54,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// Sleek Glass Dropdown
  Widget _buildGlassDropdown<T>({
    required String label,
    required T? value,
    required IconData icon,
    required List<T> items,
    required String Function(T) labelBuilder,
    required void Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          isDense: true,
          dropdownColor: const Color(0xFF161E1C),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 20),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
            prefixIcon: Icon(icon, color: Colors.white38, size: 20),
            prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            isDense: true,
          ),
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                labelBuilder(item),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (v) {
            HapticFeedback.selectionClick();
            onChanged(v);
          },
        ),
      ),
    );
  }

  /// Wellness Focus Wrap Chips
  Widget _buildWellnessChips(TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: WellnessInterest.values.map((interest) {
          final isSelected = _interests.contains(interest);
          return FilterChip(
            label: Text(interest.label),
            selected: isSelected,
            showCheckmark: false,
            avatar: Icon(
              isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
              size: 16,
              color: isSelected ? Colors.black : Colors.white54,
            ),
            selectedColor: FitoraColors.mintGreen,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12.5,
            ),
            side: BorderSide(
              color: isSelected
                  ? FitoraColors.mintGreen
                  : Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            onSelected: (selected) {
              HapticFeedback.selectionClick();
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
    );
  }

  /// Save Button
  Widget _buildSaveButton() {
    return Semantics(
      label: 'Save profile changes',
      button: true,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [FitoraColors.mintGreen, FitoraColors.softEmerald],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: FitoraColors.mintGreen.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_rounded, color: Colors.black, size: 20),
              SizedBox(width: 8),
              Text(
                'Save Changes',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
