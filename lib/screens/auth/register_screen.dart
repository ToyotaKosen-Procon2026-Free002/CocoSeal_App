import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../api_service.dart';
import '../../auth_gate.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  String _selectedRole = 'parent'; // 初期値は保護者
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // タブが切り替わった時に _selectedRole を更新する
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging ||
        _tabController.index != (_selectedRole == 'parent' ? 0 : 1)) {
      setState(() {
        _selectedRole = _tabController.index == 0 ? 'parent' : 'admin';
      });
    }
  }

  Future<void> _handleRegister() async {
    setState(() {
      _errorMessage = null;
    });

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();
    final String pin = _pinController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'すべての必須項目を入力してください';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'パスワードが一致しません';
      });
      return;
    }

    if (_selectedRole == 'parent' && pin.length != 4) {
      setState(() {
        _errorMessage = '保護者用PINコードは4桁の数字で入力してください';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Firebase Auth でアカウント作成
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (!mounted) return;

      if (userCredential.user != null) {
        // 2. バックエンド DB にユーザーを作成/取得 (get_or_create_user が動く)
        await ApiService.fetchUserProfile();

        // 3. 画面のタブ選択に応じて role を定義 ('0': 保護者, '1': 親機)
        final int roleValue = _selectedRole == 'parent' ? 0 : 1;

        // 4. バックエンドのユーザー情報を更新して role を保存
        // ※ ApiService に role を渡せるよう拡張している場合の処理例
        await ApiService.updateUserProfile(email: email, role: roleValue);

        if (!mounted) return;

        // AuthGateが保存されたroleを読み、適切なホーム画面へ遷移する。
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          _errorMessage = 'このメールアドレスは既に登録されています';
        } else if (e.code == 'weak-password') {
          _errorMessage = 'パスワードは8文字以上で入力してください';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'メールアドレスの形式が正しくありません';
        } else {
          _errorMessage = '登録に失敗しました: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = '予期せぬエラーが発生しました: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          decoration: InputDecoration(
            counterText: '',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.black, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey),
          label: const Text('戻る', style: TextStyle(color: Colors.grey)),
        ),
        leadingWidth: 100,
        title: const Text(
          '新規登録',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFFFB7B2),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(text: '保護者'),
                Tab(text: '親機'),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      label: 'メールアドレス',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      label: 'パスワード (半角英数字8文字以上)',
                      controller: _passwordController,
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      label: 'パスワード (確認用)',
                      controller: _confirmPasswordController,
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),

                    if (_selectedRole == 'parent') ...[
                      _buildTextField(
                        label: '保護者用PINコード (4桁の数字)',
                        controller: _pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (_errorMessage != null) ...[
                      Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'この内容で登録する',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
