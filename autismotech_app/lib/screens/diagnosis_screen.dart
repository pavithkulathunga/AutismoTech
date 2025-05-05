import 'dart:io';
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

  List<Widget> _buildOptions(String fieldName) {
    if (fieldName == 'feature10') {
      return [
        _buildRadio(fieldName, 'Always/Usually/Sometimes', 1),
        _buildRadio(fieldName, 'Rarely/Never', 0),
      ];
    } else if (fieldName == 'feature11') {
      return [
        _buildRadio(fieldName, 'Male', 1),
        _buildRadio(fieldName, 'Female', 0),
      ];
    } else if (fieldName == 'feature12') {
      return [
        _buildRadio(fieldName, 'Yes', 1),
        _buildRadio(fieldName, 'No', 0),
      ];
    } else {
      return [
        _buildRadio(fieldName, 'Always/Usually', 0),
        _buildRadio(fieldName, 'Sometimes/Rarely/Never', 1),
      ];
    }
  }

  Widget _buildRadio(String fieldName, String label, int value) {
    return RadioListTile<int>(
      title: Text(label),
      value: value,
      groupValue: answers[fieldName],
      onChanged: (val) {
        setState(() {
          answers[fieldName] = val;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7F3FF),
      appBar: AppBar(
        title: const Text('ASD Diagnosis'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        titleTextStyle: const TextStyle(
          color: Colors.white,
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
                  ...questions.map(
                    (q) => Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q["question"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ..._buildOptions(q["field"]),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.image),
                      const SizedBox(width: 10),
                      const Text(
                        'Upload Child\'s Photo:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Pick Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[300],
                        ),
                      ),
                    ],
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
                  if (_pickedImage == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No image selected.'),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
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
                                color: Colors.white,
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
