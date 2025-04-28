import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:autismotech_app/constants/colors.dart'; // Your color constants

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, int?> answers = {}; // To store answers
  XFile? _pickedImage;

  final List<Map<String, dynamic>> questions = [
    {
      "question": "Does your child look at you when you call his/her name?",
      "field": "feature1",
    },
    {
      "question": "Is it easy for you to get eye contact with your child?",
      "field": "feature2",
    },
    {
      "question":
          "Does your child point to indicate that he/she wants something?",
      "field": "feature3",
    },
    {
      "question": "Does your child point to share interest with you?",
      "field": "feature4",
    },
    {
      "question":
          "Does your child pretend? (e.g., care for dolls, talk on a toy phone)",
      "field": "feature5",
    },
    {
      "question": "Does your child follow where you’re looking?",
      "field": "feature6",
    },
    {
      "question": "If someone is upset, does your child try to comfort them?",
      "field": "feature7",
    },
    {
      "question": "Would you describe your child’s first words as unusual?",
      "field": "feature8",
    },
    {"question": "Does your child use simple gestures?", "field": "feature9"},
    {
      "question": "Does your child stare at nothing with no apparent purpose?",
      "field": "feature10",
    }, // SPECIAL CASE
    {"question": "Sex of the child?", "field": "feature11"}, // SPECIAL CASE
    {
      "question": "Family member suffering from ASD?",
      "field": "feature12",
    }, // SPECIAL CASE
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = picked;
      });
    }
  }

  bool validateForm() {
    bool allAnswered = answers.length == questions.length;
    bool imageSelected = _pickedImage != null;
    return allAnswered && imageSelected;
  }

  void _submit() {
    if (!validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions and upload an image.'),
        ),
      );
      return;
    }

    // Form is valid
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form submitted successfully!')),
    );
  }

  List<Widget> _buildOptions(String fieldName) {
    if (fieldName == 'feature10') {
      return [
        RadioListTile<int>(
          title: const Text('Always/Usually/Sometimes'),
          value: 1,
          groupValue: answers[fieldName],
          onChanged: (value) {
            setState(() {
              answers[fieldName] = value;
            });
          },
        ),
        RadioListTile<int>(
          title: const Text('Rarely/Never'),
          value: 0,
          groupValue: answers[fieldName],
          onChanged: (value) {
            setState(() {
              answers[fieldName] = value;
            });
          },
        ),
      ];
    } else if (fieldName == 'feature11') {
      return [
        RadioListTile<int>(
          title: const Text('Male'),
          value: 1,
          groupValue: answers[fieldName],
          onChanged: (value) {
            setState(() {
              answers[fieldName] = value;
            });
          },
        ),
        RadioListTile<int>(
          title: const Text('Female'),
          value: 0,
          groupValue: answers[fieldName],
          onChanged: (value) {
            setState(() {
              answers[fieldName] = value;
            });
          },
        ),
      ];
    } else if (fieldName == 'feature12') {
      return [
        RadioListTile<int>(
          title: const Text('Yes'),
          value: 1,
          groupValue: answers[fieldName],
          onChanged: (value) {
            setState(() {
              answers[fieldName] = value;
            });
          },
        ),
        RadioListTile<int>(
          title: const Text('No'),
          value: 0,
          groupValue: answers[fieldName],
          onChanged: (value) {
            setState(() {
              answers[fieldName] = value;
            });
          },
        ),
      ];
    } else {
      // Default case for all others
      return [
        RadioListTile<int>(
          title: const Text('Always/Usually'),
          value: 0,
          groupValue: answers[fieldName],
          onChanged: (value) {
            setState(() {
              answers[fieldName] = value;
            });
          },
        ),
        RadioListTile<int>(
          title: const Text('Sometimes/Rarely/Never'),
          value: 1,
          groupValue: answers[fieldName],
          onChanged: (value) {
            setState(() {
              answers[fieldName] = value;
            });
          },
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ASD Diagnosis'),
        centerTitle: true,
        backgroundColor: AppColors.diagnosis,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...questions.map(
                (q) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q["question"],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ..._buildOptions(q["field"]),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              const Divider(height: 30, thickness: 2),
              Wrap(
                spacing: 10, // space between items
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Upload Child\'s Photo:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text('Pick Image'),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Center(
                child:
                    _pickedImage != null
                        ? Image.file(
                          File(_pickedImage!.path),
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        )
                        : const Text('No image selected.'),
              ),

              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  onPressed: _submit,
                  child: const Text('DIAGNOSE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
