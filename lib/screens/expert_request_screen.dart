import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ExpertRequestScreen extends StatefulWidget {
  const ExpertRequestScreen({super.key});

  @override
  State<ExpertRequestScreen> createState() => _ExpertRequestScreenState();
}

class _ExpertRequestScreenState extends State<ExpertRequestScreen> {
  File? _selectedFile;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // 이미 인증 요청이 제출되었다면 (certificatePath에 값이 있다면)
      if (authProvider.user?.certificatePath != null) {
        _showPendingMessageAndPop();
      }
    });
  }

  void _showPendingMessageAndPop() {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('현재 전문가 인증 심사 중에 있습니다. 심사 결과를 기다려주세요.')),
      );
      Navigator.pop(context);
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파일 선택 중 오류 발생: $e')),
      );
    }
  }

  void _submit() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자격 증명 서류를 업로드해주세요.')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null || user.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 정보가 유효하지 않습니다.')),
      );
      return;
    }
    
    if (user.certificatePath != null) {
      _showPendingMessageAndPop();
      return;
    }


    setState(() => _isLoading = true);

    try {
      await _apiService.requestExpertVerification(
        userId: int.parse(user.id),
        file: _selectedFile!,
        token: user.token!,
      );

      authProvider.markExpertRequested(); 

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전문가 인증 신청이 완료되었습니다.')),
      );
      Navigator.pop(context); 
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('전문가 인증 신청', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '전문가 자격 증명서류',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '자격증, 경력증명서 등을 업로드해주세요.\n(파일 형식: jpg, png, pdf)',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),

            GestureDetector(
              onTap: _pickFile,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_selectedFile == null) ...[
                      const Icon(Icons.upload_file, size: 50, color: Colors.blue),
                      const SizedBox(height: 12),
                      const Text('파일을 선택하려면 터치하세요', style: TextStyle(color: Colors.grey)),
                    ] else ...[
                      const Icon(Icons.check_circle, size: 50, color: Colors.green),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _selectedFile!.path.split('/').last,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '파일 변경하기',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12, decoration: TextDecoration.underline),
                      ),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0A2A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('신청하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}