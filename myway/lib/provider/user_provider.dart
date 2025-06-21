import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myway/model/user.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSignUpSuccess = false;
  User? _currentUser;
  String? _nickname;

  // 게터
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSignUpSuccess => _isSignUpSuccess;
  User? get currentUser => _currentUser;
  String? get nickname => _nickname;

  // 로딩 상태 설정
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 에러 메시지 설정
  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void setSignUpSuccess(bool success) {
    _isSignUpSuccess = success;
    notifyListeners();
  }

  Future<void> loadNickname() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    _nickname = doc.data()?['username'];
    notifyListeners();
  }

  Future<void> updateNickname(String newNickname) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'username': newNickname,
    });

    await FirebaseAuth.instance.currentUser?.updateDisplayName(newNickname);
    await FirebaseAuth.instance.currentUser?.reload();

    _currentUser = FirebaseAuth.instance.currentUser;

    _nickname = newNickname;
    notifyListeners(); // 갱신 알림
  }

  // 회원가입 함수
  Future<bool> signUp({
    required String email,
    required String password,
    required String checkPassword,
    required String username,
  }) async {
    setLoading(true);
    setErrorMessage(null);
    try {
      // Firebase Auth 회원가입
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // 사용자 이름 업데이트
      await userCredential.user?.updateDisplayName(username.trim());
      await userCredential.user?.reload();

      // 현재 사용자 정보 업데이트
      _currentUser = FirebaseAuth.instance.currentUser;

      // UserModel 생성
      UserModel user = UserModel(
        username: username,
        useremail: email,
        uid: userCredential.user!.uid,
      );

      // Firestore에 사용자 정보 저장
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': user.username,
        'email': user.useremail,
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setSignUpSuccess(true);
      setErrorMessage(null);
      setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('회원가입 오류: $e');
      // 에러 코드에 따른 한글 메시지 설정
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = '이미 사용 중인 이메일 주소입니다.';
          break;
        case 'invalid-email':
          errorMessage = '유효하지 않은 이메일 형식입니다.';
          break;
        default:
          errorMessage = '회원가입 실패: ${e.message}';
          break;
      }
      setErrorMessage(errorMessage);
      setLoading(false);
      return false;
    } catch (e) {
      debugPrint('회원가입 기타 오류: $e');
      setErrorMessage('회원가입 실패: ${e.toString()}');
      setLoading(false);
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void signOut() async {
    await FirebaseAuth.instance.signOut();

    _currentUser = null;
    notifyListeners();
  }

  Future<bool> deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 계정 삭제 실행
        await user.delete();
        await FirebaseAuth.instance.signOut(); // 로그아웃 명시
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('회원탈퇴 실패: $e');
      return false;
    }
  }

  // 계정 삭제 후 상태 초기화를 위한 메서드
  void clearUserData() {
    _currentUser = null;
    _nickname = null;
    notifyListeners();
  }

  Future<void> updateDisplayName(String newName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(newName);
        await user.reload();
        _currentUser = FirebaseAuth.instance.currentUser;
        notifyListeners();
      }
    } catch (e) {
      print('이름 변경 실패');
    }
  }
}
