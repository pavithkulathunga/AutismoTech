// lib/screens/second_upload_screen.dart
import 'dart:io';
import 'package:autismotech_app/screens/ProgressSummaryScreen.dart';
import 'package:autismotech_app/screens/SummaryScreen.dart' as summary;
import 'package:autismotech_app/screens/SummaryScreen.dart';
import 'package:autismotech_app/screens/apiservice.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:autismotech_app/constants/theme.dart';
import 'package:autismotech_app/constants/colors.dart';
import 'package:autismotech_app/screens/global.dart' as globals;
// Import SummaryScreen

class SecondUploadScreen extends StatefulWidget {
  const SecondUploadScreen({Key? key}) : super(key: key);

  @override
  State<SecondUploadScreen> createState() => _SecondUploadScreenState();
}

class _SecondUploadScreenState extends State<SecondUploadScreen>
    with TickerProviderStateMixin {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Dropdown values stored as strings (e.g., "24 months")
  String? _selectedAge;
  String? _selectedGender;

  bool _isPickingImage = false; // Prevents multiple concurrent pick operations

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    if (_isPickingImage) return; // Prevent reentrancy
    _isPickingImage = true;
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (pickedImage != null) {
        setState(() {
          _selectedImage = File(pickedImage.path);
        });
        // Add a small scale animation when image is selected
        _scaleController.reset();
        _scaleController.forward();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error picking image: $e")));
    } finally {
      _isPickingImage = false;
    }
  }

  // Function to handle "NEXT" button press
  Future<void> _onNext() async {
    // Validate that an image and all dropdowns are selected
    if (_selectedImage == null) {
      _showErrorSnackBar("Please select an image.");
      return;
    }
    if (_selectedAge == null) {
      _showErrorSnackBar("Please select an age.");
      return;
    }
    if (_selectedGender == null) {
      _showErrorSnackBar("Please select a gender.");
      return;
    }
    // Ensure the user is logged in (globalUserId is set)
    if (globals.globalUserId == null) {
      _showErrorSnackBar("User not logged in.");
      return;
    }

    // Extract numeric part from age string (e.g., "24 months" -> 24)
    int ageNumber = int.tryParse(_selectedAge!.split(' ')[0]) ?? 0;

    // Show a modern loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildLoadingDialog(),
    );

    try {
      // Call the API service method to upload the image and form details
      final response = await ApiService.detectAndSave(
        imageFile: _selectedImage!,
        userId: globals.globalUserId.toString(),
        age: ageNumber,
        gender: _selectedGender!,
      );

      Navigator.of(context).pop(); // Dismiss the loading indicator

      print(
        "Upload successful: Predicted Label: ${response.predictedLabel}, Confidence: ${response.confidence}",
      );
      _showSuccessSnackBar(
        "Upload successful: ${response.predictedLabel} (${(response.confidence * 100).toStringAsFixed(1)}%)",
      );

      // Navigate to SummaryScreen after success
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProgressSummaryScreen()),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss the loading indicator
      print("Upload error: $e");
      _showErrorSnackBar("Upload failed: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildLoadingDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.7)],
                ),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Processing...",
              style: textStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Analyzing your data",
              style: textStyle.copyWith(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: _pickImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: MediaQuery.of(context).size.width * 0.5,
              decoration: BoxDecoration(
                gradient: _selectedImage == null
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.secondaryColor.withOpacity(0.3),
                          AppColors.primaryColor.withOpacity(0.1),
                        ],
                      )
                    : null,
                color: _selectedImage != null ? Colors.grey.shade100 : null,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedImage != null 
                      ? AppColors.primaryColor.withOpacity(0.3)
                      : AppColors.borderColor.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.7)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Tap to add image",
                          style: textStyle.copyWith(
                            color: AppColors.darkBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Upload a clear photo",
                          style: textStyle.copyWith(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: textStyle.copyWith(
            fontSize: 16,
            color: AppColors.darkBlue,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: AppColors.primaryColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        value: value,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: textStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? screenWidth * 0.1 : 16.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Behavioural Progress Prediction",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor,
                AppColors.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24,
            ),
            child: Column(
              children: [
                // Intro card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        AppColors.primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.psychology_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "We need some information to predict the progress of an autistic kid after 1 and half months.",
                          style: textStyle.copyWith(
                            fontSize: isTablet ? 20 : 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkBlue,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Image picker
                _buildImagePicker(),
                const SizedBox(height: 24),
                
                // Age Dropdown
                _buildDropdown(
                  label: "Age",
                  value: _selectedAge,
                  items: ["2 years", "3 years", "4 years", "5 years", "6 years"],
                  onChanged: (value) {
                    setState(() {
                      _selectedAge = value;
                    });
                  },
                  icon: Icons.cake_outlined,
                ),
                const SizedBox(height: 20),
                
                // Gender Dropdown
                _buildDropdown(
                  label: "Gender",
                  value: _selectedGender,
                  items: ["Male", "Female"],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 32),
                
                // NEXT Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "NEXT",
                          style: textStyle.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
