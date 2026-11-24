//
//  CommunityDemo.swift
//  ATListVM_Example
//
//  自动布局类的复杂示例：多 section 的社区信息流。
//  展开改高度走 reloadItemBlock，点赞只改数字走 refreshItemBlock，加载更多走 insert（只插新行）。
//

import UIKit
import ATListVM
import SnapKit

// MARK: - Section / Header

final class CommunitySectionVM: ATListSectionVM {
    var headerTitle = ""
}

final class CommunitySectionHeaderView: ATListReuseableView {
    static let headerId = "CommunitySectionHeader"

    private let titleLabel = UILabel()

    static func register(on collectionView: UICollectionView) {
        collectionView.register(CommunitySectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: headerId)
    }

    override func setupSubviews() {
        titleLabel.font = .boldSystemFont(ofSize: 15)
        titleLabel.textColor = .label
        addSubview(titleLabel)
    }

    override func setupLayout() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-6)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        titleLabel.text = (sectionVM as? CommunitySectionVM)?.headerTitle
    }
}

// MARK: - ItemVM

class CommunityItemVM: ATListItemVM {
    var traceName = ""
    var onTrace: ((String) -> Void)?

    override func willDisplay() {
        onTrace?("willDisplay  \(traceName)")
    }

    override func didEndDisplaying() {
        onTrace?("didEndDisplaying  \(traceName)")
    }
}

final class CommunitySearchItemVM: CommunityItemVM {
    override func setupData() {
        super.setupData()
        cellId = CommunitySearchCell.reuseId
    }
}

final class CommunityTopicItemVM: CommunityItemVM {
    var titles: [String] = []
    override func setupData() {
        super.setupData()
        cellId = CommunityTopicCell.reuseId
    }
}

final class CommunityPostItemVM: CommunityItemVM {
    var name = ""
    var summary = ""
    var detail = ""
    var expanded = false
    var imageCount = 1
    var tags = ""
    var likeCount = 0
    var commentCount = 0

    var body: String { expanded ? detail : summary }

    override func setupData() {
        super.setupData()
        cellId = CommunityPostCell.reuseId
    }
}

final class CommunityCommentItemVM: CommunityItemVM {
    var lines: [String] = []
    override func setupData() {
        super.setupData()
        cellId = CommunityCommentCell.reuseId
    }
}

final class CommunityMoreItemVM: CommunityItemVM {
    override func setupData() {
        super.setupData()
        cellId = CommunityMoreCell.reuseId
    }
}

// MARK: - Cells

final class CommunitySearchCell: ATListCell {
    static let reuseId = "CommunitySearchCell"
    private let bar = UILabel()

    override func setupSubviews() {
        bar.text = "搜索话题、邻居"
        bar.font = .systemFont(ofSize: 15)
        bar.textColor = .secondaryLabel
        bar.textAlignment = .left
        bar.backgroundColor = UIColor.systemGray6
        bar.layer.cornerRadius = 8
        bar.layer.masksToBounds = true
        contentView.addSubview(bar)
    }

    override func setupLayout() {
        bar.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(36)
        }
    }
}

final class CommunityTopicCell: ATListCell {
    static let reuseId = "CommunityTopicCell"
    private let stack = UIStackView()

    override func setupSubviews() {
        stack.axis = .vertical
        stack.spacing = 6
        contentView.backgroundColor = UIColor.systemGray6
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        contentView.addSubview(stack)
    }

    override func setupLayout() {
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let item = itemVM as? CommunityTopicItemVM else { return }
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for title in item.titles {
            let label = UILabel()
            label.font = .systemFont(ofSize: 15)
            label.textColor = .label
            label.text = "# \(title)"
            stack.addArrangedSubview(label)
        }
    }
}

final class CommunityPostCell: ATListCell {
    static let reuseId = "CommunityPostCell"

    private let stack = UIStackView()
    private let avatar = UIView()
    private let nameLabel = UILabel()
    private let bodyLabel = UILabel()
    private let imageGrid = UIStackView()
    private let tagLabel = UILabel()
    private let likeButton = UIButton(type: .system)
    private let commentLabel = UILabel()
    private var builtImageCount = -1

    override func setupSubviews() {
        contentView.backgroundColor = UIColor.systemGray6
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true

        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        contentView.addSubview(stack)

        avatar.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.35)
        avatar.layer.cornerRadius = 16
        nameLabel.font = .boldSystemFont(ofSize: 15)
        let header = UIStackView(arrangedSubviews: [avatar, nameLabel])
        header.axis = .horizontal
        header.spacing = 8
        header.alignment = .center

        bodyLabel.font = .systemFont(ofSize: 15)
        bodyLabel.textColor = .label
        bodyLabel.numberOfLines = 0
        bodyLabel.isUserInteractionEnabled = true
        bodyLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleBody)))

        imageGrid.axis = .vertical
        imageGrid.spacing = 4

        tagLabel.font = .systemFont(ofSize: 13)
        tagLabel.textColor = .systemBlue
        tagLabel.numberOfLines = 0

        likeButton.titleLabel?.font = .systemFont(ofSize: 14)
        likeButton.contentHorizontalAlignment = .leading
        likeButton.addTarget(self, action: #selector(tapLike), for: .touchUpInside)
        commentLabel.font = .systemFont(ofSize: 14)
        commentLabel.textColor = .secondaryLabel
        let actions = UIStackView(arrangedSubviews: [likeButton, commentLabel])
        actions.axis = .horizontal
        actions.spacing = 16

        stack.addArrangedSubview(header)
        stack.addArrangedSubview(bodyLabel)
        stack.addArrangedSubview(imageGrid)
        stack.addArrangedSubview(tagLabel)
        stack.addArrangedSubview(actions)
    }

    override func setupLayout() {
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        avatar.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let item = itemVM as? CommunityPostItemVM else { return }
        nameLabel.text = item.name
        bodyLabel.text = item.body
        tagLabel.text = item.tags
        tagLabel.isHidden = item.tags.isEmpty
        likeButton.setTitle("赞 \(item.likeCount)", for: .normal)
        commentLabel.text = "评论 \(item.commentCount)"
        rebuildImages(count: item.imageCount)
    }

    /// 展开正文要重新测量高度，所以走 reloadItemBlock。
    @objc private func toggleBody() {
        guard let item = itemVM as? CommunityPostItemVM else { return }
        item.expanded.toggle()
        item.reloadItemBlock?()
    }

    /// 点赞只改数字，高度不变，走 refreshItemBlock 就够了。
    @objc private func tapLike() {
        guard let item = itemVM as? CommunityPostItemVM else { return }
        item.likeCount += 1
        item.refreshItemBlock?()
    }

    private func rebuildImages(count: Int) {
        guard count != builtImageCount else { return }
        builtImageCount = count
        imageGrid.arrangedSubviews.forEach { $0.removeFromSuperview() }
        imageGrid.isHidden = count <= 0
        guard count > 0 else { return }
        let columns = count == 1 ? 1 : 3
        let side: CGFloat = count == 1 ? 160 : 72
        var remaining = count
        while remaining > 0 {
            let rowCount = min(columns, remaining)
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 4
            row.distribution = .fillEqually
            for _ in 0..<rowCount {
                let block = UIView()
                block.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.35)
                block.layer.cornerRadius = 4
                block.snp.makeConstraints { make in
                    make.height.equalTo(side)
                }
                row.addArrangedSubview(block)
            }
            imageGrid.addArrangedSubview(row)
            remaining -= rowCount
        }
    }
}

final class CommunityCommentCell: ATListCell {
    static let reuseId = "CommunityCommentCell"
    private let stack = UIStackView()

    override func setupSubviews() {
        stack.axis = .vertical
        stack.spacing = 6
        contentView.backgroundColor = UIColor.systemGray6
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        contentView.addSubview(stack)
    }

    override func setupLayout() {
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let item = itemVM as? CommunityCommentItemVM else { return }
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for line in item.lines {
            let label = UILabel()
            label.font = .systemFont(ofSize: 14)
            label.textColor = .label
            label.numberOfLines = 0
            label.text = line
            stack.addArrangedSubview(label)
        }
    }
}

final class CommunityMoreCell: ATListCell {
    static let reuseId = "CommunityMoreCell"
    private let titleLabel = UILabel()

    override func setupSubviews() {
        titleLabel.text = "加载更多"
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .systemBlue
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
    }

    override func setupLayout() {
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(44)
        }
    }
}

// MARK: - ListVM

final class CommunityListVM: ATListVM {

    var onTrace: ((String) -> Void)?
    let postSection = CommunitySectionVM()

    override init() {
        super.init(viewProxy: ATListViewAutoProxy())
    }

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(CommunitySearchCell.self, forCellWithReuseIdentifier: CommunitySearchCell.reuseId)
        collectionView.register(CommunityTopicCell.self, forCellWithReuseIdentifier: CommunityTopicCell.reuseId)
        collectionView.register(CommunityPostCell.self, forCellWithReuseIdentifier: CommunityPostCell.reuseId)
        collectionView.register(CommunityCommentCell.self, forCellWithReuseIdentifier: CommunityCommentCell.reuseId)
        collectionView.register(CommunityMoreCell.self, forCellWithReuseIdentifier: CommunityMoreCell.reuseId)
        CommunitySectionHeaderView.register(on: collectionView)
    }

    override func createData() {
        let width = UIScreen.main.bounds.width
        viewProxy.sectionVMs = [
            makeSearchSection(width: width),
            makeTopicSection(width: width),
            makePostSection(width: width),
            makeCommentSection(width: width)
        ]
    }

    /// 加载更多：往帖子 section 末尾（「加载更多」之前）插入一条，只刷新新行。
    /// 用 insert 而不是 reloadSection：后者会整段重建，自适应布局重估高度会让视线被拽、往上滑漂移。
    func appendPost() {
        let insertAt = postSection.itemVMs.count - 1
        guard insertAt >= 0 else { return }
        let item = makePost(name: "新邻居",
                            summary: "刚加载的第 \(insertAt + 1) 条帖子。",
                            detail: "刚加载的第 \(insertAt + 1) 条帖子。展开可以看它变高。",
                            imageCount: 3,
                            tags: "#新帖",
                            likes: 1,
                            comments: 0)
        // 只插新行：reloadSections 会把整段作废重估，视线会被拽、往上滑还会漂移。
        postSection.insert(item, at: insertAt)
        onTrace?("insert  追加了第 \(insertAt + 1) 条")
    }

    private func bind(_ item: CommunityItemVM) {
        item.onTrace = { [weak self] message in
            self?.onTrace?(message)
        }
    }

    private func headerSection(_ title: String, width: CGFloat, height: CGFloat) -> CommunitySectionVM {
        let section = CommunitySectionVM()
        section.headerId = CommunitySectionHeaderView.headerId
        section.headerTitle = title
        section.headerSize = CGSize(width: width, height: height)
        section.sectionInset = UIEdgeInsets(top: 4, left: 16, bottom: 8, right: 16)
        return section
    }

    private func makeSearchSection(width: CGFloat) -> CommunitySectionVM {
        let section = headerSection("搜索", width: width, height: 36)
        let item = CommunitySearchItemVM()
        item.traceName = "搜索条"
        bind(item)
        section.itemVMs = [item]
        return section
    }

    private func makeTopicSection(width: CGFloat) -> CommunitySectionVM {
        let section = headerSection("推荐话题", width: width, height: 36)
        section.minimumLineSpacing = 8
        let short = CommunityTopicItemVM()
        short.traceName = "话题·2 条"
        short.titles = ["周末去哪儿", "阳台种菜"]
        bind(short)
        let long = CommunityTopicItemVM()
        long.traceName = "话题·5 条"
        long.titles = ["二手置换", "宠物交友", "夜跑小队", "旧物改造", "邻里早餐"]
        bind(long)
        section.itemVMs = [short, long]
        return section
    }

    private func makePostSection(width: CGFloat) -> CommunitySectionVM {
        postSection.headerId = CommunitySectionHeaderView.headerId
        postSection.headerTitle = "最新帖子"
        postSection.headerSize = CGSize(width: width, height: 36)
        postSection.sectionInset = UIEdgeInsets(top: 4, left: 16, bottom: 8, right: 16)
        postSection.minimumLineSpacing = 12
        let posts = [
            makePost(name: "小林",
                     summary: "今天阳台的番茄红了。",
                     detail: "今天阳台的番茄红了。点正文展开。展开后多出来的几行会把 cell 垫高，图片和点赞栏仍排在正文下面。",
                     imageCount: 1, tags: "#阳台", likes: 12, comments: 3),
            makePost(name: "阿南",
                     summary: "夜跑三条路线，选一条。",
                     detail: "夜跑三条路线，选一条。江边风大，公园灯暗，小区里最安全。展开后高度变化，三张图保持一行。",
                     imageCount: 3, tags: "#夜跑  #运动", likes: 28, comments: 6),
            makePost(name: "老周",
                     summary: "旧物改造做到第九张图。",
                     detail: "旧物改造做到第九张图。九宫格和少图用的是同一个 cell，张数不同，行数不同，高度就不同。",
                     imageCount: 9, tags: "#旧物改造", likes: 46, comments: 11)
        ]
        let more = CommunityMoreItemVM()
        more.traceName = "加载更多"
        more.onSelectItemBlock = { [weak self] _, _, _ in
            self?.appendPost()
        }
        bind(more)
        postSection.itemVMs = posts + [more]
        return postSection
    }

    private func makeCommentSection(width: CGFloat) -> CommunitySectionVM {
        let section = headerSection("评论预览", width: width, height: 36)
        section.sectionInset = UIEdgeInsets(top: 4, left: 16, bottom: 24, right: 16)
        section.minimumLineSpacing = 8
        let two = CommunityCommentItemVM()
        two.traceName = "评论·2 条"
        two.lines = ["阿南：番茄看着就甜。", "老周：求种子。"]
        bind(two)
        let four = CommunityCommentItemVM()
        four.traceName = "评论·4 条"
        four.lines = [
            "小林：江边那条我跑过，风很大。",
            "阿南：公园灯暗的那条晚上别单人去，上次有人摔倒。",
            "老周：小区打卡就行。",
            "新邻居：我也想加入。"
        ]
        bind(four)
        section.itemVMs = [two, four]
        return section
    }

    private func makePost(name: String, summary: String, detail: String, imageCount: Int,
                          tags: String, likes: Int, comments: Int) -> CommunityPostItemVM {
        let item = CommunityPostItemVM()
        item.traceName = "帖子·\(name)"
        item.name = name
        item.summary = summary
        item.detail = detail
        item.imageCount = imageCount
        item.tags = tags
        item.likeCount = likes
        item.commentCount = comments
        bind(item)
        return item
    }
}

// MARK: - ViewController

final class CommunityViewController: UIViewController, ATListViewProxyDelegate, ATListVMDelegate {

    private let listVM = CommunityListVM()
    private let eventLabel = UILabel()

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
        title = "社区信息流"
        view.backgroundColor = .systemBackground
        listVM.delegate = self
        listVM.viewProxy.delegate = self
        listVM.onTrace = { [weak self] message in
            self?.eventLabel.text = message
        }

        let hint = UILabel()
        hint.font = .systemFont(ofSize: 12)
        hint.textColor = .secondaryLabel
        hint.numberOfLines = 2
        hint.text = "点正文展开（reloadItemBlock）· 点赞只改数字（refreshItemBlock）· 加载更多只插入新行"

        eventLabel.font = .systemFont(ofSize: 12)
        eventLabel.textColor = .secondaryLabel
        eventLabel.numberOfLines = 1

        view.addSubview(hint)
        view.addSubview(eventLabel)
        view.addSubview(collectionView)
        hint.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        eventLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(24)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(hint.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(eventLabel.snp.top).offset(-4)
        }

        listVM.createData()
        listVM.reloadData()
    }

    func listViewProxy(collectionView: UICollectionView, cellWillDisplay: UICollectionViewCell, indexPath: IndexPath) {
        eventLabel.text = "proxy cellWillDisplay  [\(indexPath.section), \(indexPath.item)]"
    }

    func listViewProxy(collectionView: UICollectionView, cellDidEndDisplaying: UICollectionViewCell, indexPath: IndexPath) {
        eventLabel.text = "proxy cellDidEndDisplaying  [\(indexPath.section), \(indexPath.item)]"
    }

    func listVMDidChange(state: ATListVMState, tag: Int, msg: String?, err: Error?) {
        eventLabel.text = "listVMDidChange  \(msg ?? "")"
    }
}

// MARK: - 菜单条目

enum CommunityDemo {
    static let entries: [DemoEntry] = [
        DemoEntry(title: "社区信息流",
                  detail: "多 section、九宫格、展开、点赞、加载更多、显示回调",
                  make: { CommunityViewController() })
    ]
}
