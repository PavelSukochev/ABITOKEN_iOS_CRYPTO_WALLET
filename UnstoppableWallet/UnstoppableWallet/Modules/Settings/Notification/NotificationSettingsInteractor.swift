import RxSwift
import CoinKit

class NotificationSettingsInteractor {
    weak var delegate: INotificationSettingsInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let priceAlertManager: IPriceAlertManager
    private let notificationManager: INotificationManager
    private let coinManager: ICoinManager

    private let localStorage: ILocalStorage

    init(priceAlertManager: IPriceAlertManager, notificationManager: INotificationManager, appManager: IAppManager, coinManager: ICoinManager, localStorage: ILocalStorage) {
        self.priceAlertManager = priceAlertManager
        self.notificationManager = notificationManager
        self.coinManager = coinManager
        self.localStorage = localStorage

        appManager.willEnterForegroundObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.delegate?.didEnterForeground()
                })
                .disposed(by: disposeBag)

        priceAlertManager.updateObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.delegate?.onAlertsUpdate()
                })
                .disposed(by: disposeBag)
    }

}

extension NotificationSettingsInteractor: INotificationSettingsInteractor {

    var pushNotificationsOn: Bool {
        get {
            localStorage.pushNotificationsOn
        }
        set {
            localStorage.pushNotificationsOn = newValue
        }
    }

    var alerts: [PriceAlert] {
        priceAlertManager.priceAlerts
    }

    var apnsTokenReceived: Bool {
        notificationManager.token != nil
    }

    func coin(coinType: CoinType) -> Coin? {
        coinManager.coin(type: coinType)
    }

    func updateTopics() {
        priceAlertManager.updateTopics()
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(MainScheduler.instance)
                .subscribe(onError: { [weak self] error in
                    self?.delegate?.didFailUpdateTopics(error: error)
                }, onCompleted: { [weak self] in
                    self?.delegate?.didUpdateTopics()
                })
                .disposed(by: disposeBag)
    }

    func requestPermission(needUpdate: Bool) {
        notificationManager.requestPermission { [weak self] granted in
            if granted {
                self?.delegate?.didGrantPermission(needUpdate: needUpdate)
            } else {
                self?.delegate?.didDenyPermission()
            }
        }
    }

    func deleteAllAlerts() {
        priceAlertManager.deleteAllAlerts()
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] in
                    self?.delegate?.didSaveAlerts()
                }, onError: { [weak self] error in
                    self?.delegate?.didFailSaveAlerts(error: error)
                })
                .disposed(by: disposeBag)
    }

}
