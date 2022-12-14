import UIKit
import PinKit

class LockScreenRouter: ILockScreenRouter {

    func reloadAppInterface() {
        UIApplication.shared.keyWindow?.set(newRootController: MainModule.instance())
    }

}

extension LockScreenRouter {

    static func module(pinKit: IPinKit, appStart: Bool) -> UIViewController {
        let router = LockScreenRouter()
        let presenter = LockScreenPresenter(router: router, appStart: appStart)

        let insets = UIEdgeInsets(top: 0, left: 0, bottom: .margin12x, right: 0)
        let unlockController = pinKit.unlockPinModule(delegate: presenter, biometryUnlockMode: .auto, insets: insets, cancellable: false, autoDismiss: !appStart)

        let viewController = LockScreenController(unlockViewController: unlockController)
        viewController.modalTransitionStyle = .crossDissolve

        return viewController
    }

}
