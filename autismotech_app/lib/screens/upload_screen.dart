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
  bool _isUploading = false;

  // Advanced Animation Controllers
  late AnimationController _backgroundController;
  late AnimationController _heroController;
  late AnimationController _cardController;
  late AnimationController _buttonController;
  late AnimationController _particleController;
  late AnimationController _glowController;

  // Complex Animations
  late Animation<double> _heroAnimation;
  late Animation<double> _cardFloatAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Color?> _gradientAnimation1;
  late Animation<Color?> _gradientAnimation2;
  late Animation<Color?> _gradientAnimation3;

  @override
  void initState() {
    super.initState();
    _initializeAdvancedAnimations();
    _startAnimationSequence();
  }

  void _initializeAdvancedAnimations() {
    // Background gradient animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    // Hero entrance animation
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Card floating animation
    _cardController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    // Button interaction animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Hero animation with elastic curve
    _heroAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: Curves.elasticOut,
    ));

    // Card floating animation
    _cardFloatAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeInOut,
    ));

    // Button scale animation
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));

    // Particle animation
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    ));

    // Glow animation
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Dynamic gradient colors
    _gradientAnimation1 = ColorTween(
      begin: const Color(0xFF667eea),
      end: const Color(0xFF764ba2),
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _gradientAnimation2 = ColorTween(
      begin: const Color(0xFFf093fb),
      end: const Color(0xFFf5576c),
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _gradientAnimation3 = ColorTween(
      begin: const Color(0xFF4facfe),
      end: const Color(0xFF00f2fe),
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _heroController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _heroController.dispose();
    _cardController.dispose();
    _buttonController.dispose();
    _particleController.dispose();
    _glowController.dispose();
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
    final isTablet = size.width > 768;
    final isMobile = size.width < 600;
    final horizontalPadding = isTablet ? size.width * 0.15 : (isMobile ? 16.0 : 24.0);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildMagicalAppBar(isMobile),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _backgroundController,
          _heroAnimation,
          _cardFloatAnimation,
          _particleAnimation,
          _glowAnimation,
        ]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(_gradientAnimation1.value, _gradientAnimation3.value, 
                    0.5 + 0.3 * math.sin(_backgroundController.value * 2 * math.pi))!,
                  Color.lerp(_gradientAnimation2.value, _gradientAnimation1.value,
                    0.7 + 0.2 * math.cos(_backgroundController.value * 3 * math.pi))!,
                  Color.lerp(_gradientAnimation3.value, _gradientAnimation2.value,
                    0.4 + 0.4 * math.sin(_backgroundController.value * 1.5 * math.pi))!,
                  const Color(0xFF1a1a2e),
                ],
                stops: const [0.0, 0.4, 0.8, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Animated particles background
                _buildParticleBackground(),
                // Main content
                SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 20,
                    ),
                    child: FadeTransition(
                      opacity: _heroAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _heroController,
                          curve: Curves.easeOutCubic,
                        )),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            _buildGlowingHeader(isMobile, isTablet),
                            const SizedBox(height: 40),
                            _buildMagicalImagePicker(isMobile, isTablet),
                            const SizedBox(height: 32),
                            _buildEnchantedFormSection(isMobile, isTablet),
                            const SizedBox(height: 40),
                            _buildSpectacularButton(isMobile, isTablet),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildMagicalAppBar(bool isMobile) {
    return AppBar(
      title: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(_glowAnimation.value * 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              "✨ Autism Progress Prediction",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: isMobile ? 16 : 20,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0x40ffffff), Color(0x20ffffff)],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
    );
  }

  Widget _buildParticleBackground() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return Stack(
          children: List.generate(15, (index) {
            final delay = index * 0.1;
            final animationValue = (_particleAnimation.value + delay) % 1.0;
            final size = MediaQuery.of(context).size;
            
            return Positioned(
              left: (index * 0.1 * size.width + animationValue * 100) % size.width,
              top: (index * 0.15 * size.height + animationValue * 200) % size.height,
              child: Container(
                width: 4 + (index % 3) * 2,
                height: 4 + (index % 3) * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.8),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildGlowingHeader(bool isMobile, bool isTablet) {
    return AnimatedBuilder(
      animation: _cardFloatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cardFloatAnimation.value),
          child: Container(
            padding: EdgeInsets.all(isTablet ? 32 : (isMobile ? 24 : 28)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(_glowAnimation.value * 0.2),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFFf093fb)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.psychology_outlined,
                    size: isTablet ? 64 : (isMobile ? 48 : 56),
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isTablet ? 24 : 20),
                Text(
                  "🧠 AI-Powered Analysis",
                  style: TextStyle(
                    fontSize: isTablet ? 28 : (isMobile ? 22 : 26),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isTablet ? 16 : 12),
                Text(
                  "Help us understand your child's unique journey with advanced behavioral analysis and personalized insights",
                  style: TextStyle(
                    fontSize: isTablet ? 18 : (isMobile ? 16 : 17),
                    color: Colors.white.withOpacity(0.9),
                    height: 1.6,
                    letterSpacing: 0.3,
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

  Widget _buildMagicalImagePicker(bool isMobile, bool isTablet) {
    return AnimatedBuilder(
      animation: _cardFloatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_cardFloatAnimation.value * 0.5),
          child: GestureDetector(
            onTap: _pickImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              height: isTablet ? 320 : (isMobile ? 240 : 280),
              decoration: BoxDecoration(
                gradient: _selectedImage == null
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                      )
                    : null,
                color: _selectedImage != null ? Colors.white.withOpacity(0.1) : null,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _selectedImage == null 
                    ? Colors.white.withOpacity(0.4)
                    : const Color(0xFF4facfe),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _selectedImage == null
                        ? Colors.white.withOpacity(_glowAnimation.value * 0.3)
                        : const Color(0xFF4facfe).withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: _selectedImage == null
                    ? _buildMagicalPlaceholder(isMobile, isTablet)
                    : _buildSelectedImageDisplay(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMagicalPlaceholder(bool isMobile, bool isTablet) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                padding: EdgeInsets.all(isTablet ? 28 : 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(_glowAnimation.value * 0.6),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  size: isTablet ? 72 : (isMobile ? 56 : 64),
                  color: Colors.white,
                ),
              );
            },
          ),
          SizedBox(height: isTablet ? 24 : 20),
          Text(
            _isPickingImage ? "✨ Selecting Magic..." : "📸 Tap to Upload Photo",
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 22 : (isMobile ? 18 : 20),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          SizedBox(height: isTablet ? 12 : 10),
          Text(
            "Choose a clear, well-lit photo for the most accurate analysis",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: isTablet ? 16 : (isMobile ? 14 : 15),
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImageDisplay() {
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
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.3),
              ],
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4facfe).withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  "Perfect!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnchantedFormSection(bool isMobile, bool isTablet) {
    return Column(
      children: [
        _buildGlowingDropdown(
          label: "🎂 Child's Age",
          value: _selectedAge,
          items: const ["2 years", "3 years", "4 years", "5 years", "6 years"],
          onChanged: (value) => setState(() => _selectedAge = value),
          icon: Icons.cake_outlined,
          isMobile: isMobile,
          isTablet: isTablet,
        ),
        SizedBox(height: isTablet ? 28 : 24),
        _buildGlowingDropdown(
          label: "👤 Gender",
          value: _selectedGender,
          items: const ["Male", "Female"],
          onChanged: (value) => setState(() => _selectedGender = value),
          icon: Icons.person_outline,
          isMobile: isMobile,
          isTablet: isTablet,
        ),
      ],
    );
  }

  Widget _buildGlowingDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
    required bool isMobile,
    required bool isTablet,
  }) {
    return AnimatedBuilder(
      animation: _cardFloatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cardFloatAnimation.value * 0.3),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: value != null 
                  ? const Color(0xFF667eea).withOpacity(0.8)
                  : Colors.white.withOpacity(0.4),
                width: value != null ? 2.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: value != null
                      ? const Color(0xFF667eea).withOpacity(0.4)
                      : Colors.white.withOpacity(_glowAnimation.value * 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: value == null ? label : null,
                labelStyle: TextStyle(
                  fontSize: isTablet ? 18 : (isMobile ? 16 : 17),
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFFf093fb)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isTablet ? 24 : 20,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: isTablet ? 24 : 20,
                ),
                // Add a hint to indicate selection is needed
                hintText: value == null ? 'Select ${label.split(' ').last}' : null,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: isTablet ? 16 : (isMobile ? 14 : 15),
                ),
              ),
              value: value,
              // Change to a lighter color with less opacity for better readability
              dropdownColor: Colors.white.withOpacity(0.95),
              style: TextStyle(
                color: const Color(0xFF1a1a2e),
                fontSize: isTablet ? 18 : (isMobile ? 16 : 17),
                fontWeight: FontWeight.w700,
              ),
              selectedItemBuilder: (BuildContext context) {
                return items.map<Widget>((String item) {
                  return Row(
                    children: [
                      // Icon to indicate selected item
                      if (value != null) ...[
                        Container(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            label.split(' ')[0] + " ", // Just the emoji part
                            style: TextStyle(
                              fontSize: isTablet ? 18 : (isMobile ? 16 : 17),
                            ),
                          ),
                        ),
                      ],
                      Text(
                        item,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 18 : (isMobile ? 16 : 17),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: value == item 
                        ? const Color(0xFF667eea).withOpacity(0.2)
                        : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        // Visual indicator for selected item
                        if (value == item)
                          Container(
                            margin: EdgeInsets.only(right: 10),
                            child: Icon(
                              Icons.check_circle,
                              color: const Color(0xFF667eea),
                              size: isTablet ? 22 : 18,
                            ),
                          ),
                        Text(
                          item,
                          style: TextStyle(
                            color: value == item 
                              ? const Color(0xFF667eea)
                              : const Color(0xFF1a1a2e),
                            fontSize: isTablet ? 17 : (isMobile ? 15 : 16),
                            fontWeight: value == item ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              icon: Container(
                width: isTablet ? 40 : 36,
                height: isTablet ? 40 : 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center, // Ensures perfect centering
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: isTablet ? 28 : 24,
                ),
              ),
              elevation: 8,
              isExpanded: true,
              borderRadius: BorderRadius.circular(16),
              menuMaxHeight: 300,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpectacularButton(bool isMobile, bool isTablet) {
    final bool canProceed = _selectedImage != null && _selectedAge != null && _selectedGender != null;

    return AnimatedBuilder(
      animation: _buttonScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonScaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _buttonController.forward(),
            onTapUp: (_) => _buttonController.reverse(),
            onTapCancel: () => _buttonController.reverse(),
            onTap: canProceed && !_isUploading ? _onNext : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: isTablet ? 72 : (isMobile ? 60 : 64),
              decoration: BoxDecoration(
                gradient: canProceed
                    ? const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFF667eea),
                          Color(0xFFf093fb),
                          Color(0xFF4facfe),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.grey.shade600,
                          Colors.grey.shade700,
                        ],
                      ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: canProceed ? [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.6),
                    blurRadius: 25,
                    spreadRadius: 3,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(_glowAnimation.value * 0.4),
                    blurRadius: 35,
                    spreadRadius: 5,
                  ),
                ] : [],
              ),
              child: Center(
                child: _isUploading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            "✨ ANALYZING MAGIC...",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 20 : (isMobile ? 16 : 18),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "🚀 START ANALYSIS",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 22 : (isMobile ? 18 : 20),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: isTablet ? 28 : 24,
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
}
