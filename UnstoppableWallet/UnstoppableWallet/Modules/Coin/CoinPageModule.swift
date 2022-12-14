import UIKit
import Chart
import LanguageKit

struct CoinPageModule {

    static func viewController(launchMode: ChartModule.LaunchMode) -> UIViewController {
        let coinPageService = CoinPageService(
                coinKit: App.shared.coinKit,
                rateManager: App.shared.rateManager,
                currencyKit: App.shared.currencyKit,
                appConfigProvider: App.shared.appConfigProvider,
                coinType: launchMode.coinType,
                coinTitle: launchMode.coinTitle,
                coinCode: launchMode.coinCode)

        let favoriteService = FavoriteService(favoritesManager: App.shared.favoritesManager)
        let coinFavoriteService = CoinFavoriteService(
                service: favoriteService,
                coinType: launchMode.coinType)

        let priceAlertService = CoinPriceAlertService(
                priceAlertManager: App.shared.priceAlertManager,
                localStorage: App.shared.localStorage,
                coinType: launchMode.coinType,
                coinTitle: launchMode.coinTitle)

        let coinChartService = CoinChartService(
                rateManager: App.shared.rateManager,
                chartTypeStorage: App.shared.localStorage,
                currencyKit: App.shared.currencyKit,
                coinType: launchMode.coinType)

        let chartFactory = CoinChartFactory(timelineHelper: TimelineHelper(), indicatorFactory: IndicatorFactory(), currentLocale: LanguageManager.shared.currentLocale)

        let coinPageViewModel = CoinPageViewModel(service: coinPageService)
        let favoriteViewModel = CoinFavoriteViewModel(service: coinFavoriteService)
        let priceAlertViewModel = CoinPriceAlertViewModel(service: priceAlertService)
        let coinChartViewModel = CoinChartViewModel(service: coinChartService, factory: chartFactory)

        return CoinPageViewController(
                viewModel: coinPageViewModel,
                favoriteViewModel: favoriteViewModel,
                priceAlertViewModel: priceAlertViewModel,
                chartViewModel: coinChartViewModel,
                configuration: ChartConfiguration.fullChart,
                urlManager: UrlManager(inApp: true)
        )
    }

}
