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
import 'dart:math' as math;

class SecondUploadScreen extends StatefulWidget {
  const SecondUploadScreen({Key? key}) : super(key: key);

  @override
  State<SecondUploadScreen> createState() => _SecondUploadScreenState();
}

class _SecondUploadScreenState extends State<SecondUploadScreen>
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
  late AnimationController _pulseController;

  // Complex Animations
  late Animation<double> _heroAnimation;
  late Animation<double> _cardFloatAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
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
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Hero entrance animation
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Card floating animation
    _cardController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    // Button interaction animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    // Pulse animation for image picker
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Hero animation with bounce
    _heroAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: Curves.bounceOut,
    ));

    // Card floating animation
    _cardFloatAnimation = Tween<double>(
      begin: -12.0,
      end: 12.0,
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
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Dynamic gradient colors (different from first screen)
    _gradientAnimation1 = ColorTween(
      begin: const Color(0xFF8EC5FC),
      end: const Color(0xFFE0C3FC),
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _gradientAnimation2 = ColorTween(
      begin: const Color(0xFF96E6A1),
      end: const Color(0xFFD4FC79),
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _gradientAnimation3 = ColorTween(
      begin: const Color(0xFFFFA8D8),
      end: const Color(0xFFFFD93D),
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
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
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedImage != null) {
        setState(() {
          _selectedImage = File(pickedImage.path);
        });
        
        _showSuccessSnackBar("✨ Image selected successfully!");
      }
    } catch (e) {
      _showErrorSnackBar("Error selecting image: $e");
    } finally {
      _isPickingImage = false;
    }
  }

  Future<void> _onNext() async {
    if (_selectedImage == null) {
      _showErrorSnackBar("Please select an image first");
      return;
    }
    if (_selectedAge == null) {
      _showErrorSnackBar("Please select the child's age");
      return;
    }
    if (_selectedGender == null) {
      _showErrorSnackBar("Please select the child's gender");
      return;
    }
    if (globals.globalUserId == null) {
      _showErrorSnackBar("Session expired. Please login again.");
      return;
    }

    setState(() {
      _isUploading = true;
    });

    _buttonController.forward();

    try {
      int ageNumber = int.tryParse(_selectedAge!.split(' ')[0]) ?? 0;

      final response = await ApiService.detectAndSave(
        imageFile: _selectedImage!,
        userId: globals.globalUserId.toString(),
        age: ageNumber,
        gender: _selectedGender!,
      );

      _showSuccessSnackBar(
        "🎉 Analysis complete: ${response.predictedLabel} (${(response.confidence * 100).toStringAsFixed(1)}% confidence)",
      );

      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ProgressSummaryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } catch (e) {
      _showErrorSnackBar("Analysis failed: $e");
    } finally {
      setState(() {
        _isUploading = false;
      });
      _buttonController.reverse();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
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
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color.lerp(_gradientAnimation1.value, _gradientAnimation3.value, 
                    0.6 + 0.3 * math.sin(_backgroundController.value * 2.5 * math.pi))!,
                  Color.lerp(_gradientAnimation2.value, _gradientAnimation1.value,
                    0.8 + 0.2 * math.cos(_backgroundController.value * 2 * math.pi))!,
                  Color.lerp(_gradientAnimation3.value, _gradientAnimation2.value,
                    0.5 + 0.4 * math.sin(_backgroundController.value * 1.8 * math.pi))!,
                  const Color(0xFF2D1B69),
                ],
                stops: const [0.0, 0.35, 0.75, 1.0],
              ),
            ),
            child: Stack(
              children: [
                _buildFloatingParticles(),
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
                          begin: const Offset(0, 0.4),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _heroController,
                          curve: Curves.easeOutCubic,
                        )),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            _buildSpectacularHeader(isMobile, isTablet),
                            const SizedBox(height: 40),
                            _buildSectionTitle("📸 Upload Photo", isMobile, isTablet),
                            const SizedBox(height: 16),
                            _buildEnchantedImagePicker(isMobile, isTablet),
                            const SizedBox(height: 40),
                            _buildSectionTitle("👶 Child Information", isMobile, isTablet),
                            const SizedBox(height: 20),
                            _buildMagicalFormSection(isMobile, isTablet),
                            const SizedBox(height: 50),
                            _buildAnalysisButton(isMobile, isTablet),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(_glowAnimation.value * 0.4),
                  blurRadius: 25,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Text(
              "🎯 Behavioral Analysis",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: isMobile ? 16 : 20,
                letterSpacing: 0.8,
                shadows: [
                  Shadow(
                    color: Colors.white.withOpacity(0.6),
                    blurRadius: 12,
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 2,
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

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return Stack(
          children: List.generate(20, (index) {
            final delay = index * 0.08;
            final animationValue = (_particleAnimation.value + delay) % 1.0;
            final size = MediaQuery.of(context).size;
            
            return Positioned(
              left: (index * 0.12 * size.width + animationValue * 120) % size.width,
              top: (index * 0.18 * size.height + animationValue * 250) % size.height,
              child: Container(
                width: 3 + (index % 4) * 2,
                height: 3 + (index % 4) * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.6),
                      blurRadius: 8,
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

  Widget _buildSpectacularHeader(bool isMobile, bool isTablet) {
    return AnimatedBuilder(
      animation: _cardFloatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cardFloatAnimation.value),
          child: Container(
            padding: EdgeInsets.all(isTablet ? 36 : (isMobile ? 28 : 32)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 35,
                  spreadRadius: 8,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(_glowAnimation.value * 0.25),
                  blurRadius: 45,
                  spreadRadius: 12,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 28 : 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8EC5FC).withOpacity(0.6),
                        blurRadius: 25,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: isTablet ? 48 : (isMobile ? 36 : 42),
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: isTablet ? 28 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "🔮 Magical Analysis",
                        style: TextStyle(
                          fontSize: isTablet ? 24 : (isMobile ? 20 : 22),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.6,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isTablet ? 12 : 8),
                      Text(
                        "Predict your child's progress over the next 6 weeks with AI-powered insights",
                        style: TextStyle(
                          fontSize: isTablet ? 16 : (isMobile ? 14 : 15),
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isMobile, bool isTablet) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 20,
            vertical: isTablet ? 16 : 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(_glowAnimation.value * 0.2),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 22 : (isMobile ? 18 : 20),
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnchantedImagePicker(bool isMobile, bool isTablet) {
    return AnimatedBuilder(
      animation: Listenable.merge([_cardFloatAnimation, _pulseAnimation]),
      builder: (context, child) {
        // Calculate a responsive height that adapts to screen size
        final screenHeight = MediaQuery.of(context).size.height;
        final containerHeight = isTablet 
            ? screenHeight * 0.35 
            : (isMobile ? screenHeight * 0.28 : screenHeight * 0.32);
            
        return Transform.translate(
          offset: Offset(0, -_cardFloatAnimation.value * 0.6),
          child: Transform.scale(
            scale: _selectedImage == null ? _pulseAnimation.value : 1.0,
            child: GestureDetector(
              onTap: _pickImage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                // Use the responsive height instead of fixed values
                height: containerHeight,
                constraints: BoxConstraints(
                  // Add constraints to prevent overflow
                  maxHeight: screenHeight * 0.4,
                  minHeight: 200,
                ),
                decoration: BoxDecoration(
                  gradient: _selectedImage == null
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.25),
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.08),
                          ],
                        )
                      : null,
                  color: _selectedImage != null ? Colors.white.withOpacity(0.12) : null,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: _selectedImage == null 
                      ? Colors.white.withOpacity(0.5)
                      : const Color(0xFF96E6A1),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _selectedImage == null
                          ? Colors.white.withOpacity(_glowAnimation.value * 0.4)
                          : const Color(0xFF96E6A1).withOpacity(0.6),
                      blurRadius: 35,
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 25,
                      spreadRadius: 3,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: _selectedImage == null
                      ? _buildEnchantedPlaceholder(isMobile, isTablet)
                      : _buildSelectedImageDisplay(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnchantedPlaceholder(bool isMobile, bool isTablet) {
    // Use more adaptive spacing that will shrink on smaller screens
    final verticalSpacing = isTablet ? 22.0 : (isMobile ? 14.0 : 16.0);
    
    return Center(
      child: SingleChildScrollView( // Wrap in SingleChildScrollView for extra safety
        physics: NeverScrollableScrollPhysics(), // Only allows scrolling if needed
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isTablet ? 16.0 : 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Use min to take only needed space
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    // Reduce padding for smaller screens
                    padding: EdgeInsets.all(isTablet ? 28 : (isMobile ? 20 : 24)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.35),
                          Colors.white.withOpacity(0.15),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(_glowAnimation.value * 0.7),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      // Adjust icon size for better fit
                      size: isTablet ? 70 : (isMobile ? 50 : 58),
                      color: Colors.white,
                    ),
                  );
                },
              ),
              SizedBox(height: verticalSpacing),
              Text(
                _isPickingImage ? "✨ Selecting Magic..." : "🌟 Upload Child's Photo",
                style: TextStyle(
                  color: Colors.white,
                  // Reduce font sizes
                  fontSize: isTablet ? 22 : (isMobile ? 18 : 20),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              SizedBox(height: verticalSpacing * 0.5), // Smaller spacing here
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 16.0 : 12.0),
                child: Text(
                  "Tap to select a clear, recent photo for magical analysis",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: isTablet ? 16 : (isMobile ? 14 : 15),
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: verticalSpacing * 0.6), // Even smaller spacing
              // This section can be conditionally rendered if space allows
              if (!isMobile || MediaQuery.of(context).size.height > 600)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16 : 12,
                    vertical: isTablet ? 10 : 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: isTablet ? 18 : 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: isTablet ? 10 : 8),
                      Text(
                        "Best quality photos work better",
                        style: TextStyle(
                          fontSize: isTablet ? 14 : (isMobile ? 12 : 13),
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
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
                Colors.black.withOpacity(0.4),
              ],
            ),
          ),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF96E6A1), Color(0xFFD4FC79)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF96E6A1).withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Perfect Shot!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMagicalFormSection(bool isMobile, bool isTablet) {
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
        SizedBox(height: isTablet ? 32 : 28),
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
          offset: Offset(0, _cardFloatAnimation.value * 0.4),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: value != null 
                  ? const Color(0xFF8EC5FC).withOpacity(0.8)
                  : Colors.white.withOpacity(0.5),
                width: value != null ? 2.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: value != null
                      ? const Color(0xFF8EC5FC).withOpacity(0.5)
                      : Colors.white.withOpacity(_glowAnimation.value * 0.25),
                  blurRadius: 25,
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: value == null ? label : null,
                labelStyle: TextStyle(
                  fontSize: isTablet ? 20 : (isMobile ? 18 : 19),
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.w700,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(16),
                  padding: EdgeInsets.all(isTablet ? 16 : 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8EC5FC).withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isTablet ? 28 : 24,
                  ),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none, // Override blue focus border
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: isTablet ? 28 : 24,
                ),
                // Add a hint to indicate selection is needed
                hintText: value == null ? 'Select ${label.split(' ').last}' : null,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: isTablet ? 18 : (isMobile ? 16 : 17),
                ),
                focusColor: Colors.transparent,
              ),
              value: value,
              dropdownColor: Colors.white.withOpacity(0.95),
              style: TextStyle(
                color: const Color(0xFF2D1B69),
                fontSize: isTablet ? 20 : (isMobile ? 18 : 19),
                fontWeight: FontWeight.w700,
              ),
              selectedItemBuilder: (BuildContext context) {
                return items.map<Widget>((String item) {
                  return Row(
                    children: [
                      // Icon to indicate selected item
                      if (value != null) ...[
                        Container(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(
                            label.split(' ')[0] + " ", // Just the emoji part
                            style: TextStyle(
                              fontSize: isTablet ? 20 : (isMobile ? 18 : 19),
                            ),
                          ),
                        ),
                      ],
                      Text(
                        item,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 20 : (isMobile ? 18 : 19),
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
                        ? const Color(0xFF8EC5FC).withOpacity(0.2)
                        : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Visual indicator for selected item
                        if (value == item)
                          Container(
                            margin: EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.check_circle,
                              color: const Color(0xFF8EC5FC),
                              size: isTablet ? 24 : 20,
                            ),
                          ),
                        Text(
                          item,
                          style: TextStyle(
                            color: value == item 
                              ? const Color(0xFF8EC5FC)
                              : const Color(0xFF2D1B69),
                            fontSize: isTablet ? 19 : (isMobile ? 17 : 18),
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
                width: isTablet ? 44 : 38,
                height: isTablet ? 44 : 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center, // Ensures perfect centering
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: isTablet ? 30 : 26,
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

  Widget _buildAnalysisButton(bool isMobile, bool isTablet) {
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
              duration: const Duration(milliseconds: 400),
              width: double.infinity,
              height: isTablet ? 80 : (isMobile ? 64 : 72),
              decoration: BoxDecoration(
                gradient: canProceed
                    ? const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFF8EC5FC),
                          Color(0xFFE0C3FC),
                          Color(0xFFFFA8D8),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.grey.shade600,
                          Colors.grey.shade700,
                        ],
                      ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: canProceed ? [
                  BoxShadow(
                    color: const Color(0xFF8EC5FC).withOpacity(0.7),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(_glowAnimation.value * 0.5),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ] : [],
              ),
              child: Center(
                child: _isUploading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 20),
                          Text(
                            "🔮 ANALYZING MAGIC...",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 22 : (isMobile ? 18 : 20),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.8,
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
                              fontSize: isTablet ? 24 : (isMobile ? 20 : 22),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.8,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: isTablet ? 32 : 28,
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
