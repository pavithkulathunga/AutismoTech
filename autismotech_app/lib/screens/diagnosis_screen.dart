import 'dart:io';
import 'package:autismotech_app/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, int?> answers = {};
  XFile? _pickedImage;
  bool _isLoading = false;

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
    },
    {"question": "Sex of the child", "field": "feature11"},
    {"question": "Family member suffering from ASD?", "field": "feature12"},
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
    return answers.length == questions.length && _pickedImage != null;
  }

  void _submit() async {
    if (!validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions and upload an image.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final uri = Uri.parse(
      'https://autismotech-models.onrender.com/asd_diagnose/predict',
      // 'https://autismo-tech-f81c1344ed86.herokuapp.com/asd_diagnose/predict',
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
          _showDialog("Prediction Result", result.toString());
        } catch (_) {
          _showDialog("Prediction Result", resBody);
        }
      } else {
        _showDialog(
          "Error",
          "Server responded with status ${response.statusCode}:\n$resBody",
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showDialog("Error", "Submission failed:\n$e");
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  List<Widget> _buildOptions(String fieldName, Color textColor) {
    List<Widget> radios = [];

    if (fieldName == 'feature10') {
      radios = [
        _buildRadio(fieldName, 'Always/Usually/Sometimes', 1, textColor),
        _buildRadio(fieldName, 'Rarely/Never', 0, textColor),
      ];
    } else if (fieldName == 'feature11') {
      radios = [
        _buildRadio(fieldName, 'Male', 1, textColor),
        _buildRadio(fieldName, 'Female', 0, textColor),
      ];
    } else if (fieldName == 'feature12') {
      radios = [
        _buildRadio(fieldName, 'Yes', 1, textColor),
        _buildRadio(fieldName, 'No', 0, textColor),
      ];
    } else {
      radios = [
        _buildRadio(fieldName, 'Always/Usually', 0, textColor),
        _buildRadio(fieldName, 'Sometimes/Rarely/Never', 1, textColor),
      ];
    }

    return radios;
  }

  Widget _buildRadio(
    String fieldName,
    String label,
    int value,
    Color textColor,
  ) {
    return RadioListTile<int>(
      title: Text(label, style: TextStyle(color: textColor)),
      value: value,
      groupValue: answers[fieldName],
      onChanged: (val) {
        setState(() {
          answers[fieldName] = val;
        });
      },
      // activeColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.diagnosis,
      appBar: AppBar(
        title: const Text('ASD Diagnosis'),
        centerTitle: true,
        backgroundColor: AppColors.diagnosis,
        titleTextStyle: const TextStyle(
          // color: Color(0xFFEEF6F7),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final q = entry.value;
                    final isEven = index % 2 == 0;

                    final bgColor =
                        isEven
                            ? const Color(0xFFfde6b3) // Dark blue
                            : const Color(0xFFfef7e6); // Light blue
                    final textColor = Color(0xFF02557a);

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: bgColor,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q["question"],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ..._buildOptions(q["field"], textColor),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(
                      Icons.upload_file,
                      color: Color(0xFFfcf5e6),
                    ),
                    label: const Text("Select Child's Photo"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF35baf6),
                      foregroundColor: const Color(0xFFfcf5e6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_pickedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_pickedImage!.path),
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (_pickedImage == null) const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0287c3),
                      foregroundColor: const Color(0xFFfcf5e6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 6,
                      shadowColor: Colors.black38,
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFfcf5e6),
                              ),
                            )
                            : const Text(
                              'DIAGNOSE',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
