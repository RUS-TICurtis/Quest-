enum TransactionType {
  deposit,
  withdrawal,
  purchase,
  sale,
  reward, // e.g., Quest Coins earned
}

enum CurrencyType {
  fiat, // e.g., USD
  questCoin, // In-app token
}

class Transaction {
  final String id;
  final String userId;
  final double amount;
  final CurrencyType currency;
  final TransactionType type;
  final String description;
  final String? relatedEntityId; // e.g., Listing ID or Opportunity ID
  final DateTime timestamp;

  Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.description,
    this.relatedEntityId,
    required this.timestamp,
  });
}

class Wallet {
  final String userId;
  final double fiatBalance; // e.g., USD
  final double questCoinBalance; // In-app points
  final List<Transaction> recentTransactions;

  Wallet({
    required this.userId,
    this.fiatBalance = 0.0,
    this.questCoinBalance = 0.0,
    this.recentTransactions = const [],
  });
}
