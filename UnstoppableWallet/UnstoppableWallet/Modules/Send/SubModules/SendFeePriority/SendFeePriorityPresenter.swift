import Foundation
import CurrencyKit
import CoinKit

class SendFeePriorityPresenter {
    weak var view: ISendFeePriorityView?
    weak var delegate: ISendFeePriorityDelegate?

    private let interactor: ISendFeePriorityInteractor
    private let router: ISendFeePriorityRouter
    private let feeRateAdjustmentHelper: FeeRateAdjustmentHelper
    private let coin: Coin

    private var feeRateAdjustmentInfo: FeeRateAdjustmentInfo
    private var customFeeRate: Int?
    private var fetchedFeeRate: Int?

    private var error: Error?
    private(set) var feeRatePriority: FeeRatePriority

    var feeRate: Int? {
        customFeeRate ?? fetchedFeeRate.flatMap { rate in
            feeRateAdjustmentHelper.applyRule(coinType: coin.type, feeRateAdjustmentInfo: feeRateAdjustmentInfo, feeRate: rate)
        }
    }

    init(interactor: ISendFeePriorityInteractor, router: ISendFeePriorityRouter, feeRateAdjustmentHelper: FeeRateAdjustmentHelper, coin: Coin) {
        self.interactor = interactor
        self.router = router
        self.feeRateAdjustmentHelper = feeRateAdjustmentHelper
        self.coin = coin

        feeRatePriority = interactor.defaultFeeRatePriority
        feeRateAdjustmentInfo = FeeRateAdjustmentInfo(amountInfo: .notEntered, xRate: nil, currency: interactor.baseCurrency, balance: nil)
    }

}

extension SendFeePriorityPresenter: ISendFeePriorityModule {

    var feeRateState: FeeRateState {
        if let error = error {
            return .error(error)
        }
        if let feeRate = feeRate {
            return .value(feeRate)
        }
        return .loading
    }

    func fetchFeeRate() {
        fetchedFeeRate = nil
        error = nil

        view?.set(enabled: false)

        interactor.syncFeeRate(priority: feeRatePriority)
    }

    func set(amountInfo: SendAmountInfo) {
        feeRateAdjustmentInfo.amountInfo = amountInfo
    }

    func set(xRate: Decimal?) {
        feeRateAdjustmentInfo.xRate = xRate
    }

    func set(balance: Decimal) {
        feeRateAdjustmentInfo.balance = balance
    }
}

extension SendFeePriorityPresenter: ISendFeePriorityViewDelegate {

    func onFeePrioritySelectorTap() {
        let items = interactor.feeRatePriorityList.map { priority in
            PriorityItem(
                    priority: priority,
                    selected: priority == feeRatePriority
            )
        }

        router.openPriorities(items: items) { [weak self] selectedItem in
            self?.updateFeeRatePriority(selectedItem: selectedItem)
        }
    }

    func selectCustom(feeRatePriority: FeeRatePriority) {
        self.feeRatePriority = feeRatePriority
        if case let .custom(value, _) = feeRatePriority {
            customFeeRate = value
        }

        delegate?.onUpdateFeePriority()
    }

    func onOpenFeeInfo() {
        router.openFeeInfo()
    }

    private func updateFeeRatePriority(selectedItem: PriorityItem) {
        if case let .custom(value: defaultValue, range: range) = selectedItem.priority {
            var value = feeRate ?? defaultValue                  // set feeRate from previous choice when select to custom slider
            value = min(value, range.upperBound)                 // value can't be more than slider upper range
            feeRatePriority = .custom(value: value, range: range)

            view?.set(customVisible: true)
            view?.set(customFeeRateValue: value, customFeeRateRange: range)
            view?.setPriority()

            delegate?.onUpdateFeePriority()
        } else {
            customFeeRate = nil
            feeRatePriority = selectedItem.priority

            view?.set(customVisible: false)
            view?.setPriority()

            fetchFeeRate()
        }
    }

}

extension SendFeePriorityPresenter: ISendFeePriorityInteractorDelegate {

    func didUpdate(feeRate: Int) {
        fetchedFeeRate = feeRate

        view?.set(enabled: true)

        delegate?.onUpdateFeePriority()
    }

    func didReceiveError(error: Error) {
        self.error = error.convertedError

        delegate?.onUpdateFeePriority()
    }

}
