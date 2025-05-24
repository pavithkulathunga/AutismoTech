// lib/screens/upload_screen.dart
import 'dart:io';
import 'package:autismotech_app/screens/apiservice.dart';
import 'package:autismotech_app/screens/uploadsecound.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:autismotech_app/constants/theme.dart';
import 'package:autismotech_app/constants/colors.dart';
import 'package:autismotech_app/screens/global.dart' as globals;
import 'dart:math' as math;

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with TickerProviderStateMixin {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  String? _selectedAge;
  String? _selectedGender;
  bool _isPickingImage = false;

  // Animation controllers
  late AnimationController _backgroundController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _scaleController;

  // Animations
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Background gradient animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Floating animation for cards
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Pulse animation for interactive elements
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Scale animation for buttons
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error picking image: $e"),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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

    // Show a loading indicator while sending the request
    _showLoadingDialog();

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

      // Navigate to SecondUploadScreen after success
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const SecondUploadScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
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
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
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
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Uploading...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final horizontalPadding = isSmallScreen ? 16.0 : size.width * 0.1;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Behavioral Progress Prediction",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    AppColors.primaryColor,
                    AppColors.accent1,
                    0.3 + 0.2 * math.sin(_backgroundController.value * 2 * math.pi),
                  )!,
                  Color.lerp(
                    AppColors.background,
                    AppColors.Progress,
                    0.5 + 0.3 * math.cos(_backgroundController.value * 2 * math.pi),
                  )!,
                  Color.lerp(
                    AppColors.Emotion,
                    AppColors.Music,
                    0.4 + 0.2 * math.sin(_backgroundController.value * 3 * math.pi),
                  )!,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20),
                    _buildHeaderSection(isSmallScreen),
                    SizedBox(height: 30),
                    _buildImagePickerCard(isSmallScreen),
                    SizedBox(height: 24),
                    _buildFormSection(isSmallScreen),
                    SizedBox(height: 32),
                    _buildNextButton(isSmallScreen),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(bool isSmallScreen) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  size: isSmallScreen ? 48 : 64,
                  color: Colors.white,
                ),
                SizedBox(height: 16),
                Text(
                  "We need some information to predict the progress of an autistic child",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePickerCard(bool isSmallScreen) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _selectedImage == null ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: _pickImage,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: isSmallScreen ? 200 : 250,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedImage == null 
                    ? Colors.white.withOpacity(0.5)
                    : AppColors.accent2,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _selectedImage == null
                    ? _buildImagePlaceholder(isSmallScreen)
                    : _buildSelectedImage(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePlaceholder(bool isSmallScreen) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.add_photo_alternate_outlined,
              size: isSmallScreen ? 48 : 64,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Text(
            "Tap to add image",
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Select a clear photo for better analysis",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImage() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          child: Image.file(
            _selectedImage!,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  "Selected",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection(bool isSmallScreen) {
    return Column(
      children: [
        _buildDropdownField(
          label: "Age",
          value: _selectedAge,
          items: ["2 years", "3 years", "4 years", "5 years", "6 years"],
          onChanged: (value) => setState(() => _selectedAge = value),
          icon: Icons.cake_outlined,
          isSmallScreen: isSmallScreen,
        ),
        SizedBox(height: 20),
        _buildDropdownField(
          label: "Gender",
          value: _selectedGender,
          items: ["Male", "Female"],
          onChanged: (value) => setState(() => _selectedGender = value),
          icon: Icons.person_outline,
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
    required bool isSmallScreen,
  }) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value * 0.5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  icon,
                  color: Colors.white.withOpacity(0.8),
                  size: isSmallScreen ? 20 : 24,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isSmallScreen ? 16 : 20,
                ),
              ),
              value: value,
              dropdownColor: AppColors.darkBlue.withOpacity(0.95),
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w500,
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNextButton(bool isSmallScreen) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _scaleController.forward(),
            onTapUp: (_) => _scaleController.reverse(),
            onTapCancel: () => _scaleController.reverse(),
            onTap: _onNext,
            child: Container(
              width: double.infinity,
              height: isSmallScreen ? 56 : 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent1,
                    AppColors.accent2,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent1.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "NEXT",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: isSmallScreen ? 20 : 24,
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
}
