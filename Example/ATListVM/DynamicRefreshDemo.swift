//
//  DynamicRefreshDemo.swift
//  ATListVM_Example
//
//  动态刷新：定时器每秒改一条 ItemVM 的数据，按变化类型分别走
//  refreshItemBlock / reloadItemBlock / reloadSectionBlock / reloadListBlock。
//

import UIKit
import SnapKit
import ATListVM

// MARK: - ItemVM / Cell

final class DynamicDeviceItemVM: ATListItemVM {
    var name = ""
    var isOnline = true
    var brightness = 0
    var offlineMinutes = 0

    override func setupData() {
        super.setupData()
        cellId = DynamicDeviceCell.reuseId
        syncItemSize()
    }

    /// 在线 84、离线 112：离线多一行「已离线 N 分钟」。
    func syncItemSize() {
        itemSize = CGSize(width: UIScreen.main.bounds.width - 32, height: isOnline ? 84 : 112)
    }
}

final class DynamicDeviceCell: ATListCell {
    static let reuseId = "DynamicDeviceCell"

    private let dot = UIView()
    private let nameLabel = UILabel()
    private let valueLabel = UILabel()
    private let offlineLabel = UILabel()

    override func setupSubviews() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true

        dot.layer.cornerRadius = 4
        nameLabel.font = .systemFont(ofSize: 15, weight: .medium)
        valueLabel.font = .systemFont(ofSize: 13)
        valueLabel.textColor = .secondaryLabel
        valueLabel.textAlignment = .right
        offlineLabel.font = .systemFont(ofSize: 12)
        offlineLabel.textColor = .tertiaryLabel

        contentView.addSubview(dot)
        contentView.addSubview(nameLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(offlineLabel)
    }

    override func setupLayout() {
        dot.snp.makeConstraints { make in
            make.width.height.equalTo(8)
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(20)
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(dot.snp.trailing).offset(8)
            make.centerY.equalTo(dot)
        }
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(nameLabel)
            make.leading.greaterThanOrEqualTo(nameLabel.snp.trailing).offset(8)
        }
        offlineLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(10)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let vm = itemVM as? DynamicDeviceItemVM else { return }
        nameLabel.text = vm.name
        dot.backgroundColor = vm.isOnline ? .systemGreen : .systemGray3
        valueLabel.text = vm.isOnline ? "亮度 \(vm.brightness)%" : "—"
        offlineLabel.isHidden = vm.isOnline
        offlineLabel.text = "已离线 \(vm.offlineMinutes) 分钟"
    }
}

// MARK: - Section header / footer

final class DynamicSectionVM: ATListSectionVM {
    var headerTitle = ""
    var headerSubtitle = ""
    var footerText = ""

    // willDisplay / didEndDisplaying 的累计次数，用来证明两个钩子真的被调到了
    var headerAppearCount = 0
    var headerEndCount = 0
    var footerAppearCount = 0
    var footerEndCount = 0

    var headerVisibilityText: String {
        "出现 \(headerAppearCount) 次 / 离开 \(headerEndCount) 次"
    }

    var footerVisibilityText: String {
        "出现 \(footerAppearCount) 次 / 离开 \(footerEndCount) 次"
    }
}

final class DynamicSectionHeader: ATListReuseableView {
    static let headerId = "DynamicSectionHeader"

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override func setupSubviews() {
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabel
        addSubview(titleLabel)
        addSubview(subtitleLabel)
    }

    override func setupLayout() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(6)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let vm = sectionVM as? DynamicSectionVM else { return }
        titleLabel.text = vm.headerTitle
        subtitleLabel.text = vm.headerSubtitle
    }

    override func willDisplay() {
        super.willDisplay()
        (sectionVM as? DynamicSectionVM)?.headerAppearCount += 1
    }

    override func didEndDisplaying() {
        super.didEndDisplaying()
        (sectionVM as? DynamicSectionVM)?.headerEndCount += 1
    }
}

final class DynamicSectionFooter: ATListReuseableView {
    static let footerId = "DynamicSectionFooter"

    private let label = UILabel()

    override func setupSubviews() {
        label.font = .systemFont(ofSize: 11)
        label.textColor = .tertiaryLabel
        addSubview(label)
    }

    override func setupLayout() {
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let vm = sectionVM as? DynamicSectionVM else { return }
        label.text = vm.footerText
    }

    override func willDisplay() {
        super.willDisplay()
        (sectionVM as? DynamicSectionVM)?.footerAppearCount += 1
    }

    override func didEndDisplaying() {
        super.didEndDisplaying()
        (sectionVM as? DynamicSectionVM)?.footerEndCount += 1
    }
}

// MARK: - ListVM

struct DynamicStats {
    var refresh = 0
    var reloadItem = 0
    var reloadSection = 0
    var reloadList = 0
    var header = 0
    var footer = 0
}

final class DynamicListVM: ATListVM {

    var onEvent: ((String) -> Void)?

    let section = DynamicSectionVM()
    private(set) var stats = DynamicStats()

    private var phase = 0
    private var headerCount = 0
    private var deviceSeq = 0
    private let names = ["客厅灯", "卧室灯", "阳台灯", "书房灯", "厨房灯", "门厅灯", "浴室灯", "走廊灯"]

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(DynamicDeviceCell.self, forCellWithReuseIdentifier: DynamicDeviceCell.reuseId)
        collectionView.register(DynamicSectionHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: DynamicSectionHeader.headerId)
        collectionView.register(DynamicSectionFooter.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: DynamicSectionFooter.footerId)
    }

    override func createData() {
        let screenWidth = UIScreen.main.bounds.width
        section.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 24, right: 16)
        section.minimumLineSpacing = 10
        section.headerId = DynamicSectionHeader.headerId
        section.headerSize = CGSize(width: screenWidth, height: 46)
        section.footerId = DynamicSectionFooter.footerId
        section.footerSize = CGSize(width: screenWidth, height: 36)
        section.headerTitle = "我的设备"
        section.headerSubtitle = "6 台 · 5 台在线（表头，走 refreshHeaderBlock）"
        section.footerText = "表尾：最近一次刷新 —— 还没开始（refreshFooterBlock）"

        let items = (0..<6).map { _ in makeDevice() }
        if let first = items.first {
            first.isOnline = false
            first.offlineMinutes = 3
            first.syncItemSize()
        }
        section.itemVMs = items
        viewProxy.sectionVMs = [section]
    }

    func makeDevice() -> DynamicDeviceItemVM {
        deviceSeq += 1
        let vm = DynamicDeviceItemVM()
        vm.name = names[(deviceSeq - 1) % names.count]
        vm.isOnline = true
        vm.brightness = Int.random(in: 10...100)
        vm.syncItemSize()
        return vm
    }

    func tick() {
        switch phase % 6 {
        case 0: refreshValue()
        case 1: toggleOnline()
        case 2: changeRowCount()
        case 3: reloadEverything()
        case 4: refreshHeader()
        default: refreshFooter()
        }
        phase += 1
    }

    /// 只挑已经在屏上的行：没上过屏的 item 没有 indexPath，两个 block 会直接 return，
    /// 页面就会"报了一次刷新但其实什么都没变"。
    private var visibleItems: [DynamicDeviceItemVM] {
        section.itemVMs.compactMap { $0 as? DynamicDeviceItemVM }.filter { $0.indexPath != nil }
    }

    // 值变化：只重绘，不重测高度
    private func refreshValue() {
        let online = visibleItems.filter { $0.isOnline }
        guard let item = online.randomElement() else {
            onEvent?("没有可见的在线设备，本次跳过")
            return
        }
        item.brightness = Int.random(in: 10...100)
        item.refreshItemBlock?()
        stats.refresh += 1
        onEvent?("refreshItemBlock → \(item.name) 亮度 \(item.brightness)%（行高不变）")
    }

    // 状态变化：先改 itemSize 再 reloadItem，高度才会跟着变
    private func toggleOnline() {
        guard let item = visibleItems.randomElement() else {
            section.reloadSectionBlock?()
            stats.reloadSection += 1
            onEvent?("没有可见行，改为 reloadSectionBlock 整段重载")
            return
        }
        let oldHeight = item.itemSize.height
        item.isOnline.toggle()
        item.offlineMinutes = item.isOnline ? 0 : Int.random(in: 1...9)
        item.syncItemSize()
        item.reloadItemBlock?()
        stats.reloadItem += 1
        onEvent?("reloadItemBlock → \(item.name) \(item.isOnline ? "在线" : "离线")（高度 \(Int(oldHeight)) → \(Int(item.itemSize.height))）")
    }

    // 行数变化：改 itemVMs 再 reloadSection
    private func changeRowCount() {
        if section.itemVMs.count < 7 {
            section.itemVMs.append(makeDevice())
        } else {
            section.itemVMs.removeLast()
        }
        section.reloadSectionBlock?()
        stats.reloadSection += 1
        onEvent?("reloadSectionBlock → 当前 \(section.itemVMs.count) 条")
    }

    // 表头：只刷 header，不动列表
    private func refreshHeader() {
        let items = section.itemVMs.compactMap { $0 as? DynamicDeviceItemVM }
        let online = items.filter { $0.isOnline }.count
        headerCount += 1
        section.headerSubtitle = "第 \(headerCount) 次刷表头 · \(items.count) 台 / \(online) 台在线 · "
            + section.headerVisibilityText
        section.refreshHeaderBlock?()
        stats.header += 1
        onEvent?("refreshHeaderBlock → 表头文案更新（列表没重建）")
    }

    // 表尾：只刷 footer
    private func refreshFooter() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        section.footerText = "表尾：最近一次刷新 \(formatter.string(from: Date()))（refreshFooterBlock）· "
            + section.footerVisibilityText
        section.refreshFooterBlock?()
        stats.footer += 1
        onEvent?("refreshFooterBlock → 表尾时间更新（列表没重建）")
    }

    // 整表换：重建全部数据再 reloadList
    private func reloadEverything() {
        let items = (0..<Int.random(in: 5...7)).map { _ in makeDevice() }
        if let one = items.first {
            one.isOnline = false
            one.offlineMinutes = Int.random(in: 1...9)
            one.syncItemSize()
        }
        section.itemVMs = items
        section.reloadListBlock?()
        stats.reloadList += 1
        onEvent?("reloadListBlock → 整表重建 \(section.itemVMs.count) 条")
    }
}

// MARK: - ViewController

final class DynamicRefreshViewController: ScenarioPageViewController {

    private var dynamicVM: DynamicListVM { listVM as! DynamicListVM }

    private var statsBar: UIView!
    private let statsLabel = UILabel()

    private var timer: Timer?
    private var isRunning = true

    init() {
        let bar = UIView(frame: .zero)
        super.init(title: "动态刷新",
                   hint: "每秒改一处数据，六拍循环：item 的 refresh / reloadItem，section 的 reloadSection / reloadList / 表头 / 表尾。表头表尾还能收到 willDisplay / didEndDisplaying。",
                   listVM: DynamicListVM(),
                   topAccessory: bar)
        statsBar = bar
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        // 先接事件，再让基类触发 createData
        dynamicVM.onEvent = { [weak self] event in
            self?.show(event)
            self?.refreshStats()
        }

        super.viewDidLoad()

        statsBar.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        statsLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        statsLabel.textColor = .secondaryLabel
        statsLabel.adjustsFontSizeToFitWidth = true
        statsLabel.minimumScaleFactor = 0.7
        statsLabel.numberOfLines = 2
        statsBar.addSubview(statsLabel)
        statsLabel.snp.makeConstraints { make in
            make.leading.trailing.centerY.equalToSuperview()
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "暂停",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(toggleTimer))

        refreshStats()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startTimer()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopTimer()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: 定时器

    private func startTimer() {
        guard timer == nil else { return }
        isRunning = true
        navigationItem.rightBarButtonItem?.title = "暂停"
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    @objc private func toggleTimer() {
        if timer == nil {
            startTimer()
            show("继续")
        } else {
            stopTimer()
            isRunning = false
            navigationItem.rightBarButtonItem?.title = "继续"
            show("已暂停")
        }
    }

    private func tick() {
        guard isRunning else { return }
        dynamicVM.tick()
    }

    // MARK: 统计条

    private func refreshStats() {
        let stats = dynamicVM.stats
        let count = dynamicVM.section.itemVMs.count
        // 刷新是异步的，等下一次布局跑完再读内容高度
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // reload* 只是让布局失效，不一定已经重新算过；不 lay out 就读到的是上一次的高度。
            self.collectionView.layoutIfNeeded()
            let height = self.collectionView.collectionViewLayout.collectionViewContentSize.height
            self.statsLabel.text = "item：refresh \(stats.refresh) · reloadItem \(stats.reloadItem)\n"
                + "section：reloadSection \(stats.reloadSection) · reloadList \(stats.reloadList) · "
                + "header \(stats.header) · footer \(stats.footer) · \(count) 条 · 高 \(Int(height))pt"
        }
    }
}
