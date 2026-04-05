import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/wallet_model.dart';
import '../models/upi_transaction_model.dart';
import '../models/transaction_model.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Initialize wallet for new user
  Future<void> initializeWallet(String userId, String email) async {
    final walletRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('wallet')
        .doc('main');

    final walletDoc = await walletRef.get();
    if (!walletDoc.exists) {
      final upiId = '${email.split('@')[0]}@valuify';
      final wallet = WalletModel(
        id: 'main',
        userId: userId,
        balance: 10000.0, // Starting balance of ₹10,000
        upiId: upiId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await walletRef.set(wallet.toMap());
    }
  }

  // Get wallet
  Stream<WalletModel?> getWallet(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wallet')
        .doc('main')
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return WalletModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // Send money via UPI
  Future<Map<String, dynamic>> sendMoney({
    required String userId,
    required String recipientUpiId,
    required String recipientName,
    required double amount,
    required String categoryId,
    String? note,
  }) async {
    try {
      // Get current wallet balance
      final walletDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallet')
          .doc('main')
          .get();

      if (!walletDoc.exists) {
        return {'success': false, 'message': 'Wallet not found'};
      }

      final wallet = WalletModel.fromMap(walletDoc.data()!, walletDoc.id);

      // Check sufficient balance
      if (wallet.balance < amount) {
        return {'success': false, 'message': 'Insufficient balance'};
      }

      // Generate transaction ID
      final transactionId = 'UPI${DateTime.now().millisecondsSinceEpoch}';

      // Create UPI transaction record
      final upiTransaction = UpiTransactionModel(
        id: _uuid.v4(),
        userId: userId,
        type: 'send',
        amount: amount,
        recipientUpiId: recipientUpiId,
        recipientName: recipientName,
        note: note,
        status: 'success',
        transactionId: transactionId,
        createdAt: DateTime.now(),
      );

      // Update wallet balance
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallet')
          .doc('main')
          .update({
        'balance': wallet.balance - amount,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Save UPI transaction
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('upiTransactions')
          .doc(upiTransaction.id)
          .set(upiTransaction.toMap());

      // Create expense transaction
      final expenseTransaction = TransactionModel(
        id: _uuid.v4(),
        userId: userId,
        amount: amount,
        type: 'expense',
        categoryId: categoryId,
        date: DateTime.now(),
        merchant: recipientName,
        notes:
            'UPI Payment to $recipientUpiId${note != null ? ' - $note' : ''}',
        receiptUrl: null,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .add(expenseTransaction.toMap());

      return {
        'success': true,
        'message': 'Payment successful',
        'transactionId': transactionId,
        'newBalance': wallet.balance - amount,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Transaction failed: ${e.toString()}'
      };
    }
  }

  // Receive money (mock)
  Future<Map<String, dynamic>> receiveMoney({
    required String userId,
    required String senderUpiId,
    required String senderName,
    required double amount,
    required String categoryId,
    String? note,
  }) async {
    try {
      final walletDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallet')
          .doc('main')
          .get();

      if (!walletDoc.exists) {
        return {'success': false, 'message': 'Wallet not found'};
      }

      final wallet = WalletModel.fromMap(walletDoc.data()!, walletDoc.id);
      final transactionId = 'UPI${DateTime.now().millisecondsSinceEpoch}';

      // Create UPI transaction record
      final upiTransaction = UpiTransactionModel(
        id: _uuid.v4(),
        userId: userId,
        type: 'receive',
        amount: amount,
        recipientUpiId: senderUpiId,
        recipientName: senderName,
        note: note,
        status: 'success',
        transactionId: transactionId,
        createdAt: DateTime.now(),
      );

      // Update wallet balance
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallet')
          .doc('main')
          .update({
        'balance': wallet.balance + amount,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Save UPI transaction
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('upiTransactions')
          .doc(upiTransaction.id)
          .set(upiTransaction.toMap());

      // Create income transaction
      final incomeTransaction = TransactionModel(
        id: _uuid.v4(),
        userId: userId,
        amount: amount,
        type: 'income',
        categoryId: categoryId,
        date: DateTime.now(),
        merchant: senderName,
        notes:
            'UPI Received from $senderUpiId${note != null ? ' - $note' : ''}',
        receiptUrl: null,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .add(incomeTransaction.toMap());

      return {
        'success': true,
        'message': 'Payment received',
        'transactionId': transactionId,
        'newBalance': wallet.balance + amount,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Transaction failed: ${e.toString()}'
      };
    }
  }

  // Get UPI transaction history
  Stream<List<UpiTransactionModel>> getUpiTransactions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('upiTransactions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UpiTransactionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Add money to wallet (mock top-up)
  Future<void> addMoney(String userId, double amount) async {
    final walletDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('wallet')
        .doc('main')
        .get();

    if (walletDoc.exists) {
      final wallet = WalletModel.fromMap(walletDoc.data()!, walletDoc.id);
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallet')
          .doc('main')
          .update({
        'balance': wallet.balance + amount,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }
}
