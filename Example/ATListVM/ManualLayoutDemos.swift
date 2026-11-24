//
//  ManualLayoutDemos.swift
//  ATListVM_Example
//
//  手动布局：自己给 itemSize，覆盖固定尺寸、两列、header/footer、单 section、手算高度。
//

import UIKit
import ATListVM
import SnapKit

// MARK: - 固定尺寸

final class FixedSizeListVM: ATListVM {
    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(DemoTextCell.self, forCellWithReuseIdentifier: DemoTextCell.reuseId)
    }

    override func createData() {
        let width = UIScreen.main.bounds.width
        let section = ATListSectionVM()
        section.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        section.minimumLineSpacing = 10
        let itemWidth = width - section.sectionInset.left - section.sectionInset.right
        let samples: [(String, CGFloat, UIColor)] = [
            ("固定 64pt", 64, UIColor.systemBlue.withAlphaComponent(0.12)),
            ("固定 88pt", 88, UIColor.systemOrange.withAlphaComponent(0.15)),
            ("固定 136pt", 136, UIColor.systemGreen.withAlphaComponent(0.15))
        ]
        section.itemVMs = samples.map { title, height, color in
            let item = DemoTextItemVM()
            item.title = title
            item.subtitle = "itemSize = \(Int(itemWidth)) × \(Int(height))"
            item.background = color
            item.itemSize = CGSize(width: itemWidth, height: height)
            return item
        }
        viewProxy.sectionVMs = [section]
    }
}

// MARK: - 两列

final class TwoColumnListVM: ATListVM {
    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(DemoTextCell.self, forCellWithReuseIdentifier: DemoTextCell.reuseId)
    }

    override func createData() {
        let width = UIScreen.main.bounds.width
        let section = ATListSectionVM()
        section.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        section.minimumLineSpacing = 12
        section.minimumInteritemSpacing = 12
        let itemWidth = floor((width - section.sectionInset.left - section.sectionInset.right - section.minimumInteritemSpacing) / 2)
        let heights: [CGFloat] = [72, 96, 72, 120, 96, 72]
        section.itemVMs = heights.enumerated().map { index, height in
            let item = DemoTextItemVM()
            item.title = "第 \(index + 1) 格"
            item.subtitle = "宽 \(Int(itemWidth)) × 高 \(Int(height))"
            item.background = UIColor.systemPurple.withAlphaComponent(0.12)
            item.itemSize = CGSize(width: itemWidth, height: height)
            return item
        }
        viewProxy.sectionVMs = [section]
    }
}

// MARK: - header / footer

final class HeaderFooterListVM: ATListVM {
    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(DemoTextCell.self, forCellWithReuseIdentifier: DemoTextCell.reuseId)
        DemoSectionTitleView.register(on: collectionView)
    }

    override func createData() {
        let width = UIScreen.main.bounds.width
        let section = ATListSectionVM()
        section.headerId = DemoSectionTitleView.headerId
        section.footerId = DemoSectionTitleView.footerId
        section.headerSize = CGSize(width: width, height: 44)
        section.footerSize = CGSize(width: width, height: 36)
        section.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        section.minimumLineSpacing = 10
        let itemWidth = width - section.sectionInset.left - section.sectionInset.right
        section.itemVMs = (1...3).map { index in
            let item = DemoTextItemVM()
            item.title = "第 \(index) 行"
            item.subtitle = "header / footer 的高度只能来自 headerSize / footerSize"
            item.itemSize = CGSize(width: itemWidth, height: 64)
            return item
        }
        viewProxy.sectionVMs = [section]
    }
}

// MARK: - 单 section

final class DefaultSectionListVM: ATListVM {
    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(DemoTextCell.self, forCellWithReuseIdentifier: DemoTextCell.reuseId)
    }

    override func createData() {
        let section = ATListSectionVM()
        section.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        section.minimumLineSpacing = 8
        let width = UIScreen.main.bounds.width - section.sectionInset.left - section.sectionInset.right
        section.itemVMs = (1...5).map { index in
            let item = DemoTextItemVM()
            item.title = "单 section 第 \(index) 条"
            item.subtitle = "只用 viewProxy.defaultSectionVM，不填 sectionVMs"
            item.itemSize = CGSize(width: width, height: 56)
            return item
        }
        // 注意：这里只设 defaultSectionVM
        viewProxy.defaultSectionVM = section
    }
}

// MARK: - 手算高度

enum ManualStackMetrics {
    static let top: CGFloat = 12
    static let titleHeight: CGFloat = 22
    static let gap: CGFloat = 8
    static let lineHeight: CGFloat = 20
    static let bottom: CGFloat = 12

    static func height(lineCount: Int) -> CGFloat {
        top + titleHeight + gap + CGFloat(lineCount) * lineHeight + bottom
    }
}

final class ManualStackItemVM: DemoTextItemVM {
    var lineCount = 1

    override func setupData() {
        super.setupData()
        cellId = ManualStackCell.reuseId
    }
}

final class ManualStackCell: ATListCell {
    static let reuseId = "ManualStackCell"

    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()

    override func setupSubviews() {
        contentView.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.2)
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.textColor = .label
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)
        contentView.addSubview(bodyLabel)
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let item = itemVM as? ManualStackItemVM else { return }
        titleLabel.text = item.title
        bodyLabel.text = item.subtitle
    }

    /// 手动摆放：高度公式和 VM 里的 itemSize 用的是同一套常量，避免对不上。
    override func layoutSubviews() {
        super.layoutSubviews()
        let lineCount = (itemVM as? ManualStackItemVM)?.lineCount ?? 1
        let width = contentView.bounds.width - ManualStackMetrics.top * 2
        titleLabel.frame = CGRect(x: ManualStackMetrics.top,
                                  y: ManualStackMetrics.top,
                                  width: width,
                                  height: ManualStackMetrics.titleHeight)
        bodyLabel.frame = CGRect(x: ManualStackMetrics.top,
                                 y: ManualStackMetrics.top + ManualStackMetrics.titleHeight + ManualStackMetrics.gap,
                                 width: width,
                                 height: CGFloat(lineCount) * ManualStackMetrics.lineHeight)
    }
}

final class ManualStackListVM: ATListVM {
    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(ManualStackCell.self, forCellWithReuseIdentifier: ManualStackCell.reuseId)
    }

    override func createData() {
        let width = UIScreen.main.bounds.width
        let section = ATListSectionVM()
        section.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        section.minimumLineSpacing = 10
        let itemWidth = width - section.sectionInset.left - section.sectionInset.right
        let samples: [(String, String, Int)] = [
            ("一行正文", "正文只有一行", 1),
            ("三行正文", "第一行\n第二行\n第三行", 3)
        ]
        section.itemVMs = samples.map { title, body, lines in
            let item = ManualStackItemVM()
            item.title = title
            item.subtitle = body
            item.lineCount = lines
            item.itemSize = CGSize(width: itemWidth, height: ManualStackMetrics.height(lineCount: lines))
            return item
        }
        viewProxy.sectionVMs = [section]
    }
}

// MARK: - 菜单条目

enum ManualLayoutDemos {
    static let entries: [DemoEntry] = [
        DemoEntry(title: "固定尺寸",
                  detail: "itemSize 三档高度，宽度 = 屏宽 − 左右 inset",
                  make: {
                      DemoListViewController(
                          title: "固定尺寸",
                          note: "演示 itemSize：height 是写死的，cell 里不要有冲突的约束。",
                          listVM: FixedSizeListVM())
                  }),
        DemoEntry(title: "两列",
                  detail: "宽度减半 + minimumInteritemSpacing 控制列间距",
                  make: {
                      DemoListViewController(
                          title: "两列",
                          note: "演示两列：itemSize.width 自己算成半宽，列间距靠 minimumInteritemSpacing。",
                          listVM: TwoColumnListVM())
                  }),
        DemoEntry(title: "header / footer",
                  detail: "headerSize / footerSize 固定高度，header 不会自适应",
                  make: {
                      DemoListViewController(
                          title: "header / footer",
                          note: "演示 header / footer：高度只来自 headerSize / footerSize。",
                          listVM: HeaderFooterListVM())
                  }),
        DemoEntry(title: "单 section",
                  detail: "只用 viewProxy.defaultSectionVM",
                  make: {
                      DemoListViewController(
                          title: "单 section",
                          note: "演示 defaultSectionVM：不填 sectionVMs 时，所有行都归这一个 section。",
                          listVM: DefaultSectionListVM())
                  }),
        DemoEntry(title: "手算高度",
                  detail: "layoutSubviews 摆放，itemSize 用同一个公式算",
                  make: {
                      DemoListViewController(
                          title: "手算高度",
                          note: "演示手算：cell 覆写 layoutSubviews，itemSize 与摆放共用 ManualStackMetrics。",
                          listVM: ManualStackListVM())
                  })
    ]
}
