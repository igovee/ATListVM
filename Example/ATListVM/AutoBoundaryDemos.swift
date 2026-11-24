//
//  AutoBoundaryDemos.swift
//  ATListVM_Example
//
//  自动布局的边界情况：增量插入、超长列表、极端高度、整表重载。
//

import UIKit
import ATListVM
import SnapKit

// MARK: - 公用 cell：正文不限行数，才能真的看到 1/2/3 行的行高差异

final class BoundaryTextItemVM: ATListItemVM {
    var title = ""
    var body = ""

    override func setupData() {
        super.setupData()
        cellId = BoundaryTextCell.reuseId
    }
}

final class BoundaryTextCell: ATListCell {
    static let reuseId = "BoundaryTextCell"

    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()

    override func setupSubviews() {
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.10)
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        bodyLabel.font = .systemFont(ofSize: 13)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)
        contentView.addSubview(bodyLabel)
    }

    override func setupLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-10)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let item = itemVM as? BoundaryTextItemVM else { return }
        titleLabel.text = item.title
        bodyLabel.text = item.body
    }
}

/// 生成 1~3 行正文：每行都是独立一整行，行数靠换行符控制，不依赖文字长度。
func boundaryBody(lines: Int) -> String {
    Array(repeating: "这一行是一整行的说明文字，用来撑满一行。", count: max(1, lines)).joined(separator: "\n")
}

// MARK: - 1. insert / append 三种用法

final class InsertDemoListVM: ATListVM {

    private var counter = 0

    override init() { super.init(viewProxy: ATListViewAutoProxy()) }

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(DemoTextCell.self, forCellWithReuseIdentifier: DemoTextCell.reuseId)
    }

    override func createData() {
        let sec = ATListSectionVM()
        sec.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        sec.minimumLineSpacing = 8
        sec.itemVMs = (1...6).map { _ in makeItem("原有条目") }
        viewProxy.sectionVMs = [sec]
    }

    private func makeItem(_ title: String) -> DemoTextItemVM {
        counter += 1
        let item = DemoTextItemVM()
        item.title = "\(title) #\(counter)"
        item.subtitle = "用于观察插入位置的一行说明。"
        return item
    }

    func appendAtEnd() -> String {
        guard let sec = viewProxy.sectionVMs.first else { return "" }
        let at = sec.itemVMs.count
        sec.append(makeItem("新增 · 末尾"))
        return "append(index \(at)) → 共 \(sec.itemVMs.count) 条"
    }

    func insertInMiddle() -> String {
        guard let sec = viewProxy.sectionVMs.first else { return "" }
        let at = max(0, sec.itemVMs.count / 2)
        sec.insert(makeItem("新增 · 中间"), at: at)
        let next = at + 1 < sec.itemVMs.count ? sec.itemVMs[at + 1] : nil
        let nextPath = next?.indexPath.map { "[\($0.section), \($0.item)]" } ?? "nil"
        return "insert(at: \(at)) → 共 \(sec.itemVMs.count) 条；下一条 indexPath = \(nextPath)"
    }

    func appendTwiceInOneTurn() -> String {
        guard let sec = viewProxy.sectionVMs.first else { return "" }
        sec.append(makeItem("连续新增 A"))
        sec.append(makeItem("连续新增 B"))
        let last2 = sec.itemVMs.suffix(2).compactMap { ($0 as? DemoTextItemVM)?.title }
        return "两次 append → 共 \(sec.itemVMs.count) 条，最后两条：\(last2.joined(separator: " / "))"
    }
}

final class InsertDemoViewController: UIViewController {

    private let listVM = InsertDemoListVM()
    private let noteLabel = UILabel()
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
        title = "insert / append"
        view.backgroundColor = .systemBackground

        let endBtn = makeButton("末尾追加", tag: 0)
        let midBtn = makeButton("中间插入", tag: 1)
        let twiceBtn = makeButton("同轮两次 append", tag: 2)
        let row = UIStackView(arrangedSubviews: [endBtn, midBtn, twiceBtn])
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 4

        // 警告常驻在 noteLabel，不随点击被覆盖
        noteLabel.font = .systemFont(ofSize: 12)
        noteLabel.textColor = .secondaryLabel
        noteLabel.numberOfLines = 0
        noteLabel.text = "insert / append 是同步的：已有 cell 不重建，插入点之后的行会重编号 indexPath。只能在主线程、稳定时机调用，不要从 willDisplay / cellForItemAt 这类回调里调用。"

        logLabel.font = .systemFont(ofSize: 12)
        logLabel.textColor = .systemBlue
        logLabel.numberOfLines = 2
        logLabel.text = "点上面的按钮看结果"

        view.addSubview(row)
        view.addSubview(noteLabel)
        view.addSubview(logLabel)
        view.addSubview(collectionView)
        row.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(32)
        }
        noteLabel.snp.makeConstraints { make in
            make.top.equalTo(row.snp.bottom).offset(6)
            make.leading.trailing.equalTo(row)
        }
        logLabel.snp.makeConstraints { make in
            make.top.equalTo(noteLabel.snp.bottom).offset(6)
            make.leading.trailing.equalTo(row)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(logLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }

        listVM.createData()
        listVM.reloadData()
    }

    private func makeButton(_ title: String, tag: Int) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 14)
        b.tag = tag
        b.addTarget(self, action: #selector(actionTapped(_:)), for: .touchUpInside)
        return b
    }

    @objc private func actionTapped(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            logLabel.text = listVM.appendAtEnd()
        case 1:
            logLabel.text = listVM.insertInMiddle()
        default:
            logLabel.text = listVM.appendTwiceInOneTurn()
        }
    }
}

// MARK: - 2. 超长列表

final class LongListVM: ATListVM {
    override init() { super.init(viewProxy: ATListViewAutoProxy()) }

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(BoundaryTextCell.self, forCellWithReuseIdentifier: BoundaryTextCell.reuseId)
    }

    override func createData() {
        let sec = ATListSectionVM()
        sec.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        sec.minimumLineSpacing = 8
        sec.itemVMs = (1...120).map { i in
            let item = BoundaryTextItemVM()
            item.title = "第 \(i) 条 / 共 120 条"
            // 行数按 1/2/3 循环，行高才会真的不一样
            item.body = boundaryBody(lines: (i % 3) + 1)
            return item
        }
        viewProxy.sectionVMs = [sec]
    }
}

// MARK: - 3. 极端高度

final class ExtremeHeightItemVM: ATListItemVM {
    var height: CGFloat = 30
    var title = ""

    override func setupData() {
        super.setupData()
        cellId = ExtremeHeightCell.reuseId
    }
}

final class ExtremeHeightCell: ATListCell {
    static let reuseId = "ExtremeHeightCell"

    private let titleLabel = UILabel()
    private let block = UIView()

    override func setupSubviews() {
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = .secondaryLabel
        block.layer.cornerRadius = 6
        block.backgroundColor = UIColor.systemPink.withAlphaComponent(0.25)
        contentView.addSubview(titleLabel)
        contentView.addSubview(block)
    }

    override func setupLayout() {
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.top.equalToSuperview().offset(6)
        }
        block.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.trailing.equalTo(titleLabel)
            make.height.equalTo(30)
            make.bottom.equalToSuperview().offset(-8)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let item = itemVM as? ExtremeHeightItemVM else { return }
        titleLabel.text = item.title
        block.snp.updateConstraints { make in
            make.height.equalTo(item.height)
        }
    }
}

final class ExtremeHeightListVM: ATListVM {
    override init() { super.init(viewProxy: ATListViewAutoProxy()) }

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(ExtremeHeightCell.self, forCellWithReuseIdentifier: ExtremeHeightCell.reuseId)
    }

    override func createData() {
        let sec = ATListSectionVM()
        sec.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        sec.minimumLineSpacing = 10
        let heights: [CGFloat] = [30, 600, 30, 600, 30]
        sec.itemVMs = heights.enumerated().map { index, height in
            let item = ExtremeHeightItemVM()
            item.height = height
            item.title = "第 \(index + 1) 条 · 色块高 \(Int(height))pt"
            return item
        }
        viewProxy.sectionVMs = [sec]
    }
}

// MARK: - 4. 整表重载

final class ReloadAllListVM: ATListVM {

    private var round = 0

    override init() { super.init(viewProxy: ATListViewAutoProxy()) }

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(BoundaryTextCell.self, forCellWithReuseIdentifier: BoundaryTextCell.reuseId)
    }

    override func createData() {
        buildData()
    }

    func reloadWithNewData() {
        round += 1
        buildData()
        reloadData()
    }

    private func buildData() {
        let sec = ATListSectionVM()
        sec.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        sec.minimumLineSpacing = 8
        sec.itemVMs = (1...5).map { i in
            let item = BoundaryTextItemVM()
            item.title = "第 \(round + 1) 批 · 第 \(i) 条"
            // 行数随批次变化，重载前后行高才会不同
            item.body = boundaryBody(lines: ((i + round) % 3) + 1)
            return item
        }
        viewProxy.sectionVMs = [sec]
    }
}

final class ReloadAllDemoViewController: UIViewController {

    private let listVM = ReloadAllListVM()
    private let noteLabel = UILabel()

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
        title = "整表重载"
        view.backgroundColor = .systemBackground

        let button = UIButton(type: .system)
        button.setTitle("换一批数据并 reloadData", for: .normal)
        button.addTarget(self, action: #selector(reloadTapped), for: .touchUpInside)

        noteLabel.font = .systemFont(ofSize: 13)
        noteLabel.textColor = .secondaryLabel
        noteLabel.numberOfLines = 0
        noteLabel.text = "每批的行数都不一样：点一次按钮，行高应该整体变一次。如果行高没变，说明缓存的高度没有被丢掉。"

        view.addSubview(button)
        view.addSubview(noteLabel)
        view.addSubview(collectionView)
        button.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(32)
        }
        noteLabel.snp.makeConstraints { make in
            make.top.equalTo(button.snp.bottom).offset(6)
            make.leading.trailing.equalTo(button)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(noteLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }

        listVM.createData()
        listVM.reloadData()
    }

    @objc private func reloadTapped() {
        listVM.reloadWithNewData()
        collectionView.setContentOffset(.zero, animated: false)
    }
}

// MARK: - 菜单条目

enum AutoBoundaryDemos {
    static let entries: [DemoEntry] = [
        DemoEntry(title: "边界 · insert / append",
                  detail: "末尾、中间、同轮两次；日志显示索引重编号",
                  make: { InsertDemoViewController() }),
        DemoEntry(title: "边界 · 超长列表 120 条",
                  detail: "行高 1/2/3 行循环，看 contentSize 先估后准",
                  make: { DemoListViewController(title: "超长列表 120 条",
                                                 note: "120 条且行高不同。往上滚会看到滚动条长度变化——那是自适应布局在补量还没进过屏幕的行。",
                                                 listVM: LongListVM()) }),
        DemoEntry(title: "边界 · 极端高度",
                  detail: "30pt 与 600pt 交替，估算与真实差 20 倍",
                  make: { DemoListViewController(title: "极端高度",
                                                 note: "30pt 与 600pt 交替。估算高度和真实高度差 20 倍时，滚动中会看到内容高度不断修正。",
                                                 listVM: ExtremeHeightListVM()) }),
        DemoEntry(title: "边界 · 整表重载",
                  detail: "换一批数据后 reloadData，行高应整体变一次",
                  make: { ReloadAllDemoViewController() })
    ]
}
