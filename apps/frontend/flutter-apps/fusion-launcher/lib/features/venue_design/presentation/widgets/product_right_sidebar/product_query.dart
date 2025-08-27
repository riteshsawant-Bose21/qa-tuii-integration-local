import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ProductQuery extends StatelessWidget {
  const ProductQuery({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        /// Search and filter section
        const ProductQuerySection(),
        const SizedBox(height: 8),

        /// Product list
        ListView.separated(
          separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: products.length,
          itemBuilder: (BuildContext context, int index) {
            return ProductCard(product: products[index]);
          },
        ),
      ],
    );
  }
}

/// Search and filter section
class ProductQuerySection extends StatelessWidget {
  const ProductQuerySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      height: 32,
      child: FusionTextField(
        hintText: 'Search',
        prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 16),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.filter_list, color: Colors.grey[600], size: 16),
            const SizedBox(width: 8),
            Icon(Icons.sort, color: Colors.grey[600], size: 16),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// Product image
          const FusionImage.asset(
            "apps/frontend/flutter-apps/fusion-launcher/assets/images/speakers/freespace_designmax_1.png",
            width: 64,
            height: 64,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                /// Product name
                FusionAppText(
                  text: product.name,
                  maxLine: 1,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    // color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                    // letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 2),

                /// Product type
                FusionAppText(
                  text: "type",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    // color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                    // letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),

                /// Product price
                FusionCurrencyText(
                  text: product.price,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.greyDark,
                    fontWeight: FontWeight.w400,
                    // letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Product {
  const Product({
    required this.name,
    required this.price,
    required this.image,
  });

  final String name;
  final String price;
  final String image;
}

final List<Product> products = const <Product>[
  Product(
    name: 'DesignMax DM8SE Loudspeaker',
    price: '246.99',
    image: 'assets/dm8se.png',
  ),
  Product(
    name: 'DesignMax DM6C Loudspeakers (1 pair)',
    price: '246.99',
    image: 'assets/dm6c.png',
  ),
  Product(
    name: 'EdgeMax EM180-LP Loudspeaker',
    price: '246.99',
    image: 'assets/em180lp.png',
  ),
  Product(
    name: 'DesignMax DM8C-SUB Subwoofer',
    price: '246.99',
    image: 'assets/dm8c_sub.png',
  ),
  Product(
    name: 'DesignMax DM8SE Loudspeaker',
    price: '246.99',
    image: 'assets/dm8se2.png',
  ),
  Product(
    name: 'DesignMax DM6C Loudspeakers (1 pair)',
    price: '246.99',
    image: 'assets/dm6c2.png',
  ),
  Product(
    name: 'EdgeMax EM180-LP Loudspeaker',
    price: '246.99',
    image: 'assets/em180lp.png',
  ),
  Product(
    name: 'DesignMax DM8C-SUB Subwoofer',
    price: '246.99',
    image: 'assets/dm8c_sub.png',
  ),
  Product(
    name: 'DesignMax DM8SE Loudspeaker',
    price: '246.99',
    image: 'assets/dm8se2.png',
  ),
  Product(
    name: 'DesignMax DM6C Loudspeakers (1 pair)',
    price: '246.99',
    image: 'assets/dm6c2.png',
  ),
  Product(
    name: 'EdgeMax EM180-LP Loudspeaker',
    price: '246.99',
    image: 'assets/em180lp.png',
  ),
  Product(
    name: 'DesignMax DM8C-SUB Subwoofer',
    price: '246.99',
    image: 'assets/dm8c_sub.png',
  ),
  Product(
    name: 'DesignMax DM8SE Loudspeaker',
    price: '246.99',
    image: 'assets/dm8se2.png',
  ),
  Product(
    name: 'DesignMax DM6C Loudspeakers (1 pair)',
    price: '246.99',
    image: 'assets/dm6c2.png',
  ),
  Product(
    name: 'EdgeMax EM180-LP Loudspeaker',
    price: '246.99',
    image: 'assets/em180lp.png',
  ),
  Product(
    name: 'DesignMax DM8C-SUB Subwoofer',
    price: '246.99',
    image: 'assets/dm8c_sub.png',
  ),
  Product(
    name: 'DesignMax DM8SE Loudspeaker',
    price: '246.99',
    image: 'assets/dm8se2.png',
  ),
  Product(
    name: 'DesignMax DM6C Loudspeakers (1 pair)',
    price: '246.99',
    image: 'assets/dm6c2.png',
  ),
];
