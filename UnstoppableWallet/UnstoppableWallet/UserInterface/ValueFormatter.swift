import Foundation
import CurrencyKit

class ValueFormatter {
    static let instance = ValueFormatter()

    enum FractionPolicy {
        case full
        case threshold(high: Decimal, low: Decimal)
    }

    private let coinFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    private let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    func format(coinValue: CoinValue, fractionPolicy: FractionPolicy = .full) -> String? {
        format(value: coinValue.value, decimalCount: coinValue.coin.decimal, symbol: coinValue.coin.code, fractionPolicy: fractionPolicy)
    }

    func format(value: Decimal, decimalCount: Int, symbol: String, fractionPolicy: FractionPolicy = .full) -> String? {
        let absoluteValue = abs(value)

        let formatter = coinFormatter
        formatter.roundingMode = .halfUp

        switch fractionPolicy {
        case .full:
            formatter.maximumFractionDigits = min(decimalCount, 8)
        case let .threshold(high, _):
            formatter.maximumFractionDigits = absoluteValue > high ? 4 : 8
        }

        guard let formattedValue = formatter.string(from: absoluteValue as NSNumber) else {
            return nil
        }

        var result = "\(formattedValue) \(symbol)"

        if value.isSignMinus {
            result = "- \(result)"
        }

        return result
    }

    func format(currencyValue: CurrencyValue, fractionPolicy: FractionPolicy = .full, trimmable: Bool = true, roundingMode: NumberFormatter.RoundingMode = .halfUp) -> String? {
        var absoluteValue = abs(currencyValue.value)

        let formatter = currencyFormatter
        formatter.roundingMode = roundingMode
        formatter.currencyCode = currencyValue.currency.code
        formatter.currencySymbol = currencyValue.currency.symbol

        var showSmallSign = false

        switch fractionPolicy {
        case .full:
            formatter.maximumFractionDigits = currencyValue.currency.decimal
            formatter.minimumFractionDigits = currencyValue.currency.decimal
        case let .threshold(high, low):
            if trimmable {
                formatter.maximumFractionDigits = absoluteValue > high ? 0 : 2
            } else {
                formatter.maximumFractionDigits = absoluteValue.significantDecimalCount(threshold: high, maxDecimals: 8)
            }
            formatter.minimumFractionDigits = 0

            if absoluteValue > 0 && absoluteValue < low && trimmable {
                absoluteValue = low
                showSmallSign = true
            }
        }

        guard var result = formatter.string(from: absoluteValue as NSNumber) else {
            return nil
        }

        if showSmallSign {
            result = "< \(result)"
        }

        if currencyValue.value.isSignMinus {
            result = "- \(result)"
        }

        return result
    }

    func format(percentValue: Decimal, signed: Bool = true) -> String? {
        let plusSign = (percentValue >= 0 && signed) ? "+" : ""

        let formattedDiff = percentFormatter.string(from: percentValue as NSNumber)
        return formattedDiff.map { plusSign + $0 + "%" }
    }

}
