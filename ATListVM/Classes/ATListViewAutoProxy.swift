//
//  ATListViewAutoProxy.swift
//  ATListVM
//
//  Created by abiaoyo on 2025/3/11.
//

import UIKit

/// Auto Layout 自撑开高度的 Proxy。
/// 打开 FlowLayout self-sizing 后，由 `ATListCell.preferredLayoutAttributesFitting` 按滚动方向锁正交轴并测量。
/// header/footer 仍走 `headerSize` / `footerSize`。
open class ATListViewAutoProxy: ATListViewProxyBase {

    open override func attach(collectionView: UICollectionView) {
        super.attach(collectionView: collectionView)
        guard let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        // 布局级 self-sizing：FlowLayout 逐项走 preferredLayoutAttributesFitting。
        // 不要用 sizeForItemAt 返回 automaticSize —— 未测量项会以 greatestFiniteMagnitude
        // 记入 contentSize，累加后溢出成 inf，列表就滚不动了。
        if flow.estimatedItemSize != UICollectionViewFlowLayout.automaticSize {
            flow.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
    }
}
