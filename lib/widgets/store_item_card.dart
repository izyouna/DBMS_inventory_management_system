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
            height: 60,
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
                        : Image.file(File(product.imagePath!),key: ValueKey(product.imagePath!), fit: BoxFit.cover),
                  )
                : const Center(
                    child: Icon(
                      Icons.shopping_basket_outlined,
                      size: 32,
                      color: Color(0xFF1E2736),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.prompt(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '฿${product.price.toStringAsFixed(0)}',
            style: GoogleFonts.prompt(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E2736),
            ),
          ),
          const SizedBox(height: 2),
          product.stock == 0
              ? Text(
                  'ของหมด',
                  style: GoogleFonts.prompt(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(
                  'คงเหลือ: ${product.stock}',
                  style: GoogleFonts.prompt(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (inCart > 0)
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: onRemove,
                    ),
                    Text(
                      inCart.toString(),
                      style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: product.stock <= inCart ? null : onAdd,
                    ),
                  ],
                )
              else
                TextButton(
                  onPressed: product.stock == 0 ? null : onAdd,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: product.stock == 0
                        ? Colors.grey
                        : const Color.fromARGB(255, 30, 39, 54),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('เพิ่ม', style: GoogleFonts.prompt(fontSize: 13)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
