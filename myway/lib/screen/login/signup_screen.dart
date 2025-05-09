import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:google_fonts/google_fonts.dart';
import 'package:myway/colors.dart';
import 'package:myway/provider/user_provider.dart';
import 'package:myway/screen/home_screen.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // FocusNode 추가
  final FocusNode _nicknameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  // 스크롤 컨트롤러 추가
  final ScrollController _scrollController = ScrollController();

  bool _allFieldsFilled = false;
  bool _isPasswordValid = false;
  bool _isNicknameValid = true;
  bool _isEmailValid = true;
  String _passwordErrorMessage = '';
  String _nicknameErrorMessage = '';
  String _emailErrorMessage = '';
  String _confirmPasswordErrorMessage = '';

  // 현재 포커스된 필드 추적
  String _currentFocusField = '';

  // 키보드 표시 여부
  bool _isKeyboardVisible = false;

  // 입력 필드에 텍스트 존재 여부
  bool _hasAnyText = false;

  @override
  void initState() {
    super.initState();

    // 텍스트 필드 변경 감지
    _nicknameController.addListener(_checkTextAndValidate);
    _emailController.addListener(_checkTextAndValidate);
    _passwordController.addListener(_checkTextAndValidate);
    _confirmPasswordController.addListener(_checkTextAndValidate);

    // 포커스 변경 감지
    _nicknameFocus.addListener(() {
      if (_nicknameFocus.hasFocus) {
        setState(() {
          _currentFocusField = 'nickname';
        });
        _scrollToField(1);
      } else {
        _checkFieldFocus();
      }
    });

    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        setState(() {
          _currentFocusField = 'email';
        });
        _scrollToField(2);
      } else {
        _checkFieldFocus();
      }
    });

    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) {
        setState(() {
          _currentFocusField = 'password';
        });
        _scrollToField(3);
      } else {
        _checkFieldFocus();
      }
    });

    _confirmPasswordFocus.addListener(() {
      if (_confirmPasswordFocus.hasFocus) {
        setState(() {
          _currentFocusField = 'confirmPassword';
        });
        _scrollToField(4);
      } else {
        _checkFieldFocus();
      }
    });
  }

  // 텍스트가 입력되었는지 확인하고 유효성 검사 실행
  void _checkTextAndValidate() {
    _checkAnyText();

    // 각 필드별 유효성 검사
    if (_currentFocusField == 'nickname' ||
        _nicknameController.text.isNotEmpty) {
      _validateNickname();
    }

    if (_currentFocusField == 'email' || _emailController.text.isNotEmpty) {
      _validateEmail();
    }

    if (_currentFocusField == 'password' ||
        _passwordController.text.isNotEmpty) {
      _validatePassword();
    }

    if (_currentFocusField == 'confirmPassword' ||
        _confirmPasswordController.text.isNotEmpty) {
      _validateConfirmPassword();
    }

    // 모든 필드 확인
    _checkFields();
  }

  // 입력 필드에 텍스트가 있는지 확인
  void _checkAnyText() {
    setState(() {
      _hasAnyText =
          _nicknameController.text.isNotEmpty ||
          _emailController.text.isNotEmpty ||
          _passwordController.text.isNotEmpty ||
          _confirmPasswordController.text.isNotEmpty;
    });
  }

  // 현재 표시할 에러 메시지 가져오기
  String _getCurrentErrorMessage() {
    // 모든 필드가 채워지고 유효하면 빈 메시지 반환
    if (_allFieldsFilled) {
      return '';
    }

    // 필드 입력 여부 확인
    bool hasEmptyField =
        _nicknameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty;

    // 닉네임 필드에 텍스트가 있고 유효하지 않은 경우
    if (_nicknameController.text.isNotEmpty && !_isNicknameValid) {
      return _nicknameErrorMessage;
    }

    // 이메일 필드에 텍스트가 있고 유효하지 않은 경우
    if (_emailController.text.isNotEmpty && !_isEmailValid) {
      return _emailErrorMessage;
    }

    // 비밀번호 필드에 텍스트가 있고 유효하지 않은 경우
    if (_passwordController.text.isNotEmpty && !_isPasswordValid) {
      return _passwordErrorMessage;
    }

    // 비밀번호 확인 필드에 텍스트가 있고 비밀번호와 일치하지 않는 경우
    if (_confirmPasswordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      return _confirmPasswordErrorMessage;
    }

    // 현재 포커스된 필드의 에러 메시지 반환 (위의 조건에 해당하지 않는 경우)
    String errorMessage = '';
    switch (_currentFocusField) {
      case 'nickname':
        errorMessage =
            _nicknameErrorMessage.isNotEmpty ? _nicknameErrorMessage : '';
        break;
      case 'email':
        errorMessage = _emailErrorMessage.isNotEmpty ? _emailErrorMessage : '';
        break;
      case 'password':
        errorMessage =
            _passwordErrorMessage.isNotEmpty ? _passwordErrorMessage : '';
        break;
      case 'confirmPassword':
        // 비밀번호 확인 필드에서는 비밀번호 필드의 유효성도 함께 확인
        if (_confirmPasswordErrorMessage.isNotEmpty) {
          errorMessage = _confirmPasswordErrorMessage;
        } else if (!_isPasswordValid && _passwordController.text.isNotEmpty) {
          errorMessage = _passwordErrorMessage;
        }
        break;
    }

    if (errorMessage.isNotEmpty) {
      return errorMessage;
    }

    // 다른 에러 메시지가 없고 입력란이 비어있으면 기본 메시지 반환
    if (hasEmptyField) {
      return '모든 입력란을 채워주세요';
    }

    return '';
  }

  // 필드 포커스 상태 확인
  void _checkFieldFocus() {
    bool hasFocus =
        _nicknameFocus.hasFocus ||
        _emailFocus.hasFocus ||
        _passwordFocus.hasFocus ||
        _confirmPasswordFocus.hasFocus;

    setState(() {
      if (!hasFocus) {
        _currentFocusField = '';
      }
    });
  }

  // 포커스된 필드로 스크롤
  void _scrollToField(int fieldIndex) {
    // 키보드가 표시되는 시간을 고려하여 약간 지연 후 스크롤
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_scrollController.hasClients) return;

      // 각 필드의 대략적인 위치 계산
      final double fieldPosition =
          40.0 + 30.0 + 40.0 + fieldIndex * (48.0 + 20.0);

      // 키보드 높이를 고려하여 스크롤
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      if (keyboardHeight > 0) {
        setState(() {
          _isKeyboardVisible = true;
        });

        final screenHeight = MediaQuery.of(context).size.height;
        final targetPosition =
            fieldPosition - (screenHeight - keyboardHeight) / 2 + 48.0;

        _scrollController.animateTo(
          targetPosition > 0 ? targetPosition : 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        setState(() {
          _isKeyboardVisible = false;
        });
      }
    });
  }

  // 닉네임 유효성 검사
  void _validateNickname() {
    final nickname = _nicknameController.text;

    if (nickname.isEmpty) {
      _isNicknameValid = true;
      _nicknameErrorMessage = '';
      return;
    }

    // UTF-8 인코딩을 사용하여 바이트 수 계산
    final bytes = utf8.encode(nickname);
    final byteLength = bytes.length;

    setState(() {
      if (byteLength < 6) {
        _isNicknameValid = false;
        _nicknameErrorMessage = '닉네임은 한글 2자, 영문 6자 이상이어야 합니다';
      } else {
        _isNicknameValid = true;
        _nicknameErrorMessage = '';
      }
    });
  }

  // 이메일 유효성 검사
  void _validateEmail() {
    final email = _emailController.text;

    if (email.isEmpty) {
      _isEmailValid = true;
      _emailErrorMessage = '';
      return;
    }

    // 이메일 형식 검사를 위한 정규식
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    setState(() {
      if (!emailRegExp.hasMatch(email)) {
        _isEmailValid = false;
        _emailErrorMessage = '올바른 이메일 형식이 아닙니다';
      } else {
        _isEmailValid = true;
        _emailErrorMessage = '';
      }
    });
  }

  // 비밀번호 확인 필드 유효성 검사
  void _validateConfirmPassword() {
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      if (confirmPassword.isEmpty) {
        _confirmPasswordErrorMessage = '';
      } else if (!_isPasswordValid) {
        _confirmPasswordErrorMessage = '비밀번호가 유효하지 않습니다';
      } else if (_passwordController.text != confirmPassword) {
        _confirmPasswordErrorMessage = '비밀번호가 일치하지 않습니다';
      } else {
        _confirmPasswordErrorMessage = '';
      }
    });
  }

  void _validatePassword() {
    final password = _passwordController.text;

    // 비밀번호 유효성 검사 (영어, 숫자, 특수문자 포함 8자 이상)
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    final isAtLeast8Chars = password.length >= 8;

    setState(() {
      if (password.isEmpty) {
        _isPasswordValid = false;
        _passwordErrorMessage = '';
      } else if (!isAtLeast8Chars) {
        _isPasswordValid = false;
        _passwordErrorMessage = '비밀번호는 8자 이상이어야 합니다';
      } else if (!(hasLetter && hasDigit && hasSpecial)) {
        _isPasswordValid = false;
        _passwordErrorMessage = '영어, 숫자, 특수문자를 모두 포함해야 합니다';
      } else {
        _isPasswordValid = true;
        _passwordErrorMessage = '';
      }

      // 비밀번호가 변경되면 비밀번호 확인 필드도 검사
      if (_confirmPasswordController.text.isNotEmpty) {
        _validateConfirmPassword();
      }
    });
  }

  void _checkFields() {
    setState(() {
      _allFieldsFilled =
          _nicknameController.text.isNotEmpty &&
          _isNicknameValid &&
          _emailController.text.isNotEmpty &&
          _isEmailValid &&
          _isPasswordValid &&
          _confirmPasswordController.text.isNotEmpty &&
          _passwordController.text == _confirmPasswordController.text;
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    // FocusNode 해제
    _nicknameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();

    // 스크롤 컨트롤러 해제
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 중앙에 표시할 메시지 가져오기
    final String centerMessage = _getCurrentErrorMessage();

    // 키보드 표시 여부 확인
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    _isKeyboardVisible = keyboardHeight > 0;

    // 버튼을 하단에 고정할지 여부 결정
    final shouldFixButtonToBottom = !_hasAnyText && !_isKeyboardVisible;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        title: Text(
          '회원가입',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40.0),
                      const SizedBox(height: 40.0),
                      _buildTextField(
                        '닉네임',
                        _nicknameController,
                        focusNode: _nicknameFocus,
                        isValid: _isNicknameValid,
                      ),
                      const SizedBox(height: 20.0),
                      _buildTextField(
                        '이메일',
                        _emailController,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        isValid: _isEmailValid,
                      ),
                      const SizedBox(height: 20.0),
                      _buildTextField(
                        '비밀번호',
                        _passwordController,
                        focusNode: _passwordFocus,
                        isPassword: true,
                        isValid: _isPasswordValid,
                      ),
                      const SizedBox(height: 20.0),
                      _buildTextField(
                        '비밀번호 확인',
                        _confirmPasswordController,
                        focusNode: _confirmPasswordFocus,
                        isPassword: true,
                        isValid:
                            _confirmPasswordController.text.isEmpty ||
                            (_isPasswordValid &&
                                _passwordController.text ==
                                    _confirmPasswordController.text),
                      ),
                      if (!shouldFixButtonToBottom) ...[
                        const SizedBox(height: 20.0),
                        Center(
                          child: Text(
                            centerMessage,
                            style: TextStyle(
                              color:
                                  centerMessage.isEmpty
                                      ? Colors.transparent
                                      : Colors.red[400],
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        SizedBox(
                          width: double.infinity,
                          height: 48.0,
                          child: Consumer<UserProvider>(
                            builder: (context, userProvider, child) {
                              return ElevatedButton(
                                onPressed:
                                    _allFieldsFilled
                                        ? () async {
                                          // 회원가입 로직 구현 필요
                                          if (!userProvider.isLoading) {
                                            bool success = await userProvider
                                                .signUp(
                                                  email: _emailController.text,
                                                  password:
                                                      _passwordController.text,
                                                  checkPassword:
                                                      _confirmPasswordController
                                                          .text,
                                                  username:
                                                      _nicknameController.text,
                                                );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).hideCurrentSnackBar();

                                            if (success) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '회원가입 성공! 이름: ${userProvider.currentUser?.displayName}',
                                                  ),
                                                ),
                                              );
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) => HomeScreen(),
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '회원가입 실패! ${userProvider.errorMessage ?? '알 수 없는 오류'}',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ORANGE_PRIMARY_500,
                                  disabledBackgroundColor: Colors.grey[300],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: const Text(
                                  '회원가입',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '이미 계정이 있으신가요?',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14.0,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // 로그인 화면으로 이동
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/home');
                              },
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: const EdgeInsets.only(left: 4.0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                '로그인',
                                style: TextStyle(
                                  color: BLUE_SECONDARY_600,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                      ],
                      if (shouldFixButtonToBottom)
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.2,
                        ),
                    ],
                  ),
                ),
              ),
              // 텍스트가 없고 키보드가 보이지 않는 경우에만 하단에 고정
              if (shouldFixButtonToBottom)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0.0,
                    vertical: 10.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Text(
                          centerMessage,
                          style: TextStyle(
                            color:
                                centerMessage.isEmpty
                                    ? Colors.transparent
                                    : Colors.red[400],
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      SizedBox(
                        width: double.infinity,
                        height: 48.0,
                        child: Consumer<UserProvider>(
                          builder: (context, userProvider, child) {
                            return ElevatedButton(
                              onPressed:
                                  _allFieldsFilled
                                      ? () async {
                                        // 회원가입 로직 구현 필요
                                        if (!userProvider.isLoading) {
                                          bool
                                          success = await userProvider.signUp(
                                            email: _emailController.text,
                                            password: _passwordController.text,
                                            checkPassword:
                                                _confirmPasswordController.text,
                                            username: _nicknameController.text,
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).hideCurrentSnackBar();

                                          if (success) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '회원가입 성공! 이름: ${userProvider.currentUser?.displayName}',
                                                ),
                                              ),
                                            );
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => HomeScreen(),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '회원가입 실패! ${userProvider.errorMessage ?? '알 수 없는 오류'}',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      }
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF567FD9),
                                disabledBackgroundColor: Colors.grey[300],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: const Text(
                                '회원가입',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '이미 계정이 있으신가요?',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14.0,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // 로그인 화면으로 이동
                              Navigator.pushNamed(context, 'signIn');
                            },
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.only(left: 4.0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              '로그인',
                              style: TextStyle(
                                color: BLUE_SECONDARY_600,
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40.0),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hintText,
    TextEditingController controller, {
    FocusNode? focusNode,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? errorText,
    double height = 50.0,
    bool isValid = true,
  }) {
    // 현재 필드가 포커스되었는지 확인
    bool isFieldFocused = focusNode != null && focusNode.hasFocus;

    // 유효하지 않고 포커스가 없는 경우에만 빨간색 테두리 표시
    bool shouldShowRedBorder =
        !isValid && !isFieldFocused && controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color:
                  shouldShowRedBorder ||
                          (errorText != null && errorText.isNotEmpty)
                      ? Colors.red.shade400
                      : GRAYSCALE_LABEL_400,
              width: 1.0,
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPassword,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15.0),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15.0),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
      ],
    );
  }
}
