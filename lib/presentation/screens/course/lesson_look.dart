import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// Picture and colour of each of the 5 lessons, shared by the lesson list,
/// the lesson and its quiz so a lesson always looks the same.
(IconData, Color) lessonLook(int lessonId) {
  const looks = <(IconData, Color)>[
    (Icons.home_work_rounded, AppColors.primary), // 1. Barn preparation
    (Icons.egg_alt_rounded, AppColors.gold), // 2. First 3 days
    (Icons.air_rounded, AppColors.info), // 3. Temperature & ventilation
    (Icons.grain_rounded, AppColors.sun), // 4. Feeding phases
    (Icons.local_hospital_rounded, AppColors.danger), // 5. Disease & the vet
  ];
  return looks[(lessonId - 1) % looks.length];
}
