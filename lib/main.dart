import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:inventory_management_system/screens/DebtReport.dart';
import 'package:provider/provider.dart';

import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
// import 'screens/AddProduct.dart';
import 'screens/Dashboard.dart';
import 'screens/Store.dart';
import 'screens/inventory.dart';
import 'screens/Report.dart';
import 'screens/Setting.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const InventoryApp(),
    ),
  );
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management Systems',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.promptTextTheme(ThemeData.light().textTheme),
      ),
      home: const MainNavScreen(),
    );
  }
}

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    StoreScreen(),
    InventoryScreen(),
    // AddProductScreen(),
    DebtReportScreen(),
    ReportScreen(),
    SettingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.13),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black,
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),

          selectedIconTheme: const IconThemeData(size: 35, color: Colors.amber),
          unselectedIconTheme: const IconThemeData(size: 24),

          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 30, 39, 54),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.dashboard_rounded),
              ),
              label: 'แดชบอร์ด',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.shopping_cart_outlined),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 30, 39, 54),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_cart_rounded),
              ),
              label: 'ขายสินค้า',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.indeterminate_check_box_outlined),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 30, 39, 54),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.indeterminate_check_box_rounded),
              ),
              label: 'สินค้า',
            ),
            // BottomNavigationBarItem(
            //   icon: const Icon(Icons.stacked_bar_chart_outlined),
            //   activeIcon: Container(
            //     padding: const EdgeInsets.all(8),
            //     decoration: const BoxDecoration(
            //       color: Color.fromARGB(255, 30, 39, 54),
            //       shape: BoxShape.circle,
            //     ),
            //     child: const Icon(Icons.stacked_bar_chart_rounded),
            //   ),
            //   label: 'เพิ่มสินค้า',
            // ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history_edu_outlined),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 30, 39, 54),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_edu_outlined),
              ),
              label: 'ลูกหนี้',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.auto_graph_outlined),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 30, 39, 54),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_graph_rounded),
              ),
              label: 'รายงาน',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history_outlined),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 30, 39, 54),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history),
              ),
              label: 'ตั้งค่า',
            ),
          ],
        ),
      ),
    );
  }
}
