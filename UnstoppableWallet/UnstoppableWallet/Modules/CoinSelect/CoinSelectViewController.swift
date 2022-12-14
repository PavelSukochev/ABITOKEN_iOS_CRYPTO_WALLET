import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import CoinKit

class CoinSelectViewController: ThemeSearchViewController {
    private let viewModel: CoinSelectViewModel
    private weak var delegate: ICoinSelectDelegate?
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private var viewItems = [CoinSelectViewModel.ViewItem]()

    init(viewModel: CoinSelectViewModel, delegate: ICoinSelectDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate

        super.init(scrollView: tableView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "choose_coin.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: SwapTokenSelectCell.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        navigationItem.searchController?.searchBar.placeholder = "placeholder.search".localized

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.handle(viewItems: $0) }
    }

    @objc func onTapClose() {
        dismiss(animated: true)
    }

    private func onSelect(coin: Coin) {
        delegate?.didSelect(coin: coin)

        if navigationItem.searchController?.isActive ?? false {
            dismiss(animated: false)
        }

        dismiss(animated: true)
    }

    private func handle(viewItems: [CoinSelectViewModel.ViewItem]) {
        self.viewItems = viewItems

        tableView.reload()
    }

    override func onUpdate(filter: String?) {
        viewModel.apply(filter: filter)
    }

}

extension CoinSelectViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "coins",
                    headerState: .margin(height: .margin3x),
                    footerState: .margin(height: .margin8x),
                    rows: viewItems.enumerated().map { index, viewItem in
                        let isLast = index == viewItems.count - 1

                        return Row<SwapTokenSelectCell>(
                                id: "coin_\(viewItem.coin.id)",
                                height: .heightDoubleLineCell,
                                autoDeselect: true,
                                bind: { cell, _ in
                                    cell.set(backgroundStyle: .claude, isLast: isLast)
                                    cell.bind(
                                            coin: viewItem.coin,
                                            balance: viewItem.balance
                                    )
                                },
                                action: { [weak self] _ in
                                    self?.onSelect(coin: viewItem.coin)
                                }
                        )
                    }
            )
        ]
    }

}
