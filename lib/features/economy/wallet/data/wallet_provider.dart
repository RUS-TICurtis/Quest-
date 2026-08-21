import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'wallet_models.dart';

final walletProvider = Provider<WalletRepository>((ref) {
  return WalletRepository();
});

class WalletRepository {
  Wallet getMockWallet(String userId) {
    return Wallet(
      userId: userId,
      fiatBalance: 150.50,
      questCoinBalance: 2400.0,
      recentTransactions: [
        Transaction(
          id: 't1',
          userId: userId,
          amount: 50.0,
          currency: CurrencyType.questCoin,
          type: TransactionType.reward,
          description: 'Completed onboarding quest',
          timestamp: DateTime.now().subtract(Duration(hours: 2)),
        ),
        Transaction(
          id: 't2',
          userId: userId,
          amount: -45.0,
          currency: CurrencyType.fiat,
          type: TransactionType.purchase,
          description: 'Quest Official Hoodie',
          relatedEntityId: 'c3', // Listing ID
          timestamp: DateTime.now().subtract(Duration(days: 2)),
        ),
        Transaction(
          id: 't3',
          userId: userId,
          amount: 100.0,
          currency: CurrencyType.fiat,
          type: TransactionType.deposit,
          description: 'Added funds from bank account',
          timestamp: DateTime.now().subtract(Duration(days: 5)),
        ),
      ],
    );
  }
}
