//
//  AutoSceneDemos.swift
//  ATListVM_Example
//
//  自动布局的业务场景：异步内容撑高、宽度变化、展开收起、空态、卡片内嵌横向列表。
//

import UIKit
import ATListVM
import SnapKit

// MARK: - 1. 图片异步加载撑高

final class AsyncImageItemVM: ATListItemVM {
    var title = ""
    var photoHeight: CGFloat = 120
    var loaded = false

    override func setupData() {
        super.setupData()
        cellId = AsyncImageCell.reuseId
    }
}

final class AsyncImageCell: ATListCell {
    static let reuseId = "AsyncImageCell"

    private let titleLabel = UILabel()
    private let photo = UIView()

    override func setupSubviews() {
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor.systemGray6
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.numberOfLines = 1
        photo.layer.cornerRadius = 8
        photo.layer.masksToBounds = true
        contentView.addSubview(titleLabel)
        contentView.addSubview(photo)
    }

    override func setupLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        photo.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(titleLabel)
            make.height.equalTo(120)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let item = itemVM as? AsyncImageItemVM else { return }
        titleLabel.text = item.title
        photo.backgroundColor = item.loaded
            ? UIColor.systemTeal.withAlphaComponent(0.35)
            : UIColor.systemGray5
        // 高度变了要同步约束，再让外部走 reloadItemBlock 重新测量
        photo.snp.updateConstraints { make in
            make.height.equalTo(item.photoHeight)
        }
    }
}

final class AsyncImageListVM: ATListVM {
    override init() { super.init(viewProxy: ATListViewAutoProxy()) }

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(AsyncImageCell.self, forCellWithReuseIdentifier: AsyncImageCell.reuseId)
    }

    override func createData() {
        let sec = ATListSectionVM()
        sec.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        sec.minimumLineSpacing = 12
        sec.itemVMs = (0..<4).map { i in
            let item = AsyncImageItemVM()
            item.title = "第 \(i + 1) 条 · 占位 120pt"
            item.photoHeight = 120
            return item
        }
        viewProxy.sectionVMs = [sec]
    }

    /// 模拟图片加载完成。高度变了只能用 reloadItemBlock，refreshItemBlock 不会重新测量。
    func simulateImageLoaded() {
        guard let sec = viewProxy.sectionVMs.first else { return }
        for item in sec.itemVMs.prefix(3) {
            guard let it = item as? AsyncImageItemVM else { continue }
            it.loaded = true
            it.photoHeight = 240
            it.title = "图片加载完成 · 240pt"
            it.reloadItemBlock?()
        }
    }
}

final class AsyncImageDemoViewController: DemoListViewController {
    private let typedVM: AsyncImageListVM
    private var started = false

    init() {
        let vm = AsyncImageListVM()
        typedVM = vm
        super.init(title: "图片异步加载撑高",
                   note: "1.5 秒后模拟图片加载完成：高度从 120 变 240。异步内容回来必须用 reloadItemBlock；refreshItemBlock 只刷可见 cell，不会重新测量。",
                   listVM: vm)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !started else { return }
        started = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.typedVM.simulateImageLoaded()
        }
    }
}

// MARK: - 2. 宽度变化重排

final class WidthListVM: ATListVM {
    override init() { super.init(viewProxy: ATListViewAutoProxy()) }

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(WidthTextCell.self, forCellWithReuseIdentifier: WidthTextCell.reuseId)
    }

    override func createData() {
        let sec = ATListSectionVM()
        sec.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        sec.minimumLineSpacing = 12
        sec.itemVMs = (1...4).map { i in
            let item = WidthTextItemVM()
            item.title = "第 \(i) 条"
            item.body = "宽度是测量的 key。容器从 280 变到 380，这段文字的折行数会变，cell 高度也应该跟着变。切宽度后如果高度没变，说明布局没有失效。"
            return item
        }
        viewProxy.sectionVMs = [sec]
    }
}

final class WidthTextItemVM: ATListItemVM {
    var title = ""
    var body = ""

    override func setupData() {
        super.setupData()
        cellId = WidthTextCell.reuseId
    }
}

/// 宽度 demo 专用：副标题不限行数，切窄之后折行数才会真的变化。
final class WidthTextCell: ATListCell {
    static let reuseId = "WidthTextCell"

    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()

    override func setupSubviews() {
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.10)
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)
        contentView.addSubview(bodyLabel)
    }

    override func setupLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let item = itemVM as? WidthTextItemVM else { return }
        titleLabel.text = item.title
        bodyLabel.text = item.body
    }
}

final class WidthChangeDemoViewController: UIViewController {

    private let listVM = WidthListVM()
    private let container = UIView()
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
        title = "宽度变化重排"
        view.backgroundColor = .systemBackground

        noteLabel.text = "切宽度后如果高度没跟着变，说明布局没有失效——这条 demo 就是用来暴露这件事的。"
        noteLabel.font = .systemFont(ofSize: 13)
        noteLabel.textColor = .secondaryLabel
        noteLabel.numberOfLines = 0

        // 按可用宽度取百分比，320pt 的老设备也不会溢出
        let usable = view.bounds.width - 32
        let widths = [0.72, 0.85, 0.96].map { floor(usable * $0) }
        let buttons = widths.map { w -> UIButton in
            let b = UIButton(type: .system)
            b.setTitle("\(Int(w))pt", for: .normal)
            b.setTitleColor(.systemBlue, for: .normal)
            b.tag = Int(w)
            b.addTarget(self, action: #selector(widthTapped(_:)), for: .touchUpInside)
            return b
        }
        let row = UIStackView(arrangedSubviews: buttons)
        row.axis = .horizontal
        row.distribution = .fillEqually

        view.addSubview(noteLabel)
        view.addSubview(row)
        view.addSubview(container)
        container.addSubview(collectionView)

        noteLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        row.snp.makeConstraints { make in
            make.top.equalTo(noteLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(32)
        }
        container.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(row.snp.bottom).offset(8)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.width.equalTo(widths[1])
        }
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        listVM.createData()
        listVM.reloadData()
    }

    @objc private func widthTapped(_ sender: UIButton) {
        applyWidth(CGFloat(sender.tag))
    }

    private func applyWidth(_ width: CGFloat) {
        // 注意：SnapKit 的 constraint.update(offset:) 不是「在原值上加减」，
        // 宽度这种约束要走 updateConstraints 重设 equalTo。
        container.snp.updateConstraints { make in
            make.width.equalTo(width)
        }
        view.layoutIfNeeded()
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.layoutIfNeeded()
    }
}

// MARK: - 3. 展开 / 收起

final class ExpandItemVM: ATListItemVM {
    var title = ""
    var body = ""
    var expanded = false

    override func setupData() {
        super.setupData()
        cellId = ExpandCell.reuseId
    }
}

final class ExpandCell: ATListCell {
    static let reuseId = "ExpandCell"

    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let toggleButton = UIButton(type: .system)

    override func setupSubviews() {
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.08)
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 3
        toggleButton.titleLabel?.font = .systemFont(ofSize: 14)
        toggleButton.contentHorizontalAlignment = .leading
        toggleButton.addTarget(self, action: #selector(toggle), for: .touchUpInside)
        contentView.addSubview(titleLabel)
        contentView.addSubview(bodyLabel)
        contentView.addSubview(toggleButton)
    }

    override func setupLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.trailing.equalTo(titleLabel)
        }
        toggleButton.snp.makeConstraints { make in
            make.top.equalTo(bodyLabel.snp.bottom).offset(6)
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let item = itemVM as? ExpandItemVM else { return }
        titleLabel.text = item.title
        bodyLabel.text = item.body
        bodyLabel.numberOfLines = item.expanded ? 0 : 3
        toggleButton.setTitle(item.expanded ? "收起" : "展开全文", for: .normal)
    }

    @objc private func toggle() {
        guard let item = itemVM as? ExpandItemVM else { return }
        item.expanded.toggle()
        item.reloadItemBlock?()
    }
}

final class ExpandListVM: ATListVM {
    override init() { super.init(viewProxy: ATListViewAutoProxy()) }

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(ExpandCell.self, forCellWithReuseIdentifier: ExpandCell.reuseId)
    }

    override func createData() {
        let sec = ATListSectionVM()
        sec.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        sec.minimumLineSpacing = 12
        let longText = "这段文字默认只显示三行。点下面的按钮会把 numberOfLines 从 3 改成 0，然后用 reloadItemBlock 让列表重新测量高度。收起时反过来。因为在自适应布局里高度是由约束算出来的，只改文字不重新测量是不会变高的。"
        sec.itemVMs = (1...3).map { i in
            let item = ExpandItemVM()
            item.title = "第 \(i) 条 · 可展开"
            item.body = longText
            return item
        }
        viewProxy.sectionVMs = [sec]
    }
}

// MARK: - 4. 空态 / 只有 header / 单条

final class EmptyStateListVM: ATListVM {

    enum Mode: Int {
        case empty
        case headerOnly
        case single
    }

    override init() { super.init(viewProxy: ATListViewAutoProxy()) }

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(DemoTextCell.self, forCellWithReuseIdentifier: DemoTextCell.reuseId)
        DemoSectionTitleView.register(on: collectionView)
    }

    override func createData() {
        rebuild(.empty)
    }

    func apply(_ mode: Mode) {
        rebuild(mode)
        reloadData()
    }

    private func rebuild(_ mode: Mode) {
        let sec = ATListSectionVM()
        sec.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        // 空态要连 headerId 一起清掉：设了 headerId 就算没有 item，header 照样会占位。
        if mode != .empty {
            sec.headerId = DemoSectionTitleView.headerId
            sec.headerSize = CGSize(width: UIScreen.main.bounds.width, height: 36)
        }
        if mode == .single {
            let item = DemoTextItemVM()
            item.title = "只有一条"
            item.subtitle = "单条时高度应正常，不应出现多余留白。"
            sec.itemVMs = [item]
        }
        viewProxy.sectionVMs = [sec]
    }
}

final class EmptyStateDemoViewController: UIViewController {

    private let listVM = EmptyStateListVM()
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
        title = "空态 / 只有 header / 单条"
        view.backgroundColor = .systemBackground

        let emptyBtn = makeButton("空态", tag: 0)
        let headerBtn = makeButton("只有 header", tag: 1)
        let singleBtn = makeButton("单条", tag: 2)
        let row = UIStackView(arrangedSubviews: [emptyBtn, headerBtn, singleBtn])
        row.axis = .horizontal
        row.distribution = .fillEqually

        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        statusLabel.text = "空态必须把 headerId 一起清掉，否则 header 仍会占位。"

        view.addSubview(row)
        view.addSubview(statusLabel)
        view.addSubview(collectionView)
        row.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(32)
        }
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(row.snp.bottom).offset(8)
            make.leading.trailing.equalTo(row)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }

        listVM.createData()
        listVM.reloadData()
    }

    private func makeButton(_ title: String, tag: Int) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.tag = tag
        b.addTarget(self, action: #selector(modeTapped(_:)), for: .touchUpInside)
        return b
    }

    @objc private func modeTapped(_ sender: UIButton) {
        guard let mode = EmptyStateListVM.Mode(rawValue: sender.tag) else { return }
        listVM.apply(mode)
    }
}

// MARK: - 5. 卡片内嵌横向列表

final class CardTagsItemVM: ATListItemVM {
    var title = ""
    var tags: [String] = []

    override func setupData() {
        super.setupData()
        cellId = CardWithTagsCell.reuseId
    }
}

final class CardWithTagsCell: ATListCell {
    static let reuseId = "CardWithTagsCell"

    private let titleLabel = UILabel()
    private let scroll = UIScrollView()
    private let stack = UIStackView()

    override func setupSubviews() {
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor.systemGray6
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.numberOfLines = 2
        scroll.showsHorizontalScrollIndicator = false
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        scroll.addSubview(stack)
        contentView.addSubview(titleLabel)
        contentView.addSubview(scroll)
    }

    override func setupLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        // 横滑容器必须给显式高度，否则自适应会把整张卡片算成 0
        scroll.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(32)
            make.bottom.equalToSuperview().offset(-12)
        }
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(scroll.snp.height)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let item = itemVM as? CardTagsItemVM else { return }
        titleLabel.text = item.title
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for tag in item.tags {
            let label = UILabel()
            label.font = .systemFont(ofSize: 13)
            label.textColor = .systemBlue
            label.text = "  \(tag)  "
            label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.10)
            label.layer.cornerRadius = 12
            label.layer.masksToBounds = true
            stack.addArrangedSubview(label)
        }
    }
}

final class CardTagsListVM: ATListVM {
    override init() { super.init(viewProxy: ATListViewAutoProxy()) }

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(CardWithTagsCell.self, forCellWithReuseIdentifier: CardWithTagsCell.reuseId)
    }

    override func createData() {
        let sec = ATListSectionVM()
        sec.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        sec.minimumLineSpacing = 12
        let samples: [(String, [String])] = [
            ("卡片里嵌一行横向标签，标题可能折成两行，横滑区域高度固定 32。",
             ["阳台种菜", "周末去哪儿", "二手置换"]),
            ("横滑容器没有固有高度，必须给显式约束，否则自适应会把卡片算成一条线。",
             ["夜跑", "旧物改造", "邻里早餐", "宠物交友", "露营"]),
            ("横向内容超出屏幕时，卡片本身的高度不受影响。",
             ["摄影", "咖啡", "读书"])
        ]
        sec.itemVMs = samples.map { title, tags in
            let item = CardTagsItemVM()
            item.title = title
            item.tags = tags
            return item
        }
        viewProxy.sectionVMs = [sec]
    }
}

// MARK: - 菜单条目

enum AutoSceneDemos {
    static let entries: [DemoEntry] = [
        DemoEntry(title: "业务场景 · 图片异步加载撑高",
                  detail: "占位 120pt → 加载完成 240pt，走 reloadItemBlock",
                  make: { AsyncImageDemoViewController() }),
        DemoEntry(title: "业务场景 · 宽度变化重排",
                  detail: "按屏宽切三档宽度，看高度是否重新算",
                  make: { WidthChangeDemoViewController() }),
        DemoEntry(title: "业务场景 · 展开与收起",
                  detail: "numberOfLines 3 ↔ 0，展开后重新测量",
                  make: { DemoListViewController(title: "展开与收起",
                                                 note: "点卡片里的「展开全文」：numberOfLines 从 3 变 0，再 reloadItemBlock 重新测量。",
                                                 listVM: ExpandListVM()) }),
        DemoEntry(title: "业务场景 · 空态 / 只有 header / 单条",
                  detail: "三种数据量，重点看空态要清 headerId",
                  make: { EmptyStateDemoViewController() }),
        DemoEntry(title: "业务场景 · 卡片内嵌横向列表",
                  detail: "横滑容器显式高度 32，否则自适应算出 0",
                  make: { DemoListViewController(title: "卡片内嵌横向列表",
                                                 note: "横滑区域没有固有高度，必须给显式约束；横向内容不参与纵向高度计算。",
                                                 listVM: CardTagsListVM()) })
    ]
}
