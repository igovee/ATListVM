//
//  ManualBehaviorDemos.swift
//  ATListVM_Example
//
//  手动布局的行为演示：四个 reload/refresh block，以及选中与显示回调。
//

import UIKit
import ATListVM
import SnapKit

// MARK: - 刷新与 reload

final class ReloadDemoListVM: ATListVM {
    let section = ATListSectionVM()

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(DemoTextCell.self, forCellWithReuseIdentifier: DemoTextCell.reuseId)
    }

    override func createData() {
        let width = UIScreen.main.bounds.width - 32
        section.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        section.minimumLineSpacing = 10
        section.itemVMs = (1...3).map { index in
            let item = DemoTextItemVM()
            item.title = "第 \(index) 条"
            item.subtitle = "itemSize 高度 64"
            item.itemSize = CGSize(width: width, height: 64)
            return item
        }
        viewProxy.sectionVMs = [section]
    }

    func firstItem() -> DemoTextItemVM? {
        section.itemVMs.first as? DemoTextItemVM
    }

    func makeItem(_ title: String) -> DemoTextItemVM {
        let width = UIScreen.main.bounds.width - 32
        let item = DemoTextItemVM()
        item.title = title
        item.subtitle = "itemSize 高度 64"
        item.itemSize = CGSize(width: width, height: 64)
        return item
    }
}

final class ReloadDemoViewController: UIViewController {

    private let listVM = ReloadDemoListVM()
    private let statusLabel = UILabel()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .systemBackground
        view.config(listVM: listVM)
        view.config(viewProxy: listVM.viewProxy)
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "刷新与 reload"
        view.backgroundColor = .systemBackground

        let refreshBtn = makeButton("refresh 只改文案", #selector(refreshText))
        let reloadItemBtn = makeButton("reloadItem 改高度", #selector(reloadItemHeight))
        let reloadSectionBtn = makeButton("追加 + reloadSection", #selector(appendThenReloadSection))
        let reloadListBtn = makeButton("reloadList 整表重来", #selector(resetList))
        let stack = UIStackView(arrangedSubviews: [refreshBtn, reloadItemBtn, reloadSectionBtn, reloadListBtn])
        stack.axis = .vertical
        stack.spacing = 8

        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        statusLabel.text = "refresh 只改可见 cell；改高度必须 reloadItem；加行必须 reloadSection。"

        view.addSubview(stack)
        view.addSubview(statusLabel)
        view.addSubview(collectionView)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(stack.snp.bottom).offset(8)
            make.leading.trailing.equalTo(stack)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }

        listVM.createData()
        listVM.reloadData()
    }

    private func makeButton(_ title: String, _ action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func refreshText() {
        guard let item = listVM.firstItem() else { return }
        item.title = "文案已改（走 refreshItemBlock）"
        item.refreshItemBlock?()
        statusLabel.text = "refresh：可见 cell 的文案变了，行高不变，不会重新测量。"
    }

    @objc private func reloadItemHeight() {
        guard let item = listVM.firstItem() else { return }
        // 从当前 itemSize 推导下一次高度，不要用外部开关：resetList 之后开关会和实际高度失步
        let height: CGFloat = item.itemSize.height >= 120 ? 64 : 120
        item.title = "高度改成 \(Int(height))pt（走 reloadItemBlock）"
        item.subtitle = "itemSize 高度 \(Int(height))"
        item.itemSize = CGSize(width: item.itemSize.width, height: height)
        item.reloadItemBlock?()
        statusLabel.text = "reloadItem：这一条按新的 itemSize 重新加载。"
    }

    @objc private func appendThenReloadSection() {
        let count = listVM.section.itemVMs.count
        listVM.section.itemVMs.append(listVM.makeItem("追加的第 \(count + 1) 条"))
        listVM.section.reloadSectionBlock?()
        statusLabel.text = "reloadSection：整段重建，新行才会出现。"
    }

    @objc private func resetList() {
        listVM.section.itemVMs = (1...3).map { listVM.makeItem("重置后的第 \($0) 条") }
        listVM.section.reloadListBlock?()
        statusLabel.text = "reloadList：整表 reloadData。"
    }
}

// MARK: - 选中与显示回调

final class CallbackItemVM: DemoTextItemVM {
    var onEvent: ((String) -> Void)?

    override func willDisplay() {
        onEvent?("itemVM.willDisplay  \(title)")
    }

    override func didEndDisplaying() {
        onEvent?("itemVM.didEndDisplaying  \(title)")
    }
}

final class CallbackListVM: ATListVM {
    var onEvent: ((String) -> Void)?
    let origin = Date()

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(DemoTextCell.self, forCellWithReuseIdentifier: DemoTextCell.reuseId)
    }

    override func createData() {
        let section = ATListSectionVM()
        section.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        section.minimumLineSpacing = 8
        let width = UIScreen.main.bounds.width - 32
        section.itemVMs = (1...12).map { index in
            let item = CallbackItemVM()
            item.title = "第 \(index) 条"
            item.subtitle = "试试点它，或者上下滚动看 willDisplay"
            item.background = UIColor.systemOrange.withAlphaComponent(0.12)
            item.itemSize = CGSize(width: width, height: 88)
            item.onEvent = { [weak self] message in
                self?.onEvent?(message)
            }
            item.onSelectItemBlock = { [weak self] _, _, itemVM in
                self?.onEvent?("onSelectItemBlock  \((itemVM as? DemoTextItemVM)?.title ?? "")")
            }
            return item
        }
        viewProxy.sectionVMs = [section]
    }

    /// 把经过的时间塞进 msg，证明 delegate 真的被调到了。
    func state(_ name: String) -> String {
        String(format: "%.1fs", Date().timeIntervalSince(origin)) + "  " + name
    }
}

final class CallbackDemoViewController: UIViewController, ATListViewProxyDelegate, ATListVMDelegate {

    private let listVM = CallbackListVM()
    private let logLabel = UILabel()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .systemBackground
        view.config(listVM: listVM)
        view.config(viewProxy: listVM.viewProxy)
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "选中与显示回调"
        view.backgroundColor = .systemBackground
        listVM.delegate = self
        listVM.viewProxy.delegate = self
        listVM.onEvent = { [weak self] message in
            self?.show(message)
        }

        let stateBtn = makeButton("触发 listVMDidChange", #selector(fireState))
        logLabel.font = .systemFont(ofSize: 12)
        logLabel.textColor = .secondaryLabel
        logLabel.numberOfLines = 2
        logLabel.text = "滚动或点击，这里显示最后一条回调"

        view.addSubview(stateBtn)
        view.addSubview(logLabel)
        view.addSubview(collectionView)
        stateBtn.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        logLabel.snp.makeConstraints { make in
            make.top.equalTo(stateBtn.snp.bottom).offset(8)
            make.leading.trailing.equalTo(stateBtn)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(logLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }

        listVM.createData()
        listVM.reloadData()
    }

    private func makeButton(_ title: String, _ action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    func listViewProxy(collectionView: UICollectionView, cellWillDisplay: UICollectionViewCell, indexPath: IndexPath) {
        show("proxy cellWillDisplay  [\(indexPath.section), \(indexPath.item)]")
    }

    func listViewProxy(collectionView: UICollectionView, cellDidEndDisplaying: UICollectionViewCell, indexPath: IndexPath) {
        show("proxy cellDidEndDisplaying  [\(indexPath.section), \(indexPath.item)]")
    }

    func listVMDidChange(state: ATListVMState, tag: Int, msg: String?, err: Error?) {
        show("listVMDidChange  tag=\(tag)  \(msg ?? "")")
    }

    @objc private func fireState() {
        listVM.listVMDidChange(state: .success, tag: 1, msg: listVM.state("手动触发一次状态回调"), err: nil)
    }

    private func show(_ message: String) {
        logLabel.text = message
    }
}

// MARK: - 菜单条目

enum ManualBehaviorDemos {
    static let entries: [DemoEntry] = [
        DemoEntry(title: "刷新与 reload",
                  detail: "refreshItemBlock / reloadItemBlock / reloadSectionBlock / reloadListBlock",
                  make: { ReloadDemoViewController() }),
        DemoEntry(title: "选中与显示回调",
                  detail: "onSelectItemBlock、itemVM.willDisplay、proxy delegate、listVMDidChange",
                  make: { CallbackDemoViewController() })
    ]
}
