import CoinKit

struct PriceAlert {
    let coinType: CoinType
    let coinTitle: String
    var changeState: ChangeState
    var trendState: TrendState

    enum ChangeState: Int, CaseIterable {
        case off = 0
        case percent2 = 2
        case percent5 = 5
        case percent10 = 10

        init?(index: Int) {
            switch index {
            case 0: self = .off
            case 1: self = .percent2
            case 2: self = .percent5
            case 3: self = .percent10
            default: return nil
            }
        }

    }

    enum TrendState: String, CaseIterable {
        case off = "off"
        case short = "short"
        case long = "long"

        init?(index: Int) {
            switch index {
            case 0: self = .off
            case 1: self = .short
            case 2: self = .long
            default: return nil
            }
        }

    }

    private func changeTopic(coinCode: String) -> String {
        "\(coinCode)_24hour_\(changeState.rawValue)percent"
    }
    private func trendTopic(coinCode: String) -> String {
        "\(coinCode)_\(trendState.rawValue)term_trend_change"
    }

    func activeTopics(coinCode: String) -> Set<String> {
        var topics = Set<String>()
        if changeState != .off {
            topics.insert(changeTopic(coinCode: coinCode))
        }
        if trendState != .off {
            topics.insert(trendTopic(coinCode: coinCode))
        }
        return topics
    }

    mutating func updatePriceChange(stateIndex: Int) {
        guard let state = ChangeState(index: stateIndex) else {
            return
        }

        changeState = state
    }

    mutating func updateTrend(stateIndex: Int) {
        guard let state = TrendState(index: stateIndex) else {
            return
        }

        trendState = state
    }

}

extension PriceAlert.ChangeState: CustomStringConvertible {

    public var description: String {
        switch self {
        case .off: return "settings_notifications.alert_off".localized
        case .percent2: return "2%"
        case .percent5: return "5%"
        case .percent10: return "10%"
        }
    }

}

extension PriceAlert.TrendState: CustomStringConvertible {

    public var description: String {
        switch self {
        case .off: return "settings_notifications.alert_off".localized
        case .short: return "settings_notifications.trend_short".localized
        case .long: return "settings_notifications.trend_long".localized
        }
    }

}
