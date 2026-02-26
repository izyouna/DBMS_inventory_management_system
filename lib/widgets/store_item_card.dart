import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';

class StoreItemCard extends StatelessWidget {
  final Product product;
  final int inCart;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const StoreItemCard({
    super.key,
    required this.product,
    required this.inCart,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 226, 232, 240),
              borderRadius: BorderRadius.circular(16),
            ),
            child: product.imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: kIsWeb
                        ? Image.network(product.imagePath!, fit: BoxFit.cover)
                        : Image.file(File(product.imagePath!), fit: BoxFit.cover),
                  )
                : const Center(child: Icon(Icons.shopping_basket_outlined, size: 32, color: Color(0xFF1E2736))),
          ),
          const SizedBox(height: 8),
          Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.w600)),
          Text('฿${product.price.toStringAsFixed(0)}', style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (inCart > 0)
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20), onPressed: onRemove),
                    Text(inCart.toString(), style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
                    IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: onAdd),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E2736), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('เพิ่ม'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
