/// EN: Accessibility usage examples
/// KO: 접근성 사용 예제
///
/// This file demonstrates how to use accessibility features for WCAG AA compliance.
/// 이 파일은 WCAG AA 준수를 위한 접근성 기능 사용 방법을 보여줍니다.
library;

import 'package:flutter/material.dart';
import 'package:oshi_log/core/accessibility/a11y_wrapper.dart';

/// EN: Example screen demonstrating A11yScalableText usage
/// KO: A11yScalableText 사용법을 보여주는 예제 화면
class A11yExamplesScreen extends StatelessWidget {
  const A11yExamplesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const A11yScalableText(
          '접근성 예제',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // EN: Example 1: Basic scalable text
          // KO: 예제 1: 기본 스케일 가능 텍스트
          _buildSection(
            context,
            title: '기본 사용법',
            children: [
              const A11yScalableText(
                '이 텍스트는 사용자의 시스템 설정에 따라 크기가 자동으로 조정됩니다.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const A11yScalableText(
                'This text automatically scales based on user system settings.',
                style: TextStyle(fontSize: 16),
                semanticLabel: 'Description of scalable text feature',
              ),
            ],
          ),

          const Divider(height: 32),

          // EN: Example 2: Text with overflow handling
          // KO: 예제 2: 오버플로우 처리가 있는 텍스트
          _buildSection(
            context,
            title: '오버플로우 처리',
            children: [
              Container(
                width: 200,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const A11yScalableText(
                  '매우 긴 텍스트가 컨테이너를 초과할 때 말줄임표로 표시됩니다',
                  style: TextStyle(fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          // EN: Example 3: Announcer demonstrations
          // KO: 예제 3: Announcer 데모
          _buildSection(
            context,
            title: '스크린 리더 공지',
            children: [
              ElevatedButton(
                onPressed: () {
                  A11yAnnouncer.announce(context, '일반 메시지가 공지되었습니다');
                },
                child: const Text('일반 공지'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  A11yAnnouncer.announceError(context, '네트워크 연결 실패');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('에러 공지'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  A11yAnnouncer.announceSuccess(context, '저장 완료');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('성공 공지'),
              ),
            ],
          ),

          const Divider(height: 32),

          // EN: Example 4: Form error handling
          // KO: 예제 4: 폼 에러 처리
          _buildSection(context, title: '폼 에러 처리', children: [_FormExample()]),

          const Divider(height: 32),

          // EN: Example 5: Accessibility utilities
          // KO: 예제 5: 접근성 유틸리티
          _buildSection(
            context,
            title: '접근성 설정 확인',
            children: [_AccessibilityStatusWidget()],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        A11yScalableText(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

/// EN: Example form demonstrating error announcements
/// KO: 에러 공지를 보여주는 예제 폼
class _FormExample extends StatefulWidget {
  @override
  State<_FormExample> createState() => _FormExampleState();
}

class _FormExampleState extends State<_FormExample> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // EN: Announce form validation errors
      // KO: 폼 검증 에러 공지
      A11yAnnouncer.announceError(context, '입력 항목을 확인해주세요');
      return;
    }

    setState(() => _isSubmitting = true);

    // EN: Announce loading state
    // KO: 로딩 상태 공지
    A11yAnnouncer.announce(context, '제출 중입니다');

    // EN: Simulate API call
    // KO: API 호출 시뮬레이션
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isSubmitting = false);

    // EN: Announce success
    // KO: 성공 공지
    if (mounted) {
      A11yAnnouncer.announceSuccess(context, '성공적으로 제출되었습니다');
      _emailController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: '이메일',
              hintText: 'example@email.com',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '이메일을 입력해주세요';
              }
              if (!value.contains('@')) {
                return '올바른 이메일 형식이 아닙니다';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitForm,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('제출'),
          ),
        ],
      ),
    );
  }
}

/// EN: Widget showing current accessibility settings
/// KO: 현재 접근성 설정을 보여주는 위젯
class _AccessibilityStatusWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isScreenReaderEnabled = A11yUtils.isScreenReaderEnabled(context);
    final isReduceMotionEnabled = A11yUtils.isReduceMotionEnabled(context);
    final isBoldTextEnabled = A11yUtils.isBoldTextEnabled(context);
    final textScaleFactor = A11yUtils.getTextScaleFactor(context);
    final isHighContrastEnabled = A11yUtils.isHighContrastEnabled(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow('스크린 리더', isScreenReaderEnabled),
            _buildStatusRow('모션 감소', isReduceMotionEnabled),
            _buildStatusRow('굵은 텍스트', isBoldTextEnabled),
            _buildStatusRow('고대비 모드', isHighContrastEnabled),
            const Divider(height: 16),
            A11yScalableText(
              '텍스트 스케일: ${textScaleFactor.toStringAsFixed(2)}x',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          A11yScalableText(label, style: const TextStyle(fontSize: 14)),
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }
}
