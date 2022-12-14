import Foundation
import ZcashLightClientKit
import RxSwift

class ZcashTransactionPool {
    private var confirmedTransactions = Set<ZcashTransaction>()
    private var pendingTransactions = Set<ZcashTransaction>()

    private var transactions: [ZcashTransaction] {
        Array(confirmedTransactions.union(pendingTransactions)).sorted()
    }

    private func zcashTransactions(_ transactions: [SignedTransactionEntity]) -> [ZcashTransaction] {
        transactions.compactMap { tx in
            switch tx {
            case let tx as PendingTransactionEntity: return ZcashTransaction(pendingTransaction: tx)
            case let tx as ConfirmedTransactionEntity: return ZcashTransaction(confirmedTransaction: tx)
            default: return nil
            }
        }
    }

    @discardableResult private func sync(own: inout Set<ZcashTransaction>, incoming: [ZcashTransaction]) -> [ZcashTransaction] {
        var newTxs = [ZcashTransaction]()
        incoming.forEach { transaction in
            if own.insert(transaction).inserted {
                newTxs.append(transaction)
            }
        }
        return newTxs
    }

    func store(confirmedTransactions: [ConfirmedTransactionEntity], pendingTransactions: [PendingTransactionEntity]) {
        self.pendingTransactions = Set(zcashTransactions(pendingTransactions))
        self.confirmedTransactions = Set(zcashTransactions(confirmedTransactions))
    }

    func sync(transactions: [PendingTransactionEntity]) -> [ZcashTransaction] {
        sync(own: &pendingTransactions, incoming: zcashTransactions(transactions))
    }

    func sync(transactions: [ConfirmedTransactionEntity]) -> [ZcashTransaction] {
        sync(own: &confirmedTransactions, incoming: zcashTransactions(transactions))
    }

    func transaction(by hash: String) -> ZcashTransaction? {
        transactions.first { $0.transactionHash == hash }
    }

}

extension ZcashTransactionPool {

    func transactionsSingle(from: TransactionRecord?, limit: Int) -> Single<[ZcashTransaction]> {
        let transactions = self.transactions

        guard let transaction = from else {
            return Single.just(Array(transactions.prefix(limit)))
        }

        if let index = transactions.firstIndex(where: { $0.transactionHash == transaction.transactionHash }) {
            return Single.just((Array(transactions.suffix(from: index + 1).prefix(limit))))
        }
        return Single.just([])
    }

}
