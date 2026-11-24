//
//  BusinessScenarioDemos.swift
//  ATListVM_Example
//
//  「业务场景」示例集：设置页 / 商品列表 / 消息中心 / 个人中心 / 搜索结果 / 横向卡片流。
//  每页都只用 ATListVM 的公开能力，页面骨架由 ScenarioPageViewController 提供。
//

import UIKit
import SnapKit
import ATListVM

// MARK: - 页面骨架

/// 业务场景页的公共骨架：顶部一行说明、中间 collectionView、底部一行事件回显。
class ScenarioPageViewController: UIViewController {

    /// 由子类传入的 VM，页面创建时确定，之后不再更换。
    let listVM: ATListVM

    let eventLabel = UILabel()

    private let hintText: String
    private let topAccessory: UIView?
    private let collectionViewHeight: CGFloat?
    private let scrollDirection: UICollectionView.ScrollDirection

    private(set) lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = scrollDirection
        if scrollDirection == .horizontal {
            layout.minimumLineSpacing = 12
            layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .systemBackground
        view.alwaysBounceVertical = scrollDirection == .vertical
        view.config(listVM: listVM)
        view.config(viewProxy: listVM.viewProxy)
        return view
    }()

    init(title: String,
         hint: String,
         listVM: ATListVM,
         scrollDirection: UICollectionView.ScrollDirection = .vertical,
         topAccessory: UIView? = nil,
         collectionViewHeight: CGFloat? = nil) {
        self.listVM = listVM
        self.hintText = hint
        self.scrollDirection = scrollDirection
        self.topAccessory = topAccessory
        self.collectionViewHeight = collectionViewHeight
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let hintLabel = UILabel()
        hintLabel.text = hintText
        hintLabel.font = .systemFont(ofSize: 12)
        hintLabel.textColor = .secondaryLabel
        hintLabel.numberOfLines = 0

        eventLabel.font = .systemFont(ofSize: 12)
        eventLabel.textColor = .secondaryLabel
        eventLabel.numberOfLines = 1
        eventLabel.text = "等待操作"

        view.addSubview(hintLabel)
        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        var topAnchor = hintLabel.snp.bottom
        if let accessory = topAccessory {
            view.addSubview(accessory)
            accessory.snp.makeConstraints { make in
                make.top.equalTo(topAnchor).offset(8)
                make.leading.equalToSuperview().offset(16)
                make.trailing.equalToSuperview().offset(-16)
            }
            topAnchor = accessory.snp.bottom
        }

        view.addSubview(eventLabel)
        eventLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(24)
        }

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(topAnchor).offset(8)
            make.leading.trailing.equalToSuperview()
            if let height = collectionViewHeight {
                make.height.equalTo(height)
            } else {
                make.bottom.equalTo(eventLabel.snp.top).offset(-4)
            }
        }

        listVM.createData()
        listVM.reloadData()
    }

    /// 底部事件回显。
    func show(_ event: String) {
        eventLabel.text = event
    }
}

// MARK: - 设置页

final class SettingsSectionVM: ATListSectionVM {
    var title = ""
}

final class SettingsSectionHeader: ATListReuseableView {
    static let reuseId = "SettingsSectionHeader"

    private let label = UILabel()

    override func setupSubviews() {
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        addSubview(label)
    }

    override func setupLayout() {
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        label.text = (sectionVM as? SettingsSectionVM)?.title
    }
}

class SettingsRowVM: ATListItemVM {
    var title = ""
    var onEvent: ((String) -> Void)?

    override func setupData() {
        super.setupData()
        itemSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 56)
    }
}

final class SettingsValueRowVM: SettingsRowVM {
    var value = ""

    override func setupData() {
        super.setupData()
        cellId = SettingsValueRowCell.reuseId
    }
}

final class SettingsToggleRowVM: SettingsRowVM {
    var isOn = true

    override func setupData() {
        super.setupData()
        cellId = SettingsToggleRowCell.reuseId
    }
}

final class SettingsDangerRowVM: SettingsRowVM {
    override func setupData() {
        super.setupData()
        cellId = SettingsDangerRowCell.reuseId
        itemSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 52)
    }
}

final class SettingsValueRowCell: ATListCell {
    static let reuseId = "SettingsValueRowCell"

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let arrowLabel = UILabel()

    override func setupSubviews() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true

        titleLabel.font = .systemFont(ofSize: 15)
        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.textColor = .secondaryLabel
        valueLabel.textAlignment = .right
        arrowLabel.text = "›"
        arrowLabel.font = .systemFont(ofSize: 18)
        arrowLabel.textColor = .tertiaryLabel

        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(arrowLabel)
    }

    override func setupLayout() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
        }
        arrowLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(arrowLabel.snp.leading).offset(-6)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let vm = itemVM as? SettingsValueRowVM else { return }
        titleLabel.text = vm.title
        valueLabel.text = vm.value
    }
}

final class SettingsToggleRowCell: ATListCell {
    static let reuseId = "SettingsToggleRowCell"

    private let titleLabel = UILabel()
    private let toggle = UISwitch()
    private var onChange: ((Bool) -> Void)?

    override func setupSubviews() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true

        titleLabel.font = .systemFont(ofSize: 15)
        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)

        contentView.addSubview(titleLabel)
        contentView.addSubview(toggle)
    }

    override func setupLayout() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
        }
        toggle.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let vm = itemVM as? SettingsToggleRowVM else { return }
        titleLabel.text = vm.title
        toggle.isOn = vm.isOn
        onChange = { [weak vm] isOn in
            guard let vm = vm else { return }
            vm.isOn = isOn
            vm.reloadItemBlock?()
            vm.onEvent?("开关 \(vm.title) = \(isOn ? "on" : "off")")
        }
    }

    @objc private func toggleChanged() {
        onChange?(toggle.isOn)
    }
}

final class SettingsDangerRowCell: ATListCell {
    static let reuseId = "SettingsDangerRowCell"

    private let titleLabel = UILabel()

    override func setupSubviews() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true

        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = .systemRed
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
    }

    override func setupLayout() {
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let vm = itemVM as? SettingsDangerRowVM else { return }
        titleLabel.text = vm.title
    }
}

final class SettingsListVM: ATListVM {

    var onEvent: ((String) -> Void)?

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(SettingsValueRowCell.self,
                                forCellWithReuseIdentifier: SettingsValueRowCell.reuseId)
        collectionView.register(SettingsToggleRowCell.self,
                                forCellWithReuseIdentifier: SettingsToggleRowCell.reuseId)
        collectionView.register(SettingsDangerRowCell.self,
                                forCellWithReuseIdentifier: SettingsDangerRowCell.reuseId)
        collectionView.register(SettingsSectionHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: SettingsSectionHeader.reuseId)
    }

    override func createData() {
        let screenWidth = UIScreen.main.bounds.width

        func makeSection(_ title: String, top: CGFloat) -> SettingsSectionVM {
            let section = SettingsSectionVM()
            section.title = title
            section.headerId = SettingsSectionHeader.reuseId
            section.headerSize = CGSize(width: screenWidth, height: 28)
            section.sectionInset = UIEdgeInsets(top: top, left: 16, bottom: 8, right: 16)
            section.minimumLineSpacing = 6
            return section
        }

        let account = makeSection("账号", top: 4)
        let accountRows = [
            ("头像与昵称", "张同学"),
            ("绑定手机", "138****0000")
        ].map { title, value -> SettingsValueRowVM in
            let vm = SettingsValueRowVM()
            vm.title = title
            vm.value = value
            vm.onSelectItemBlock = { [weak self] _, _, _ in
                self?.onEvent?("点击 \(title)")
            }
            return vm
        }
        account.itemVMs = accountRows

        let preference = makeSection("偏好", top: 12)
        let preferenceRows: [SettingsToggleRowVM] = [
            ("深色跟随后台", false),
            ("消息推送", true)
        ].map { title, isOn in
            let vm = SettingsToggleRowVM()
            vm.title = title
            vm.isOn = isOn
            vm.onEvent = { [weak self] event in self?.onEvent?(event) }
            return vm
        }
        preference.itemVMs = preferenceRows

        let danger = SettingsSectionVM()
        danger.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)
        let logout = SettingsDangerRowVM()
        logout.title = "退出登录"
        logout.onSelectItemBlock = { [weak self] _, _, _ in
            self?.onEvent?("点击 退出登录")
        }
        danger.itemVMs = [logout]

        viewProxy.sectionVMs = [account, preference, danger]
    }
}

final class ScenarioSettingsViewController: ScenarioPageViewController {

    private var settingsVM: SettingsListVM { listVM as! SettingsListVM }

    init() {
        super.init(title: "设置页",
                   hint: "3 组、3 种行。开关只刷自己那一行（reloadItemBlock），不重建整表。",
                   listVM: SettingsListVM())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        settingsVM.onEvent = { [weak self] event in
            self?.show(event)
        }
        super.viewDidLoad()
    }
}

// MARK: - 商品列表

final class ProductItemVM: ATListItemVM {
    var title = ""
    var price = ""
    var color: UIColor = .systemGray5
    override func setupData() {
        super.setupData()
        cellId = ProductCell.reuseId
    }
}

final class ProductCell: ATListCell {
    static let reuseId = "ProductCell"

    private let cover = UIView()
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()

    override func setupSubviews() {
        cover.layer.cornerRadius = 8
        cover.layer.masksToBounds = true

        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.numberOfLines = 1
        priceLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        priceLabel.textColor = .systemOrange

        contentView.addSubview(cover)
        contentView.addSubview(titleLabel)
        contentView.addSubview(priceLabel)
    }

    override func setupLayout() {
        cover.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            // 高度随 cell 走：两列 180 高时封面 116，单列 120 高时封面 56，
            // 一套约束同时适配两种尺寸，切换视图不用换 cell。
            make.height.equalToSuperview().offset(-64)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(cover.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
        }
        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview()
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let vm = itemVM as? ProductItemVM else { return }
        cover.backgroundColor = vm.color
        titleLabel.text = vm.title
        priceLabel.text = vm.price
    }
}

final class ProductMoreVM: ATListItemVM {
    override func setupData() {
        super.setupData()
        cellId = ProductMoreCell.reuseId
    }
}

final class ProductMoreCell: ATListCell {
    static let reuseId = "ProductMoreCell"

    private let label = UILabel()

    override func setupSubviews() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        label.text = "加载更多"
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .systemBlue
        label.textAlignment = .center
        contentView.addSubview(label)
    }

    override func setupLayout() {
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

final class ProductListVM: ATListVM {

    var onEvent: ((String) -> Void)?

    let section = ATListSectionVM()
    var isGrid = true
    var pageIndex = 0

    private var seed = 0
    private let palette: [UIColor] = [.systemTeal, .systemIndigo, .systemPink, .systemBrown,
                                      .systemGreen, .systemBlue, .systemPurple, .systemOrange]

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(ProductCell.self, forCellWithReuseIdentifier: ProductCell.reuseId)
        collectionView.register(ProductMoreCell.self, forCellWithReuseIdentifier: ProductMoreCell.reuseId)
    }

    override func createData() {
        section.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16)
        section.minimumLineSpacing = 12
        section.itemVMs = (0..<8).map { _ in makeItem() }
        section.itemVMs.append(makeMoreItem())
        applyStyle()
        viewProxy.sectionVMs = [section]
    }

    func toggleStyle() {
        isGrid.toggle()
        applyStyle()
        section.reloadSectionBlock?()
        onEvent?("切换为 \(isGrid ? "两列" : "单列")")
    }

    private func applyStyle() {
        let width = UIScreen.main.bounds.width - 32
        let itemWidth = isGrid ? (width - 12) / 2 : width
        let itemHeight: CGFloat = isGrid ? 180 : 120
        for item in section.itemVMs {
            item.itemSize = CGSize(width: itemWidth, height: itemHeight)
        }
        section.minimumInteritemSpacing = isGrid ? 12 : 0
    }

    private func makeMoreItem() -> ProductMoreVM {
        let vm = ProductMoreVM()
        vm.onSelectItemBlock = { [weak self] _, _, _ in
            self?.loadMore()
        }
        return vm
    }

    private func makeItem() -> ProductItemVM {
        seed += 1
        let vm = ProductItemVM()
        vm.title = "商品 \(seed)"
        vm.price = "¥\(9 + seed * 7).00"
        vm.color = palette[(seed - 1) % palette.count]
        return vm
    }

    /// 点「加载更多」时追加 6 条。点击发生在列表空闲时，append 的批量更新不会和
    /// 别的更新撞上；这也是社区示例用的同一条路。
    func loadMore() {
        guard pageIndex < 3 else {
            onEvent?("没有更多")
            return
        }
        pageIndex += 1
        let moreIndex = section.itemVMs.count - 1
        section.itemVMs.remove(at: moreIndex)
        for _ in 0..<6 {
            section.itemVMs.append(makeItem())
        }
        section.itemVMs.append(makeMoreItem())
        // 新加的 item 没有 itemSize，必须先套一次当前样式，否则 sizeForItemAt 返回 .zero
        applyStyle()
        section.reloadSectionBlock?()
        onEvent?("加载第 \(self.pageIndex) 页")
    }
}

final class ScenarioProductListViewController: ScenarioPageViewController {

    private var productVM: ProductListVM { listVM as! ProductListVM }

    init() {
        super.init(title: "商品列表",
                   hint: "右上角切换两列/单列（改 itemSize 后 reloadSection）；点「加载更多」追加一页，最多 3 页。",
                   listVM: ProductListVM())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        productVM.onEvent = { [weak self] event in
            self?.show(event)
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "切换视图",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(toggleStyle))
        super.viewDidLoad()
    }

    @objc private func toggleStyle() {
        productVM.toggleStyle()
    }
}


// MARK: - 消息中心

class MessageItemVM: ATListItemVM {
    var isUnread = false
    var time = ""
    var onEvent: ((String) -> Void)?

    override func setupData() {
        super.setupData()
        // 自撑开：只给宽度，高度交给 ATListCell.preferredLayoutAttributesFitting 量。
        itemSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 0)
    }

    func markRead(_ label: String) {
        guard isUnread else { return }
        isUnread = false
        refreshItemBlock?()
        onEvent?("标记已读 \(label)")
    }
}

final class SystemMessageVM: MessageItemVM {
    var title = ""
    var body = ""

    override func setupData() {
        super.setupData()
        cellId = SystemMessageCell.reuseId
    }
}

final class LikeMessageVM: MessageItemVM {
    var name = ""
    var action = ""

    override func setupData() {
        super.setupData()
        cellId = LikeMessageCell.reuseId
    }
}

final class CommentMessageVM: MessageItemVM {
    var name = ""
    var quote = ""
    var reply = ""

    override func setupData() {
        super.setupData()
        cellId = CommentMessageCell.reuseId
    }
}

final class FollowMessageVM: MessageItemVM {
    var name = ""
    var desc = ""

    override func setupData() {
        super.setupData()
        cellId = FollowMessageCell.reuseId
    }
}

class MessageBaseCell: ATListCell {
    let dot = UIView()

    override func setupSubviews() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true

        dot.backgroundColor = .systemRed
        dot.layer.cornerRadius = 3
        contentView.addSubview(dot)
    }

    override func setupLayout() {
        dot.snp.makeConstraints { make in
            make.width.height.equalTo(6)
            make.leading.equalToSuperview().offset(6)
            make.top.equalToSuperview().offset(20)
        }
    }

    func applyUnread(_ vm: MessageItemVM?) {
        dot.isHidden = !(vm?.isUnread ?? false)
    }
}

final class SystemMessageCell: MessageBaseCell {
    static let reuseId = "SystemMessageCell"

    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let timeLabel = UILabel()

    override func setupSubviews() {
        super.setupSubviews()
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        bodyLabel.font = .systemFont(ofSize: 13)
        bodyLabel.textColor = .label
        bodyLabel.numberOfLines = 0
        timeLabel.font = .systemFont(ofSize: 11)
        timeLabel.textColor = .tertiaryLabel
        contentView.addSubview(titleLabel)
        contentView.addSubview(bodyLabel)
        contentView.addSubview(timeLabel)
    }

    override func setupLayout() {
        super.setupLayout()
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-12)
        }
        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.trailing.equalTo(titleLabel)
        }
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(bodyLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let vm = itemVM as? SystemMessageVM else { return }
        titleLabel.text = vm.title
        bodyLabel.text = vm.body
        timeLabel.text = vm.time
        applyUnread(vm)
    }
}

final class LikeMessageCell: MessageBaseCell {
    static let reuseId = "LikeMessageCell"

    private let avatar = UIView()
    private let label = UILabel()
    private let timeLabel = UILabel()

    override func setupSubviews() {
        super.setupSubviews()
        avatar.backgroundColor = .systemPink
        avatar.layer.cornerRadius = 16
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        timeLabel.font = .systemFont(ofSize: 11)
        timeLabel.textColor = .tertiaryLabel
        contentView.addSubview(avatar)
        contentView.addSubview(label)
        contentView.addSubview(timeLabel)
    }

    override func setupLayout() {
        super.setupLayout()
        avatar.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(12)
        }
        label.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalTo(avatar)
        }
        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(label)
            make.top.equalTo(label.snp.bottom).offset(6)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let vm = itemVM as? LikeMessageVM else { return }
        label.text = "\(vm.name) \(vm.action)"
        timeLabel.text = vm.time
        applyUnread(vm)
    }
}

final class CommentMessageCell: MessageBaseCell {
    static let reuseId = "CommentMessageCell"

    private let nameLabel = UILabel()
    private let quoteView = UIView()
    private let quoteLabel = UILabel()
    private let replyLabel = UILabel()
    private let timeLabel = UILabel()

    override func setupSubviews() {
        super.setupSubviews()
        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        quoteView.backgroundColor = .tertiarySystemBackground
        quoteView.layer.cornerRadius = 6
        quoteLabel.font = .systemFont(ofSize: 13)
        quoteLabel.textColor = .secondaryLabel
        quoteLabel.numberOfLines = 2
        replyLabel.font = .systemFont(ofSize: 14)
        replyLabel.numberOfLines = 0
        timeLabel.font = .systemFont(ofSize: 11)
        timeLabel.textColor = .tertiaryLabel

        contentView.addSubview(nameLabel)
        contentView.addSubview(quoteView)
        quoteView.addSubview(quoteLabel)
        contentView.addSubview(replyLabel)
        contentView.addSubview(timeLabel)
    }

    override func setupLayout() {
        super.setupLayout()
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-12)
        }
        quoteView.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(6)
            make.leading.equalTo(nameLabel)
            make.trailing.equalTo(nameLabel)
        }
        quoteLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10))
        }
        replyLabel.snp.makeConstraints { make in
            make.top.equalTo(quoteView.snp.bottom).offset(8)
            make.leading.trailing.equalTo(nameLabel)
        }
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(replyLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(nameLabel)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let vm = itemVM as? CommentMessageVM else { return }
        nameLabel.text = vm.name
        quoteLabel.text = vm.quote
        replyLabel.text = vm.reply
        timeLabel.text = vm.time
        applyUnread(vm)
    }
}

final class FollowMessageCell: MessageBaseCell {
    static let reuseId = "FollowMessageCell"

    private let avatar = UIView()
    private let nameLabel = UILabel()
    private let descLabel = UILabel()
    private let followButton = UIButton(type: .system)

    override func setupSubviews() {
        super.setupSubviews()
        avatar.backgroundColor = .systemIndigo
        avatar.layer.cornerRadius = 20
        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        descLabel.font = .systemFont(ofSize: 12)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0
        followButton.setTitle("关注", for: .normal)
        followButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        followButton.backgroundColor = .systemBlue
        followButton.setTitleColor(.white, for: .normal)
        followButton.layer.cornerRadius = 12

        contentView.addSubview(avatar)
        contentView.addSubview(nameLabel)
        contentView.addSubview(descLabel)
        contentView.addSubview(followButton)
    }

    override func setupLayout() {
        super.setupLayout()
        avatar.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(12)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatar)
            make.leading.equalTo(avatar.snp.trailing).offset(10)
            make.trailing.lessThanOrEqualTo(followButton.snp.leading).offset(-8)
        }
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.equalTo(nameLabel)
            make.trailing.equalTo(followButton.snp.leading).offset(-8)
            make.bottom.equalToSuperview().offset(-12)
        }
        followButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalTo(avatar)
            make.width.equalTo(56)
            make.height.equalTo(24)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let vm = itemVM as? FollowMessageVM else { return }
        nameLabel.text = vm.name
        descLabel.text = vm.desc
        applyUnread(vm)
    }
}

final class MessageListVM: ATListVM {

    var onEvent: ((String) -> Void)?

    let section = ATListSectionVM()

    override init() {
        super.init(viewProxy: ATListViewAutoProxy())
    }

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(SystemMessageCell.self, forCellWithReuseIdentifier: SystemMessageCell.reuseId)
        collectionView.register(LikeMessageCell.self, forCellWithReuseIdentifier: LikeMessageCell.reuseId)
        collectionView.register(CommentMessageCell.self, forCellWithReuseIdentifier: CommentMessageCell.reuseId)
        collectionView.register(FollowMessageCell.self, forCellWithReuseIdentifier: FollowMessageCell.reuseId)
    }

    override func createData() {
        section.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 24, right: 16)
        section.minimumLineSpacing = 10

        var items: [MessageItemVM] = []

        let system = SystemMessageVM()
        system.title = "系统通知"
        system.body = "你的设备固件有新版本可以升级了。本次更新优化了连接稳定性，并修复了定时任务偶尔不触发的问题。建议在充电时升级。"
        system.time = "10 分钟前"
        system.isUnread = true
        items.append(system)

        let like = LikeMessageVM()
        like.name = "小林"
        like.action = "赞了你的帖子「阳台的番茄红了」"
        like.time = "1 小时前"
        like.isUnread = true
        items.append(like)

        let comment = CommentMessageVM()
        comment.name = "阿南"
        comment.quote = "夜跑三条路线，选一条。江边风大，公园灯暗，小区里最安全。"
        comment.reply = "小区那条我也跑过，晚上十点以后基本没人，路灯也够亮。"
        comment.time = "3 小时前"
        items.append(comment)

        let follow = FollowMessageVM()
        follow.name = "老周"
        follow.desc = "关注了你，他最近更新了 12 条旧物改造笔记。"
        follow.time = "昨天"
        items.append(follow)

        for (index, item) in items.enumerated() {
            item.onEvent = { [weak self] event in self?.onEvent?(event) }
            item.onSelectItemBlock = { [weak item] _, _, _ in
                item?.markRead("第 \(index + 1) 条")
            }
        }

        section.itemVMs = items
        viewProxy.sectionVMs = [section]
    }

    func markAllRead() {
        let unread = section.itemVMs.compactMap { $0 as? MessageItemVM }.filter { $0.isUnread }
        guard !unread.isEmpty else {
            onEvent?("没有未读消息")
            return
        }
        for item in unread {
            item.isUnread = false
            item.refreshItemBlock?()
        }
        onEvent?("全部已读（\(unread.count) 条）")
    }
}

final class ScenarioMessageCenterViewController: ScenarioPageViewController {

    private var messageVM: MessageListVM { listVM as! MessageListVM }

    init() {
        super.init(title: "消息中心",
                   hint: "自撑开的四种消息行：标题正文、点赞、评论引用、关注卡片。未读点一下就消，只刷可见 cell。",
                   listVM: MessageListVM())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        messageVM.onEvent = { [weak self] event in
            self?.show(event)
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "全部已读",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(markAllRead))
        super.viewDidLoad()
    }

    @objc private func markAllRead() {
        messageVM.markAllRead()
    }
}


// MARK: - 个人中心

class ProfileItemVM: ATListItemVM {
    var onEvent: ((String) -> Void)?

    func bindTap(_ label: String) {
        onSelectItemBlock = { [weak self] _, _, _ in
            self?.onEvent?("点击 \(label)")
        }
    }
}

final class ProfileAvatarVM: ProfileItemVM {
    var name = ""
    var bio = ""

    override func setupData() {
        super.setupData()
        cellId = ProfileAvatarCell.reuseId
        itemSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 120)
    }
}

final class ProfileStatVM: ProfileItemVM {
    var value = ""
    var label = ""

    override func setupData() {
        super.setupData()
        cellId = ProfileStatCell.reuseId
        itemSize = CGSize(width: (UIScreen.main.bounds.width - 32) / 3, height: 72)
    }
}

final class ProfileGridVM: ProfileItemVM {
    var title = ""
    var color: UIColor = .systemBlue

    override func setupData() {
        super.setupData()
        cellId = ProfileGridCell.reuseId
        itemSize = CGSize(width: (UIScreen.main.bounds.width - 32 - 36) / 4, height: 76)
    }
}

final class ProfileRowVM: ProfileItemVM {
    var title = ""

    override func setupData() {
        super.setupData()
        cellId = ProfileRowCell.reuseId
        itemSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 56)
    }
}

final class ProfileAvatarCell: ATListCell {
    static let reuseId = "ProfileAvatarCell"

    private let avatar = UIView()
    private let nameLabel = UILabel()
    private let bioLabel = UILabel()

    override func setupSubviews() {
        contentView.backgroundColorPlaceholder()

        avatar.backgroundColor = .systemTeal
        avatar.layer.cornerRadius = 32
        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        bioLabel.font = .systemFont(ofSize: 13)
        bioLabel.textColor = .secondaryLabel
        bioLabel.numberOfLines = 2

        contentView.addSubview(avatar)
        contentView.addSubview(nameLabel)
        contentView.addSubview(bioLabel)
    }

    override func setupLayout() {
        avatar.snp.makeConstraints { make in
            make.width.height.equalTo(64)
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(14)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(32)
        }
        bioLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(6)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let vm = itemVM as? ProfileAvatarVM else { return }
        nameLabel.text = vm.name
        bioLabel.text = vm.bio
    }
}

extension UIView {
    fileprivate func backgroundColorPlaceholder() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        layer.masksToBounds = true
    }
}

final class ProfileStatCell: ATListCell {
    static let reuseId = "ProfileStatCell"

    private let valueLabel = UILabel()
    private let nameLabel = UILabel()

    override func setupSubviews() {
        valueLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        valueLabel.textAlignment = .center
        nameLabel.font = .systemFont(ofSize: 12)
        nameLabel.textColor = .secondaryLabel
        nameLabel.textAlignment = .center
        contentView.backgroundColor = .secondarySystemBackground
        contentView.addSubview(valueLabel)
        contentView.addSubview(nameLabel)
    }

    override func setupLayout() {
        valueLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview()
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(valueLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let vm = itemVM as? ProfileStatVM else { return }
        valueLabel.text = vm.value
        nameLabel.text = vm.label
    }
}

final class ProfileGridCell: ATListCell {
    static let reuseId = "ProfileGridCell"

    private let icon = UIView()
    private let titleLabel = UILabel()

    override func setupSubviews() {
        icon.layer.cornerRadius = 14
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textAlignment = .center
        contentView.addSubview(icon)
        contentView.addSubview(titleLabel)
    }

    override func setupLayout() {
        icon.snp.makeConstraints { make in
            make.width.height.equalTo(28)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(10)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(icon.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let vm = itemVM as? ProfileGridVM else { return }
        icon.backgroundColor = vm.color
        titleLabel.text = vm.title
    }
}

final class ProfileRowCell: ATListCell {
    static let reuseId = "ProfileRowCell"

    private let titleLabel = UILabel()
    private let arrowLabel = UILabel()

    override func setupSubviews() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        titleLabel.font = .systemFont(ofSize: 15)
        arrowLabel.text = "›"
        arrowLabel.font = .systemFont(ofSize: 18)
        arrowLabel.textColor = .tertiaryLabel
        contentView.addSubview(titleLabel)
        contentView.addSubview(arrowLabel)
    }

    override func setupLayout() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
        }
        arrowLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let vm = itemVM as? ProfileRowVM else { return }
        titleLabel.text = vm.title
    }
}

final class ProfileListVM: ATListVM {

    var onEvent: ((String) -> Void)?

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(ProfileAvatarCell.self, forCellWithReuseIdentifier: ProfileAvatarCell.reuseId)
        collectionView.register(ProfileStatCell.self, forCellWithReuseIdentifier: ProfileStatCell.reuseId)
        collectionView.register(ProfileGridCell.self, forCellWithReuseIdentifier: ProfileGridCell.reuseId)
        collectionView.register(ProfileRowCell.self, forCellWithReuseIdentifier: ProfileRowCell.reuseId)
    }

    override func createData() {
        let avatarSection = ATListSectionVM()
        avatarSection.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 0, right: 16)
        let avatar = ProfileAvatarVM()
        avatar.name = "张同学"
        avatar.bio = "爱折腾智能家居，家里 12 台设备。"
        avatar.bindTap(avatar.name)
        avatarSection.itemVMs = [avatar]

        let statSection = ATListSectionVM()
        statSection.sectionInset = UIEdgeInsets(top: 10, left: 16, bottom: 0, right: 16)
        statSection.minimumInteritemSpacing = 0
        let stats: [(String, String)] = [("128", "关注"), ("42", "粉丝"), ("3.6k", "获赞")]
        statSection.itemVMs = stats.map { value, label in
            let vm = ProfileStatVM()
            vm.value = value
            vm.label = label
            vm.bindTap(label)
            return vm
        }

        let gridSection = ATListSectionVM()
        gridSection.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 0, right: 16)
        gridSection.minimumInteritemSpacing = 12
        gridSection.minimumLineSpacing = 12
        let entries: [(String, UIColor)] = [("我的收藏", .systemOrange), ("浏览记录", .systemBlue),
                                            ("优惠券", .systemPink), ("积分", .systemGreen),
                                            ("我的帖子", .systemIndigo), ("我的话题", .systemTeal),
                                            ("我的视频", .systemRed), ("更多", .systemGray)]
        gridSection.itemVMs = entries.map { title, color in
            let vm = ProfileGridVM()
            vm.title = title
            vm.color = color
            vm.bindTap(title)
            return vm
        }

        let rowSection = ATListSectionVM()
        rowSection.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)
        rowSection.minimumLineSpacing = 6
        rowSection.itemVMs = ["消息通知", "隐私设置", "关于我们"].map { title in
            let vm = ProfileRowVM()
            vm.title = title
            vm.bindTap(title)
            return vm
        }

        // item 的 onEvent 默认是空的，统一接到 ListVM 上，点击才会回到底部 eventLabel
        let allSections = [avatarSection, statSection, gridSection, rowSection]
        for section in allSections {
            for item in section.itemVMs.compactMap({ $0 as? ProfileItemVM }) {
                item.onEvent = { [weak self] event in self?.onEvent?(event) }
            }
        }

        viewProxy.sectionVMs = allSections
    }
}

final class ScenarioProfileViewController: ScenarioPageViewController {

    private var profileVM: ProfileListVM { listVM as! ProfileListVM }

    init() {
        super.init(title: "个人中心",
                   hint: "4 段拼装：大头像卡 / 统计行 / 图标网格 / 列表行，每段自己的 sectionInset。",
                   listVM: ProfileListVM())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        profileVM.onEvent = { [weak self] event in
            self?.show(event)
        }
        super.viewDidLoad()
    }
}


// MARK: - 搜索结果

final class SearchResultItemVM: ATListItemVM {
    var title = ""
    var summary = ""

    override func setupData() {
        super.setupData()
        cellId = SearchResultCell.reuseId
        itemSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 72)
    }
}

final class SearchResultCell: ATListCell {
    static let reuseId = "SearchResultCell"

    private let titleLabel = UILabel()
    private let summaryLabel = UILabel()

    override func setupSubviews() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        summaryLabel.font = .systemFont(ofSize: 13)
        summaryLabel.textColor = .secondaryLabel
        summaryLabel.numberOfLines = 2
        contentView.addSubview(titleLabel)
        contentView.addSubview(summaryLabel)
    }

    override func setupLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        summaryLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalTo(titleLabel)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let vm = itemVM as? SearchResultItemVM else { return }
        titleLabel.text = vm.title
        summaryLabel.text = vm.summary
    }
}

final class SearchEmptyFooterView: ATListReuseableView {
    static let footerId = "SearchEmptyFooterView"

    private let label = UILabel()

    override func setupSubviews() {
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.text = "没有找到相关结果"
        addSubview(label)
    }

    override func setupLayout() {
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

final class SearchResultVM: ATListVM {

    var onEvent: ((String) -> Void)?

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(SearchResultCell.self, forCellWithReuseIdentifier: SearchResultCell.reuseId)
        collectionView.register(SearchEmptyFooterView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: SearchEmptyFooterView.footerId)
    }

    override func createData() {
        apply(query: "")
    }

    /// 换关键词 = 整表替换：新建 section，赋给 viewProxy 再 reloadData。
    func apply(query: String) {
        let section = ATListSectionVM()
        section.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 24, right: 16)
        section.minimumLineSpacing = 8

        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let hit = keyword.contains("灯") || keyword.lowercased().contains("h")

        if hit {
            section.itemVMs = (1...6).map { index in
                let item = SearchResultItemVM()
                item.title = "结果 \(index)：\(keyword) 相关"
                item.summary = "这是第 \(index) 条命中「\(keyword)」的结果，用于演示整表替换后的手动定高列表。"
                return item
            }
            onEvent?("命中 6 条")
        } else if keyword.isEmpty {
            section.footerId = SearchEmptyFooterView.footerId
            section.footerSize = CGSize(width: UIScreen.main.bounds.width, height: 160)
            onEvent?("输入关键词开始搜索")
        } else {
            section.footerId = SearchEmptyFooterView.footerId
            section.footerSize = CGSize(width: UIScreen.main.bounds.width, height: 160)
            onEvent?("无结果")
        }

        viewProxy.sectionVMs = [section]
        reloadData()
    }
}

final class ScenarioSearchViewController: ScenarioPageViewController {

    private var searchBar: UIView!
    private let field = UITextField()

    private var resultVM: SearchResultVM { listVM as! SearchResultVM }

    init() {
        let bar = UIView(frame: .zero)
        super.init(title: "搜索结果",
                   hint: "换关键词就是整表替换：新建 section 赋给 viewProxy 再 reloadData。没有命中时靠 footer 撑出空态。",
                   listVM: SearchResultVM(),
                   topAccessory: bar)
        searchBar = bar
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        // 先接上事件，再让基类触发 createData（首屏的「输入关键词开始搜索」才不会丢）
        resultVM.onEvent = { [weak self] event in
            self?.show(event)
        }

        super.viewDidLoad()

        searchBar.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        field.placeholder = "输入关键词（试试「灯」或「abc」）"
        field.font = .systemFont(ofSize: 14)
        field.borderStyle = .none
        field.backgroundColor = .secondarySystemBackground
        field.layer.cornerRadius = 10
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        field.leftViewMode = .always
        field.returnKeyType = .search
        field.delegate = self

        let button = UIButton(type: .system)
        button.setTitle("搜索", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.addTarget(self, action: #selector(runSearch), for: .touchUpInside)

        searchBar.addSubview(field)
        searchBar.addSubview(button)
        field.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.trailing.equalTo(button.snp.leading).offset(-8)
            make.height.equalTo(36)
        }
        button.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.equalTo(52)
        }
    }

    @objc private func runSearch() {
        field.resignFirstResponder()
        show("搜索中…")
        let keyword = field.text ?? ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.resultVM.apply(query: keyword)
        }
    }
}

extension ScenarioSearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        runSearch()
        return true
    }
}


// MARK: - 横向卡片流

final class RankItemVM: ATListItemVM {
    var index = 0
    var title = ""
    var color: UIColor = .systemBlue
    var onEvent: ((String) -> Void)?
    var isMore = false

    override func setupData() {
        super.setupData()
        cellId = isMore ? RankMoreCell.reuseId : RankCell.reuseId
        itemSize = CGSize(width: 140, height: 180)
    }
}

final class RankCell: ATListCell {
    static let reuseId = "RankCell"

    private let cover = UIView()
    private let indexLabel = UILabel()
    private let titleLabel = UILabel()

    override func setupSubviews() {
        cover.layer.cornerRadius = 10
        cover.layer.masksToBounds = true
        indexLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        indexLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.numberOfLines = 2
        cover.addSubview(indexLabel)
        contentView.addSubview(cover)
        contentView.addSubview(titleLabel)
    }

    override func setupLayout() {
        cover.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(110)
        }
        indexLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.top.equalToSuperview().offset(8)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(cover.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let vm = itemVM as? RankItemVM else { return }
        cover.backgroundColor = vm.color
        indexLabel.text = "No.\(vm.index)"
        titleLabel.text = vm.title
    }
}

final class RankMoreCell: ATListCell {
    static let reuseId = "RankMoreCell"

    private let border = CAShapeLayer()
    private let label = UILabel()

    override func setupSubviews() {
        border.strokeColor = UIColor.secondaryLabel.cgColor
        border.lineWidth = 1
        border.lineDashPattern = [4, 3]
        border.fillColor = nil
        contentView.layer.addSublayer(border)

        label.text = "更多"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        contentView.addSubview(label)
    }

    override func setupLayout() {
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        border.frame = contentView.bounds
        border.path = UIBezierPath(roundedRect: contentView.bounds.insetBy(dx: 0.5, dy: 0.5),
                                   cornerRadius: 10).cgPath
    }
}

final class RankListVM: ATListVM {

    var onEvent: ((String) -> Void)?

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(RankCell.self, forCellWithReuseIdentifier: RankCell.reuseId)
        collectionView.register(RankMoreCell.self, forCellWithReuseIdentifier: RankMoreCell.reuseId)
    }

    override func createData() {
        let palette: [UIColor] = [.systemOrange, .systemPink, .systemPurple, .systemIndigo,
                                  .systemBlue, .systemTeal, .systemGreen, .systemBrown]
        let names = ["日出", "夜跑", "旧物改造", "阳台种菜", "宠物交友", "邻里早餐",
                     "二手置换", "周末露营", "手冲咖啡", "城市骑行", "胶片冲洗", "家庭菜谱"]

        let section = ATListSectionVM()
        section.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        section.minimumLineSpacing = 12

        var items: [ATListItemVM] = names.enumerated().map { offset, name in
            let vm = RankItemVM()
            vm.index = offset + 1
            vm.title = name
            vm.color = palette[offset % palette.count]
            vm.onSelectItemBlock = { [weak self] _, _, _ in
                self?.onEvent?("点击 第 \(offset + 1) 名 \(name)")
            }
            return vm
        }

        let more = RankItemVM()
        more.isMore = true
        more.cellId = RankMoreCell.reuseId
        more.onSelectItemBlock = { [weak self] _, _, _ in
            self?.onEvent?("点击 更多")
        }
        items.append(more)

        section.itemVMs = items
        viewProxy.sectionVMs = [section]
    }
}

final class ScenarioHorizontalRankViewController: ScenarioPageViewController {

    private var rankVM: RankListVM { listVM as! RankListVM }
    private let noteLabel = UILabel()

    init() {
        super.init(title: "横向卡片流",
                   hint: "一个 section、横向滚动；卡片宽高都由 itemSize 给死，末位是「更多」卡。",
                   listVM: RankListVM(),
                   scrollDirection: .horizontal,
                   collectionViewHeight: 180)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        rankVM.onEvent = { [weak self] event in
            self?.show(event)
        }
        super.viewDidLoad()

        noteLabel.text = """
        · 一个 section 就是一条横滑轨：scrollDirection 设成 .horizontal，卡片宽高全由 itemSize 给死。
        · sectionInset 控制左右留白（这里 16），minimumLineSpacing 控制卡片间距（12）。
        · collectionView 自身高度要单独约束（这里 180）：不约束的话它会被拉成全屏高，横滑条只剩下半截空白。
        · 横向布局里 header/footer 会排在轨道的左右两端，不是上下——要栏目标题就另起一段 UILabel。
        · 末位的「更多」卡就是一个普通 item，只是换了 cellId 和虚线边框。
        """
        noteLabel.font = .systemFont(ofSize: 13)
        noteLabel.textColor = .secondaryLabel
        noteLabel.numberOfLines = 0

        view.addSubview(noteLabel)
        noteLabel.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
    }
}

// MARK: - 菜单条目

enum BusinessScenarioDemos {
    static let entries: [DemoEntry] = [
        DemoEntry(title: "设置页",
                  detail: "分组 + 异质行 + 单行刷新",
                  make: { ScenarioSettingsViewController() }),
        DemoEntry(title: "商品列表",
                  detail: "两列/单列切换 + 分页追加",
                  make: { ScenarioProductListViewController() }),
        DemoEntry(title: "消息中心",
                  detail: "自撑开异质行 + 未读只刷单行",
                  make: { ScenarioMessageCenterViewController() }),
        DemoEntry(title: "个人中心",
                  detail: "4 段拼装 + 网格与列表混排",
                  make: { ScenarioProfileViewController() }),
        DemoEntry(title: "搜索结果",
                  detail: "整表替换 + footer 空态",
                  make: { ScenarioSearchViewController() }),
        DemoEntry(title: "横向卡片流",
                  detail: "横向滚动 + 固定卡片尺寸",
                  make: { ScenarioHorizontalRankViewController() }),
        DemoEntry(title: "动态刷新",
                  detail: "数据变化 → 四种 block 的取舍",
                  make: { DynamicRefreshViewController() })
    ]
}
