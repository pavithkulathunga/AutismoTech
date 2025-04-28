import 'package:autismotech_app/constants/colors.dart';
import 'package:flutter/material.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final _formKey = GlobalKey<FormState>();
  bool agree = false;

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
        child: Column(
          children: [
            CheckboxListTile(
              title: Text('I agree'),
              value: agree,
              onChanged: (val) {
                setState(() {
                  agree = val!;
                });
              },
            ),
            TextFormField(
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate() && agree) {
                  // success
                }
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}