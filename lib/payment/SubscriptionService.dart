import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionService {
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final List<String> productIds = [
    'test_plan',
    'montlhy_subs',
    'yearly_subs',
  ];

  List<ProductDetails> products = [];

  bool isSubscribed = false;

  Future<void> init() async {
    final bool available = await _iap.isAvailable();

    if (!available) {
      print("Store not available");
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      (purchaseDetailsList) {
        for (final purchase in purchaseDetailsList) {
          switch (purchase.status) {
            case PurchaseStatus.pending:
              print("⏳ Purchase Pending");
              break;

            case PurchaseStatus.purchased:
              print("✅ Purchase Successful");

              isSubscribed = true;

              break;

            case PurchaseStatus.error:
              print("❌ Purchase Failed");
              print(purchase.error);

              break;

            case PurchaseStatus.canceled:
              print("⚠️ Purchase Cancelled");

              break;

            case PurchaseStatus.restored:
              print("🔄 Purchase Restored");

              isSubscribed = true;

              break;
          }

          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
        }
      },
    );

    await loadProducts();
  }

  Future<void> loadProducts() async {
    final ProductDetailsResponse response =
        await _iap.queryProductDetails(productIds.toSet());

    if (response.notFoundIDs.isNotEmpty) {
      print("Products not found:");
      print(response.notFoundIDs);
    }

    products = response.productDetails;

    print("Products Loaded:");
    print(products.map((e) => e.id).toList());
  }

  Future<void> buySubscription(ProductDetails product) async {
    try {
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: product);

      await _iap.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      print("🚀 Purchase flow started");
    } catch (e) {
      print("Purchase Error: $e");
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();

    print("Restore Started");
  }

  void dispose() {
    _subscription?.cancel();
  }
}

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _service = SubscriptionService();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    init();
  }

  Future<void> init() async {
    await _service.init();

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _service.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upgrade Plan"),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _service.products.isEmpty
              ? const Center(
                  child: Text("No Plans Available"),
                )
              : Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      "Go Premium 🚀",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Unlock all premium features",
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _service.products.length,
                        itemBuilder: (context, index) {
                          final product = _service.products[index];

                          return planCard(product);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextButton(
                        onPressed: () async {
                          await _service.restorePurchases();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Restoring purchases...",
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Restore Purchases",
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget planCard(ProductDetails product) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.description,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                product.price,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _service.buySubscription(product);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Processing payment...",
                      ),
                    ),
                  );
                },
                child: const Text("Subscribe"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_service.isSubscribed)
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                "ACTIVE",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
