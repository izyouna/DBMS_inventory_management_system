import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/Inventory.dart';
import 'screens/AddProduct.dart';
import 'screens/Debtors.dart';
import 'screens/History.dart';

void main() {
  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ระบบจัดการสต็อกสินค้าการเกษตร',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0891B2),
          brightness: Brightness.light,
          primary: const Color(0xFF0891B2),
        ),
        textTheme: GoogleFonts.promptTextTheme(ThemeData.light().textTheme),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _products = [
    // {'id': '1', 'name': 'สินค้าตัวอย่าง A', 'price': 99.0, 'quantity': 50, 'unit': 'ชิ้น'},
    // {'id': '2', 'name': 'สินค้าตัวอย่าง B', 'price': 150.0, 'quantity': 30, 'unit': 'กล่อง'},
    // {'id': '3', 'name': 'สินค้าตัวอย่าง C', 'price': 299.0, 'quantity': 15, 'unit': 'ชุด'},
  ];

  void _addProduct(Map<String, dynamic> product) {
    setState(() {
      _products.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': product['name'],
        'price': product['price'],
        'quantity': product['quantity'],
        'unit': product['unit'],
      });
    });
  }

  void _updateProduct(String id, Map<String, dynamic> product) {
    setState(() {
      final index = _products.indexWhere((p) => p['id'] == id);
      if (index >= 0) {
        _products[index] = {
          'id': id,
          'name': product['name'],
          'price': product['price'],
          'quantity': product['quantity'],
          'unit': product['unit'],
        };
      }
    });
  }

  void _deleteProduct(String id) {
    setState(() {
      _products.removeWhere((p) => p['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          InventoryScreen(
            products: _products,
            onUpdateProduct: _updateProduct,
            onDeleteProduct: _deleteProduct,
          ),
          AddProductScreen(onProductAdded: _addProduct),
          const DebtorsScreen(),
          const HistoryScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0891B2),
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'สินค้า',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'เพิ่มสินค้า',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_off_outlined),
              activeIcon: Icon(Icons.person_off),
              label: 'ลูกค้าค้างชำระ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'ประวัติ',
            ),
          ],
        ),
      ),
    );
  }
}
