// lib/features/profile/models/payment_methods.dart

import 'package:flutter/foundation.dart';

/// Platform payment methods including commission percentage
class PaymentMethods {
  final String? jazzcashNumber;
  final String? jazzcashAccountTitle;
  final String? easypaisaNumber;
  final String? easypaisaAccountTitle;
  final String? bankName;
  final String? bankAccountTitle;
  final String? bankAccountNumber;
  final String? bankIban;
  final String? subscriptionPriceAmount;
  final String? subscriptionPriceCurrency;
  final double? commissionPercentage;
  final DateTime? updatedAt;

  PaymentMethods({
    this.jazzcashNumber,
    this.jazzcashAccountTitle,
    this.easypaisaNumber,
    this.easypaisaAccountTitle,
    this.bankName,
    this.bankAccountTitle,
    this.bankAccountNumber,
    this.bankIban,
    this.subscriptionPriceAmount,
    this.subscriptionPriceCurrency,
    this.commissionPercentage,
    this.updatedAt,
  });

  factory PaymentMethods.fromJson(Map<String, dynamic> json) {
    double? commission;
    try {
      final raw = json['commission_percentage'];
      if (raw != null && raw.toString().isNotEmpty) {
        commission = double.tryParse(raw.toString());
      }
    } catch (_) {
      commission = null;
    }

    return PaymentMethods(
      jazzcashNumber: json['jazzcash_number'] as String?,
      jazzcashAccountTitle: json['jazzcash_account_title'] as String?,
      easypaisaNumber: json['easypaisa_number'] as String?,
      easypaisaAccountTitle: json['easypaisa_account_title'] as String?,
      bankName: json['bank_name'] as String?,
      bankAccountTitle: json['bank_account_title'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankIban: json['bank_iban'] as String?,
      subscriptionPriceAmount: json['subscription_price_amount'] as String?,
      subscriptionPriceCurrency: json['subscription_price_currency'] as String?,
      commissionPercentage: commission,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (jazzcashNumber != null) 'jazzcash_number': jazzcashNumber,
      if (jazzcashAccountTitle != null)
        'jazzcash_account_title': jazzcashAccountTitle,
      if (easypaisaNumber != null) 'easypaisa_number': easypaisaNumber,
      if (easypaisaAccountTitle != null)
        'easypaisa_account_title': easypaisaAccountTitle,
      if (bankName != null) 'bank_name': bankName,
      if (bankAccountTitle != null) 'bank_account_title': bankAccountTitle,
      if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
      if (bankIban != null) 'bank_iban': bankIban,
      if (subscriptionPriceAmount != null)
        'subscription_price_amount': subscriptionPriceAmount,
      if (subscriptionPriceCurrency != null)
        'subscription_price_currency': subscriptionPriceCurrency,
      if (commissionPercentage != null)
        'commission_percentage': commissionPercentage!.toStringAsFixed(2),
    };
  }

  // Helper to get formatted commission display
  String get commissionDisplay {
    if (commissionPercentage == null) return 'Not set';
    return '${commissionPercentage!.toStringAsFixed(2)}%';
  }

  // Helper to check if commission is set
  bool get hasCommission => commissionPercentage != null;
}
