import 'package:flutter/material.dart';

import 'SubscriptionService.dart';

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

    print(_service.products.map((e) => e.id).toList());
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
          ? const Center(child: CircularProgressIndicator())
          : _service.products.isEmpty
          ? const Center(child: Text("No Plans Available"))
          : Column(
        children: [
          const SizedBox(height: 20),

          /// HEADER
          const Text(
            "Go Premium 🚀",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Unlock all features with premium subscription",
            style: TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 20),

          /// PLAN LIST
          Expanded(
            child: ListView.builder(
              itemCount: _service.products.length,
              itemBuilder: (context, index) {
                final product = _service.products[index];

                return _planCard(product);
              },
            ),
          ),

          /// RESTORE BUTTON (Important for iOS)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton(
              onPressed: () async {
                await _service.restorePurchases();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Restoring purchases...")),
                );
              },
              child: const Text("Restore Purchases"),
            ),
          )
        ],
      ),
    );
  }

  /// PLAN CARD UI
  Widget _planCard(product) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          Text(
            product.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          /// DESCRIPTION
          Text(
            product.description,
            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                product.price,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              ElevatedButton(
                onPressed: () async {
                  await _service.buySubscription(product);

                  print("Payment flow started");

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Processing payment..."),
                    ),
                  );
                },
                child: const Text("Subscribe"),
              ),
            ],
          ),

          /// ACTIVE TAG
          if (_service.isSubscribed)
            const Align(
              alignment: Alignment.topRight,
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