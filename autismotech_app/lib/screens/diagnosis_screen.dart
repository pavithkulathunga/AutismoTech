import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final Map<String, int?> answers = {};
  XFile? _pickedImage;
  bool _isLoading = false;
  
  // Animation controllers
  late AnimationController _loadingController;
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late AnimationController _backgroundController;
  late AnimationController _slideController;
  
  // Animations
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Progress tracking
  int _completedQuestions = 0;
  double _progress = 0.0;
  
  // Confetti effect controls
  bool _showConfetti = false;
  
  // Background properties
  final List<Color> _gradientColors = [
    const Color(0xFF6AB7FF),
    const Color(0xFF4A66F5),
    const Color(0xFF39D8C9),
    const Color(0xFF32B4FF),
  ];
  int _currentGradient = 0;
  
  // Animation for question selection
  int? _selectedQuestionIndex;

  @override
  void initState() {
    super.initState();
    
    // Main loading animation
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    // Pulse animation for UI elements
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );
    
    // Button bounce animation
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut)
    );
    
    // Background color animation
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _backgroundColorAnimation = ColorTween(
      begin: _gradientColors[0],
      end: _gradientColors[1],
    ).animate(_backgroundController);
    
    // Start periodic gradient changes
    _startGradientTransition();
    
    // Slide animation
    _slideController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 500),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0), 
      end: Offset.zero
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideController.forward();
    
    // Add haptic feedback for interactions
    HapticFeedback.lightImpact();
  }
  
  void _startGradientTransition() {
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _currentGradient = (_currentGradient + 1) % _gradientColors.length;
        });
        _startGradientTransition();
      }
    });
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    _backgroundController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> questions = [
    {
      "question": "Does your child look at you when you call his/her name?",
      "field": "feature1",
      "icon": Icons.visibility,
    },
    {
      "question": "Is it easy for you to get eye contact with your child?",
      "field": "feature2",
      "icon": Icons.remove_red_eye,
    },
    {
      "question": "Does your child point to indicate that he/she wants something?",
      "field": "feature3",
      "icon": Icons.back_hand,
    },
    {
      "question": "Does your child point to share interest with you?",
      "field": "feature4",
      "icon": Icons.interests,
    },
    {
      "question": "Does your child pretend? (e.g., care for dolls, talk on a toy phone)",
      "field": "feature5",
      "icon": Icons.toys,
    },
    {
      "question": "Does your child follow where you're looking?",
      "field": "feature6",
      "icon": Icons.visibility,
    },
    {
      "question": "If someone is upset, does your child try to comfort them?",
      "field": "feature7",
      "icon": Icons.emoji_emotions,
    },
    {
      "question": "Would you describe your child's first words as unusual?",
      "field": "feature8",
      "icon": Icons.record_voice_over,
    },
    {
      "question": "Does your child use simple gestures?",
      "field": "feature9",
      "icon": Icons.waving_hand,
    },
    {
      "question": "Does your child stare at nothing with no apparent purpose?",
      "field": "feature10",
      "icon": Icons.remove_red_eye_outlined,
    },
    {
      "question": "Sex of the child",
      "field": "feature11",
      "icon": Icons.people,
    },
    {
      "question": "Family member suffering from ASD?",
      "field": "feature12",
      "icon": Icons.family_restroom,
    },
  ];

  Future<void> _pickImage() async {
    // Trigger bounce animation
    _bounceController.forward().then((_) => _bounceController.reverse());
    
    // Add haptic feedback
    HapticFeedback.mediumImpact();
    
    final picker = ImagePicker();
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween<double>(begin: 0.8, end: 1.0),
          curve: Curves.easeOutQuint,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6AB7FF).withOpacity(0.9),
                  const Color(0xFF4A66F5).withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Image Source',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 24),
                _buildEnhancedImageSourceOption(
                  context,
                  'Camera',
                  Icons.camera_alt_rounded,
                  ImageSource.camera,
                ),
                const SizedBox(height: 16),
                _buildEnhancedImageSourceOption(
                  context,
                  'Gallery',
                  Icons.photo_library_rounded,
                  ImageSource.gallery,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (source != null) {
      final picked = await picker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          _pickedImage = picked;
          // Add celebration effect when image is picked
          _updateProgress();
        });
      }
    }
  }

  Widget _buildEnhancedImageSourceOption(
    BuildContext context,
    String title,
    IconData icon,
    ImageSource source,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop(source);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool validateForm() {
    return answers.length == questions.length && _pickedImage != null;
  }

  void _updateProgress() {
    setState(() {
      _completedQuestions = answers.length;
      _progress = (_completedQuestions + (_pickedImage != null ? 1 : 0)) / (questions.length + 1);
      
      // Show confetti when all questions are answered
      if (_progress > 0.95) {
        _showConfetti = true;
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _submit() async {
    if (!validateForm()) {
      _showEnhancedErrorSnackBar('Please answer all questions and upload an image.');
      return;
    }

    // Add haptic feedback before submission
    HapticFeedback.heavyImpact();
    
    // Button animation
    _bounceController.forward().then((_) => _bounceController.reverse());
    
    setState(() => _isLoading = true);

    final uri = Uri.parse(
      'http://192.168.1.5:5000/asd_diagnose/predict',
    );
    final request = http.MultipartRequest("POST", uri);

    answers.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    request.files.add(
      await http.MultipartFile.fromPath('image', _pickedImage!.path),
    );

    try {
      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        try {
          final decoded = json.decode(resBody);
          final result = decoded['result'] ?? resBody;
          _showEnhancedResultDialog(result.toString());
        } catch (_) {
          _showEnhancedResultDialog(resBody);
        }
      } else {
        _showEnhancedErrorDialog(
            "Server responded with status ${response.statusCode}:\n$resBody");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showEnhancedErrorDialog("Submission failed:\n$e");
    }
  }

  void _showEnhancedErrorSnackBar(String message) {
    // Add haptic feedback for error
    HapticFeedback.vibrate();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween<double>(begin: 0.8, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showEnhancedResultDialog(String result) {
    // Add haptic feedback for success
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          tween: Tween<double>(begin: 0.7, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF39D8C9).withOpacity(0.95),
                  const Color(0xFF32B4FF).withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.psychology, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "Diagnosis Result",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    result,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.05),
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF32B4FF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                          shadowColor: Colors.black26,
                        ),
                        child: const Text(
                          "CLOSE",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEnhancedErrorDialog(String message) {
    // Add haptic feedback for error
    HapticFeedback.vibrate();
    
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween<double>(begin: 0.8, end: 1.0),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.redAccent.withOpacity(0.95),
                  Colors.red.shade800.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.error_outline, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "Error",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black26,
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOptions(String fieldName, Color textColor) {
    List<Widget> radios = [];

    if (fieldName == 'feature10') {
      radios = [
        _buildEnhancedRadio(fieldName, 'Always/Usually/Sometimes', 1, textColor),
        _buildEnhancedRadio(fieldName, 'Rarely/Never', 0, textColor),
      ];
    } else if (fieldName == 'feature11') {
      radios = [
        _buildEnhancedRadio(fieldName, 'Male', 1, textColor),
        _buildEnhancedRadio(fieldName, 'Female', 0, textColor),
      ];
    } else if (fieldName == 'feature12') {
      radios = [
        _buildEnhancedRadio(fieldName, 'Yes', 1, textColor),
        _buildEnhancedRadio(fieldName, 'No', 0, textColor),
      ];
    } else {
      radios = [
        _buildEnhancedRadio(fieldName, 'Always/Usually', 0, textColor),
        _buildEnhancedRadio(fieldName, 'Sometimes/Rarely/Never', 1, textColor),
      ];
    }

    return radios;
  }

  Widget _buildEnhancedRadio(
    String fieldName,
    String label,
    int value,
    Color textColor,
  ) {
    final isSelected = answers[fieldName] == value;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF39D8C9).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF39D8C9)
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: RadioListTile<int>(
          title: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF0287c3) : textColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 15,
            ),
          ),
          value: value,
          groupValue: answers[fieldName],
          onChanged: (val) {
            setState(() {
              answers[fieldName] = val;
              _updateProgress();
            });
            // Add haptic feedback
            HapticFeedback.selectionClick();
          },
          activeColor: const Color(0xFF39D8C9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
  
  // Confetti particles
  Widget _buildConfetti() {
    if (!_showConfetti) return const SizedBox();
    
    return IgnorePointer(
      child: Container(
        width: double.infinity,
        height: 400,
        child: CustomPaint(
          painter: ConfettiPainter(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF6FB),
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.05),
              child: const Text(
                'ASD Diagnosis',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            );
          },
        ),
        centerTitle: true,
        backgroundColor: _gradientColors[_currentGradient],
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _gradientColors[_currentGradient],
                _gradientColors[(_currentGradient + 1) % _gradientColors.length],
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stack(
            children: [
              // Animated background gradient
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _gradientColors[_currentGradient],
                      const Color(0xFFEEF6FB),
                    ],
                    stops: const [0.0, 0.3],
                  ),
                ),
              ),
              
              // Confetti overlay
              _buildConfetti(),
              
              // Main content
              SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Progress indicator
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Progress: ${(_progress * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '$_completedQuestions/${questions.length} questions',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              height: 10,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF39D8C9),
                                        const Color(0xFF32B4FF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF32B4FF).withOpacity(0.5),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 16, top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8), 
                            width: 1
                          ),
                        ),
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 1.0 + (_pulseController.value * 0.1),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Color(0xFF0287c3),
                                    size: 36,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Please answer all questions and upload a clear photo of the child for accurate diagnosis.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF444444),
                                fontSize: 16,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Questions
                      ...questions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final q = entry.value;
                        final isEven = index % 2 == 0;
                        final isSelected = _selectedQuestionIndex == index;

                        final bgColor = isEven 
                            ? const Color(0xFFFFFFFF) 
                            : const Color(0xFFF5F8FF);
                        final textColor = const Color(0xFF02557a);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedQuestionIndex = isSelected ? null : index;
                            });
                            HapticFeedback.selectionClick();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF0F8FF)
                                  : bgColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? const Color(0xFF32B4FF).withOpacity(0.2)
                                      : Colors.black.withOpacity(0.05),
                                  blurRadius: isSelected ? 12 : 8,
                                  spreadRadius: isSelected ? 1 : 0,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF32B4FF).withOpacity(0.5)
                                    : const Color(0xFFE0E0E0),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: ExpansionTile(
                                key: Key(q["field"]),
                                initiallyExpanded: answers.containsKey(q["field"]),
                                onExpansionChanged: (expanded) {
                                  if (expanded) {
                                    setState(() {
                                      _selectedQuestionIndex = index;
                                    });
                                    HapticFeedback.selectionClick();
                                  }
                                },
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 20, 
                                  vertical: 16
                                ),
                                childrenPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, 
                                  vertical: 8
                                ),
                                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                                leading: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: answers.containsKey(q["field"])
                                        ? const Color(0xFF39D8C9).withOpacity(0.2)
                                        : const Color(0xFFEDF6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    q["icon"] ?? Icons.help_outline,
                                    color: answers.containsKey(q["field"])
                                        ? const Color(0xFF39D8C9)
                                        : const Color(0xFF0287c3),
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  q["question"],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? const Color(0xFF0287c3)
                                        : textColor,
                                    fontSize: 16,
                                  ),
                                ),
                                trailing: answers.containsKey(q["field"])
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF39D8C9),
                                        size: 24,
                                      )
                                    : Icon(
                                        Icons.arrow_drop_down_circle,
                                        color: isSelected
                                            ? const Color(0xFF0287c3)
                                            : const Color(0xFF02557a).withOpacity(0.6),
                                      ),
                                iconColor: const Color(0xFF0287c3),
                                collapsedIconColor: const Color(0xFF02557a),
                                backgroundColor: bgColor,
                                collapsedBackgroundColor: bgColor,
                                children: _buildOptions(q["field"], textColor),
                              ),
                            ),
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 24),
                      
                      // Image upload section
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              const Color(0xFFF9FBFF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8), 
                            width: 1
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo_camera,
                                  color: const Color(0xFF0287c3),
                                  size: 26,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Upload Child's Photo",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF02557a),
                                    fontSize: 18,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.1),
                                        offset: const Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (_pickedImage != null)
                              AnimatedScale(
                                scale: 1.0,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutBack,
                                child: Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 8, right: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 12,
                                            spreadRadius: 3,
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.file(
                                          File(_pickedImage!.path),
                                          width: 250,
                                          height: 250,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _pickedImage = null;
                                          _updateProgress();
                                        });
                                        HapticFeedback.mediumImpact();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              AnimatedBuilder(
                                animation: _bounceController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _bounceAnimation.value,
                                    child: child,
                                  );
                                },
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F4F8),
                                      borderRadius: BorderRadius.circular(20),
                                      border: DashedBorder.all(
                                        color: const Color(0xFF35baf6).withOpacity(0.7),
                                        dashPattern: const [6, 3],
                                        strokeWidth: 2,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        AnimatedBuilder(
                                          animation: _pulseController,
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale: 1.0 + (_pulseController.value * 0.1),
                                              child: Icon(
                                                Icons.add_photo_alternate_rounded,
                                                size: 56,
                                                color: const Color(0xFF35baf6).withOpacity(0.8),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          "Tap to select a photo",
                                          style: TextStyle(
                                            color: Color(0xFF35baf6),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (_pickedImage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: TextButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Change Photo"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF0287c3),
                                    backgroundColor: const Color(0xFFE3F2FD),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20, 
                                      vertical: 12
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Submit button with bounce animation
                      AnimatedBuilder(
                        animation: _bounceController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _bounceAnimation.value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(35),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isLoading ? [
                                const Color(0xFF32B4FF).withOpacity(0.7),
                                const Color(0xFF0287c3).withOpacity(0.7),
                              ] : [
                                const Color(0xFF32B4FF),
                                const Color(0xFF0287c3),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0287c3).withOpacity(_isLoading ? 0.2 : 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isLoading ? null : _submit,
                              borderRadius: BorderRadius.circular(35),
                              splashColor: Colors.white.withOpacity(0.2),
                              highlightColor: Colors.transparent,
                              child: _isLoading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: CircularProgressIndicator(
                                          valueColor: _loadingController.drive(
                                            ColorTween(
                                              begin: Colors.white,
                                              end: Colors.white.withOpacity(0.6),
                                            ),
                                          ),
                                          strokeWidth: 3,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Processing...',
                                        style: TextStyle(
                                          fontSize: 18,
                                          letterSpacing: 1,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        AnimatedBuilder(
                                          animation: _pulseController,
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale: 1.0 + (_pulseController.value * 0.1),
                                              child: const Icon(
                                                Icons.medical_services_rounded,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'DIAGNOSE NOW',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final List<Particle> particles = List.generate(30, (index) => Particle());

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();
      particle.draw(canvas, size);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class Particle {
  late double x;
  late double y;
  late Color color;
  late double size;
  late double velocity;
  late double angle;

  Particle() {
    reset(true);
  }

  void reset([bool top = false]) {
    final random = math.Random();
    x = random.nextDouble() * 400;
    y = top ? -10 - random.nextDouble() * 40 : random.nextDouble() * 200;
    color = Color.fromARGB(
      255,
      100 + random.nextInt(155),
      100 + random.nextInt(155),
      100 + random.nextInt(155),
    );
    size = 5 + random.nextDouble() * 10;
    velocity = 1 + random.nextDouble() * 4;
    angle = random.nextDouble() * 0.5 - 0.25;
  }

  void update() {
    y += velocity;
    x += angle;
    if (y > 400) reset();
  }

  void draw(Canvas canvas, Size size) {
    Paint paint = Paint()..color = color;
    canvas.drawCircle(Offset(x, y), this.size, paint);
  }
}

class DashedBorder {
  static BoxBorder all({
    required Color color,
    required List<double> dashPattern,
    required double strokeWidth,
    required BorderRadius borderRadius,
  }) {
    return _DashedBorder(
      color: color,
      dashPattern: dashPattern,
      strokeWidth: strokeWidth,
      borderRadius: borderRadius,
    );
  }
}

class _DashedBorder extends BoxBorder {
  final Color color;
  final List<double> dashPattern;
  final double strokeWidth;
  final BorderRadius borderRadius;

  const _DashedBorder({
    required this.color,
    required this.dashPattern,
    required this.strokeWidth,
    required this.borderRadius,
  }) : assert(dashPattern.length == 2);

  @override
  BorderSide get top => BorderSide.none;

  @override
  BorderSide get bottom => BorderSide.none;

  @override
  BorderSide get right => BorderSide.none;

  @override
  BorderSide get left => BorderSide.none;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  bool get isUniform => true;
  
  @override
  ShapeBorder scale(double t) {
    return _DashedBorder(
      color: color,
      dashPattern: dashPattern,
      strokeWidth: strokeWidth * t,
      borderRadius: borderRadius * t,
    );
  }

  @override
  void paint(Canvas canvas, Rect rect,
      {TextDirection? textDirection,
      BoxShape shape = BoxShape.rectangle,
      BorderRadius? borderRadius}) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Path path = Path();
    
    if (shape == BoxShape.rectangle) {
      path.addRRect(RRect.fromRectAndCorners(
        rect,
        topLeft: this.borderRadius.topLeft,
        topRight: this.borderRadius.topRight,
        bottomLeft: this.borderRadius.bottomLeft,
        bottomRight: this.borderRadius.bottomRight,
      ));
    } else {
      path.addOval(rect);
    }

    final Path dashedPath = Path();
    final double dashLength = dashPattern[0];
    final double gapLength = dashPattern[1];
    bool isDash = true;
    
    for (final metric in path.computeMetrics()) {
      double currentDistance = 0.0;
      while (currentDistance < metric.length) {
        final double segmentLength = isDash ? dashLength : gapLength;
        if (currentDistance + segmentLength > metric.length) {
          final segment = metric.extractPath(
            currentDistance,
            metric.length,
          );
          dashedPath.addPath(segment, Offset.zero);
          currentDistance = metric.length;
        } else {
          final segment = metric.extractPath(
            currentDistance,
            currentDistance + segmentLength,
          );
          if (isDash) {
            dashedPath.addPath(segment, Offset.zero);
          }
          currentDistance += segmentLength;
        }
        isDash = !isDash;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }
}
