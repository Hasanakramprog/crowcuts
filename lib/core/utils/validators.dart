import 'package:flutter/material.dart';

/// Input validation helpers.
class Validators {
  /// Validate email address.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate phone number.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Allow various formats: +1 (555) 123-4567, 555-123-4567, etc.
    final phoneRegex = RegExp(r'^[\+\d\s\-\(\)]{7,20}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validate password.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate name.
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validate required field.
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate positive price.
  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }
    final price = double.tryParse(value.trim());
    if (price == null || price < 0) {
      return 'Please enter a valid price';
    }
    return null;
  }

  /// Validate duration in minutes.
  static String? duration(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Duration is required';
    }
    final duration = int.tryParse(value.trim());
    if (duration == null || duration < 5 || duration > 480) {
      return 'Duration must be 5-480 minutes';
    }
    return null;
  }
}
