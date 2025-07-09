import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class UploadImageScreen extends StatefulWidget {
  const UploadImageScreen({super.key});

  @override
  State<UploadImageScreen> createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  File? _image;
  bool _uploading = false;
  final ImagePicker _picker = ImagePicker();
  String _message = '';

  Future<void> _pickImage() async {
    final XFile? pickedFile =
    await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _message = '';
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() {
      _uploading = true;
      _message = '';
    });

    final uri = Uri.parse('http://192.168.0.104:5000/upload'); // твой бек

    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      _image!.path,
      filename: basename(_image!.path),
    ));

    final response = await request.send();

    if (response.statusCode == 200) {
      setState(() {
        _message = 'Изображение успешно загружено';
        _image = null;
      });
    } else {
      setState(() {
        _message = 'Ошибка загрузки изображения';
      });
    }

    setState(() {
      _uploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Загрузка изображения')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _image == null
                  ? const Text('Выберите изображение')
                  : Image.file(_image!),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Выбрать изображение'),
              ),
              const SizedBox(height: 20),
              _uploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _uploadImage,
                child: const Text('Загрузить'),
              ),
              const SizedBox(height: 20),
              Text(_message, style: const TextStyle(color: Colors.green)),
            ],
          ),
        ));
  }
}
