// lib/screens/upload_screen.dart
import 'dart:io';
import 'package:autismotech_app/screens/apiservice.dart';
import 'package:autismotech_app/screens/uploadsecound.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:autismotech_app/constants/theme.dart';
import 'package:autismotech_app/constants/colors.dart';
import 'package:autismotech_app/screens/global.dart' as globals;
// Import SecondUploadScreen

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Dropdown values stored as strings (e.g., "24 months")
  String? _selectedAge;
  String? _selectedGender;

  bool _isPickingImage = false; // Prevents multiple concurrent pick operations

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select an image.")));
      return;
    }
    if (_selectedAge == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select an age.")));
      return;
    }
    if (_selectedGender == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a gender.")));
      return;
    }
    // Ensure the user is logged in (globalUserId is set)
    if (globals.globalUserId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in.")));
      return;
    }

    // Extract numeric part from age string (e.g., "24 months" -> 24)
    int ageNumber = int.tryParse(_selectedAge!.split(' ')[0]) ?? 0;

    // Show a loading indicator while sending the request
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Upload successful: ${response.predictedLabel} (${(response.confidence * 100).toStringAsFixed(1)}%)",
          ),
        ),
      );

      // Navigate to SecondUploadScreen after success
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SecondUploadScreen()),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss the loading indicator
      print("Upload error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Behavioural Progress Prediction"),
        backgroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Intro text
            Text(
              "We need some information to predict the progress of an autistic kid",
              style: textStyle.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Image picker area
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child:
                    _selectedImage == null
                        ? Center(
                          child: Text(
                            "Tap to add image",
                            style: textStyle.copyWith(
                              color: AppColors.darkBlue,
                              fontSize: 16,
                            ),
                          ),
                        )
                        : Image.file(_selectedImage!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            // Age Dropdown (only numbers will be extracted)
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Age",
                labelStyle: textStyle.copyWith(
                  fontSize: 16,
                  color: AppColors.darkBlue,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              value: _selectedAge,
              items:
                  [
                    "2 years",
                    "3 years",
                    "4 years",
                    "5 years",
                    "6 years",
                  ].map((age) {
                    return DropdownMenuItem(
                      value: age,
                      child: Text(age, style: textStyle.copyWith(fontSize: 16)),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAge = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Gender Dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Gender",
                labelStyle: textStyle.copyWith(
                  fontSize: 16,
                  color: AppColors.darkBlue,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              value: _selectedGender,
              items:
                  ["Male", "Female"].map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(
                        gender,
                        style: textStyle.copyWith(fontSize: 16),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
            const SizedBox(height: 24),
            // NEXT Button to submit details
            ElevatedButton(
              onPressed: _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "NEXT",
                style: textStyle.copyWith(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
