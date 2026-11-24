//
//  AutoWidthDemoViewController.swift
//  ATListVM_Example
//
//  横向 FlowLayout + ATListViewAutoProxy：标签宽度按文字撑开。
//

import UIKit
import ATListVM
import SnapKit

final class AutoWidthItemVM: ATListItemVM {
    override func setupData() {
        cellId = "AutoWidthCell"
        // 行高由 collectionView 高度决定；宽度保持 0，交给 Auto Layout 撑开
    }
}

final class AutoWidthCell: ATListCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()

    override func setupSubviews() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        contentView.addSubview(titleLabel)
    }

    override func setupLayout() {
        // 横滑：左右撑开决定宽度，上下钉到 contentView
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        titleLabel.text = itemVM?.data as? String
    }
}

final class AutoWidthListVM: ATListVM {
    override init() {
        super.init(viewProxy: ATListViewAutoProxy())
    }

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(AutoWidthCell.self, forCellWithReuseIdentifier: "AutoWidthCell")
    }

    override func createData() {
        let section = ATListSectionVM()
        section.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        section.minimumLineSpacing = 12
        section.itemVMs = ["短", "自适应宽度", "ATListViewAutoProxy", "横滑锁高、文字撑开宽", "OK"].map { text in
            let item = AutoWidthItemVM()
            item.data = text
            return item
        }
        viewProxy.sectionVMs = [section]
    }
}

final class AutoWidthDemoViewController: UIViewController {
    private let listVM = AutoWidthListVM()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .systemBackground
        view.showsHorizontalScrollIndicator = false
        view.config(listVM: listVM)
        view.config(viewProxy: listVM.viewProxy)
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "横向自适应宽度"
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(80)
        }
        listVM.createData()
        listVM.reloadData()
    }
}
