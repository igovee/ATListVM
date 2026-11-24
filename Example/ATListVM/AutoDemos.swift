//
//  AutoDemos.swift
//  ATListVM_Example
//
//  自动布局类：纵向 / 横向（沿用已有页面）、混合手动 + 自适应、header / footer。
//

import UIKit
import ATListVM
import SnapKit

// MARK: - 混合：同一列表里手动 item 与自适应 item 并排

final class MixedAutoListVM: ATListVM {

    override init() {
        super.init(viewProxy: ATListViewAutoProxy())
    }

    override func register(collectionView: UICollectionView) {
        super.register(collectionView: collectionView)
        collectionView.register(DemoTextCell.self, forCellWithReuseIdentifier: DemoTextCell.reuseId)
    }

    override func createData() {
        let width = UIScreen.main.bounds.width - 32
        let section = ATListSectionVM()
        section.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        section.minimumLineSpacing = 10
        section.itemVMs = (0..<6).map { index in
            let item = DemoTextItemVM()
            if index % 2 == 0 {
                // 第 1/3/5 条（index 为偶数）：itemSize 两轴都为 0 → 交给 automaticSize / preferredLayoutAttributesFitting
                item.title = "第 \(index + 1) 条 · 自适应"
                item.subtitle = "itemSize 保持 .zero。高度按约束算，文字换行就变高，副标题最多两行。"
                item.background = UIColor.systemTeal.withAlphaComponent(0.12)
            } else {
                // 第 2/4/6 条（index 为奇数）：两轴都有值 → AutoProxy 直接返回 itemSize，走手动分支
                item.title = "第 \(index + 1) 条 · 手动"
                item.subtitle = "itemSize 两轴都给值，固定 56 高，不参与自适应。"
                item.background = UIColor.systemIndigo.withAlphaComponent(0.12)
                item.itemSize = CGSize(width: width, height: 56)
            }
            return item
        }
        viewProxy.sectionVMs = [section]
    }
}

// MARK: - header / footer（自适应列表里 header 仍只认 headerSize）

final class AutoHeaderFooterListVM: ATListVM {

    override init() {
        super.init(viewProxy: ATListViewAutoProxy())
    }

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
        section.itemVMs = (1...4).map { index in
            let item = DemoTextItemVM()
            item.title = "第 \(index) 条 · 自适应"
            item.subtitle = "cell 高度自适应；header / footer 不参与，只认 headerSize / footerSize。"
            item.background = UIColor.systemPink.withAlphaComponent(0.10)
            return item
        }
        viewProxy.sectionVMs = [section]
    }
}

// MARK: - 菜单条目

enum AutoDemos {
    static let entries: [DemoEntry] = [
        DemoEntry(title: "纵向自适应高度",
                  detail: "纵向 FlowLayout + automaticSize，宽度锁死、高度按约束",
                  make: { AutoHeightDemoViewController() }),
        DemoEntry(title: "横向自适应宽度",
                  detail: "横向 FlowLayout，高度锁死、宽度按文字撑开",
                  make: { AutoWidthDemoViewController() }),
        DemoEntry(title: "混合：手动 + 自适应",
                  detail: "同一列表里 itemSize 有值的走手动，其余走自适应",
                  make: {
                      DemoListViewController(
                          title: "混合：手动 + 自适应",
                          note: "演示混合：奇偶行交替，奇数行（第 1/3/5 条）itemSize 为 .zero 走自适应，偶数行两轴有值走手动 56。",
                          listVM: MixedAutoListVM())
                  }),
        DemoEntry(title: "header / footer",
                  detail: "自适应列表里 header 只认 headerSize",
                  make: {
                      DemoListViewController(
                          title: "header / footer",
                          note: "演示自适应列表的 header / footer：cell 自适应，header 仍只认 headerSize。",
                          listVM: AutoHeaderFooterListVM())
                  })
    ]
}
