import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
// import 'screens/Inventory.dart';

void main() {
  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management Systems',
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
  int _currentindex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: IndexedStack(
      //   index: _currentindex,
      //   children: [
      //     const InventoryScreen(),
      //     ],
      // ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentindex,
          onTap: (index) => setState(() => _currentindex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          
          selectedIconTheme: const  IconThemeData(
            size: 35,
            color: Colors.amber,

          ),
          unselectedIconTheme: const IconThemeData(
            size: 24,
          ),

          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Container(
                padding: const EdgeInsets.all(8), 
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 30, 39, 54), 
                  shape: BoxShape.circle,
                ),
               child: Icon(Icons.dashboard_rounded),
              ),
              label: 'แดชบอร์ด',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 30, 39, 54), 
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shopping_cart_rounded),
              ),
              label: 'ขายสินค้า',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.indeterminate_check_box_outlined),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 30, 39, 54),
                  shape: BoxShape.circle,
                ),
              child: Icon(Icons.indeterminate_check_box_rounded),
              ),
              label: 'สินค้า',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_graph_outlined),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 30, 39, 54),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_graph_rounded),
              ),
              label: 'รายงาน',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 30, 39, 54),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.history),
              ),
              label: 'ตั้งค่า',
            ),
          ],
        ),
      ),
    );
  }
}
