//
//  AutoHeightDemoViewController.swift
//  ATListVM_Example
//
//  纵向 FlowLayout + ATListViewAutoProxy：多行文字按内容撑开 cell 高度。
//

import UIKit
import ATListVM
import SnapKit

final class AutoHeightItemVM: ATListItemVM {
    override func setupData() {
        cellId = "AutoHeightCell"
        // 全宽自适应高：itemSize 保持 .zero，由 AutoProxy 用 collectionView 宽度去测
    }
}

final class AutoHeightCell: ATListCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()

    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        // 多行必须 numberOfLines = 0，且不要写死高度
        label.numberOfLines = 0
        return label
    }()

    override func setupSubviews() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        contentView.addSubview(titleLabel)
        contentView.addSubview(bodyLabel)
    }

    override func setupLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        let text = itemVM?.data as? String ?? ""
        titleLabel.text = "第 \((indexPath?.item ?? 0) + 1) 条"
        bodyLabel.text = text
    }
}

final class AutoHeightListVM: ATListVM {
    override init() {
        super.init(viewProxy: ATListViewAutoProxy())
    }

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(AutoHeightCell.self, forCellWithReuseIdentifier: "AutoHeightCell")
    }

    override func createData() {
        let section = ATListSectionVM()
        section.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        section.minimumLineSpacing = 12
        section.itemVMs = Self.sampleTexts.map { text in
            let item = AutoHeightItemVM()
            item.data = text
            return item
        }
        viewProxy.sectionVMs = [section]
    }

    private static let sampleTexts = [
        "短文本：一行就能放下。",
        "中等长度：FlowLayout 打开 estimatedItemSize 后，ATListCell 会在 preferredLayoutAttributesFitting 里锁住宽度，再按 Auto Layout 算出高度。",
        "很长的一段说明。列表是纵向滚动时，正交轴是宽度：用 collectionView 宽度减去 contentInset 和 sectionInset 锁死，高度走 systemLayoutSizeFitting。业务 cell 只要把子视图约束钉在 contentView 上、从上到下形成完整约束链，不要再写死 cell 高度。多行 Label 记得 numberOfLines = 0。内容变化导致高度变化时请走 reloadItemBlock，refreshItemBlock 只刷新可见 cell、不会重新问 fitting。",
        "再来一条短的。",
        "混合场景：同一列表里每条文本长度不同，cell 高度应明显不同，而不是被估成同一个值。",
        "很长的一段说明。列表是纵向滚动时，正交轴是宽度：用 collectionView 宽度减去 contentInset 和 sectionInset 锁死，高度走 systemLayoutSizeFitting。",
        "用 collectionView 宽度减去 contentInset 和 sectionInset 锁死，高度走 systemLayoutSizeFitting。业务 cell 只要把子视图约束钉在 contentView 上、从上到下形成完整约束链，不要再写死 cell 高度。多行 Label 记得 numberOfLines = 0。内容变化导致高度变化时请走 reloadItemBlock，refreshItemBlock 只刷新可见 cell、不会重新问 fitting。",
        "高度走 systemLayoutSizeFitting。业务 cell 只要把子视图约束钉在 contentView 上、从上到下形成完整约束链，不要再写死 cell 高度。多行 Label 记得 numberOfLines = 0。内容变化导致高度变化时请走 reloadItemBlock，refreshItemBlock 只刷新可见 cell、不会重新问 fitting。",
        "很长的一段说明。列表是纵向滚动时，正交轴是宽度：用 collectionView 宽度减去 contentInset 和 sectionInset 锁死，高度走 systemLayoutSizeFitting。业务 cell 只要把子视图约束钉在 contentView 上、从上到下形成完整约束链，不要再写死 cell 高度。多行 Label 记得 numberOfLines = 0。内容变化导致高度变化时请走 reloadItemBlock，refreshItemBlock 只刷新可见 cell、不会重新问 fitting。asfpsofpasfwsfasefds",
        "23092r90w3jfoserfjseolfk 很长的一段说明。列表是纵向滚动时，正交轴是宽度：用 collectionView 宽度减去 contentInset 和 sectionInset 锁死，高度走 systemLayoutSizeFitting。业务 cell 只要把子视图约束钉在 contentView 上、从上到下形成完整约束链，不要再写死 cell 高度。多行 Label 记得 numberOfLines = 0。内容变化导致高度变化时请走 reloadItemBlock，refreshItemBlock 只刷新可见 cell、不会重新问 fitting。",
        "不要再写死 cell 高度。多行 Label 记得 numberOfLines = 0。内容变化导致高度变化时请走 reloadItemBlock，refreshItemBlock 只刷新可见 cell、不会重新问 fitting。",
    ]
}

final class AutoHeightDemoViewController: UIViewController {
    private let listVM = AutoHeightListVM()

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
        title = "纵向自适应高度"
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        listVM.createData()
        listVM.reloadData()
    }
}
