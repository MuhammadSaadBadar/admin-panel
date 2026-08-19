/// Platform payment methods returned by `GET /api/v1/accounts/payment-methods/`.
///
/// Mirrors the `PlatformPaymentMethod` schema in `Mama Health API.yaml`. The
/// admin configures these (JazzCash / EasyPaisa / bank details and the price
/// shown to patients) via `PATCH /accounts/payment-methods/`; patients read
/// them to know where to send their manual payment.
///
/// IMPORTANT: Never hardcode these details in the UI — always render whatever
/// the API returns. A blank field means that method is not configured and the
/// app should hide it.
class PlatformPaymentMethods {
  final String jazzcashNumber;
  final String jazzcashAccountTitle;
  final String easypaisaNumber;
  final String easypaisaAccountTitle;
  final String bankName;
  final String bankAccountTitle;
  final String bankAccountNumber;
  final String bankIban;
  final String? subscriptionPriceAmount;
  final String subscriptionPriceCurrency;
  final DateTime? updatedAt;

  const PlatformPaymentMethods({
    this.jazzcashNumber = '',
    this.jazzcashAccountTitle = '',
    this.easypaisaNumber = '',
    this.easypaisaAccountTitle = '',
    this.bankName = '',
    this.bankAccountTitle = '',
    this.bankAccountNumber = '',
    this.bankIban = '',
    this.subscriptionPriceAmount,
    this.subscriptionPriceCurrency = 'PKR',
    this.updatedAt,
  });

  factory PlatformPaymentMethods.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['subscription_price_amount'];
    return PlatformPaymentMethods(
      jazzcashNumber: _asString(json['jazzcash_number']),
      jazzcashAccountTitle: _asString(json['jazzcash_account_title']),
      easypaisaNumber: _asString(json['easypaisa_number']),
      easypaisaAccountTitle: _asString(json['easypaisa_account_title']),
      bankName: _asString(json['bank_name']),
      bankAccountTitle: _asString(json['bank_account_title']),
      bankAccountNumber: _asString(json['bank_account_number']),
      bankIban: _asString(json['bank_iban']),
      subscriptionPriceAmount: rawPrice == null || rawPrice.toString().isEmpty
          ? null
          : rawPrice.toString(),
      subscriptionPriceCurrency: _asString(json['subscription_price_currency']),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  /// Whether a JazzCash method is configured (non-empty number).
  bool get hasJazzcash => jazzcashNumber.isNotEmpty;

  /// Whether an EasyPaisa method is configured (non-empty number).
  bool get hasEasypaisa => easypaisaNumber.isNotEmpty;

  /// Whether a bank method is configured (non-empty account number).
  bool get hasBank => bankAccountNumber.isNotEmpty;

  /// Whether any payment method is configured at all.
  bool get hasAnyMethod => hasJazzcash || hasEasypaisa || hasBank;

  /// Whether an explicit price is published for patients to pay.
  bool get hasPrice => subscriptionPriceAmount != null;
}
