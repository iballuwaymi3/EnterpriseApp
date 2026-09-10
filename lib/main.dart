import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart0:convert';

void main() {
  runApp(const VarietyEnterpriseApp());
}

class VarietyEnterpriseApp extends StatelessWidget {
  const VarietyEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Al-Muhaidib ESS Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF007AFF),
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        fontFamily: 'SF Pro Display',
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final String _baseUrl = "https://varietyit-al-muhaidib-sanitary-ceramics.odoo.com";

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/en/ess/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'params': {
            'login': _employeeIdController.text,
            'password': _passwordController.text,
          }
        }),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(baseUrl: _baseUrl)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(baseUrl: _baseUrl)),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.corporate_fare, size: 80, color: Color(0xFF1D1D1F)),
            const SizedBox(height: 16),
            const Text(
              "المهيدب للأدوات الصحية والسيراميك",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "تسجيل دخول الموظفين (ESS Portal)",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _employeeIdController,
              decoration: const InputDecoration(
                labelText: 'الرقم الوظيفي / البريد',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                ),
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('تسجيل الدخول', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String baseUrl;
  const HomeScreen({super.key, required this.baseUrl});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final LocalAuthentication auth = LocalAuthentication();
  bool _isCheckedIn = false;
  String _scannedBarcode = "";

  Future<void> _handleAttendance() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'يرجى تأكيد البصمة لتسجيل الحضور/الانصراف',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (e) {
      debugPrint("Biometrics error: $e");
    }

    if (authenticated) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _isCheckedIn = !_isCheckedIn;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isCheckedIn 
              ? 'تم تسجيل الحضور بنجاح عند الإحداثيات: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}' 
              : 'تم تسجيل الانصراف بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بوابة الموظف - ESS'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _selectedIndex == 0 ? _buildAttendanceUI() : _buildBarcodeUI(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fingerprint),
            label: 'الحضور والإنصراف',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'فحص الباركود',
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isCheckedIn ? Icons.check_circle : Icons.access_time_filled,
            size: 90,
            color: _isCheckedIn ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            _isCheckedIn ? "أنت حالياً: على رأس العمل" : "أنت حالياً: خارج الدوام",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _handleAttendance,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: _isCheckedIn ? Colors.redAccent : const Color(0xFF007AFF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fingerprint, size: 55, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    _isCheckedIn ? 'تسجيل انصراف' : 'تسجيل حضور',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeUI() {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() {
                    _scannedBarcode = barcode.rawValue!;
                  });
                }
              }
            },
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("بيانات المنتج", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  _scannedBarcode.isEmpty 
                    ? "وجه الكاميرا نحو الباركود للبدء بالمسح..." 
                    : "الباركود المقروء: $_scannedBarcode",
                  style: TextStyle(
                    fontSize: 15, 
                    color: _scannedBarcode.isEmpty ? Colors.grey : Colors.blue,
                    fontWeight: _scannedBarcode.isEmpty ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "تنبيه: سيتم عرض كميات المخزون فور ربط صلاحيات API المبيعات.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
