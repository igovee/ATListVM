//
//  ATListViewProxyBase.swift
//  ATListVM
//
//  Created by abiaoyo on 2025/3/11.
//

import UIKit

/// 列表 Proxy 基类：数据源、点击、header/footer、section 间距。
/// 尺寸策略：
/// - `ATListViewProxy`：手动 `itemSize`，由 `sizeForItemAt` 返回
/// - `ATListViewAutoProxy`：不用 `sizeForItemAt`，改走布局级 self-sizing
///   （`estimatedItemSize = .automaticSize` + `ATListCell.preferredLayoutAttributesFitting`）
///
/// 基类**不再**提供默认的 `sizeForItemAt`。返回 `UICollectionViewFlowLayout.automaticSize`
/// 会让未测量项以 `greatestFiniteMagnitude` 计入 `contentSize`，累加后溢出成 `inf`，
/// 长列表就会滚不动（只能滚到估计高度，或者干脆乱跳）。
open class ATListViewProxyBase: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public weak var forwarder: AnyObject?
    public weak var delegate: ATListViewProxyDelegate?

    private var _defaultSectionVM: ATListSectionVM?
    public var defaultSectionVM: ATListSectionVM {
        get {
            if let vm = _defaultSectionVM {
                return vm
            }
            let vm = ATListSectionVM()
            _defaultSectionVM = vm
            return vm
        }
        set {
            _defaultSectionVM = newValue
        }
    }
    public lazy var sectionVMs: [ATListSectionVM] = []

    public func getSectionVM(section: Int) -> ATListSectionVM? {
        if _defaultSectionVM == nil {
            if section < sectionVMs.count {
                return sectionVMs[section]
            }
        }
        return _defaultSectionVM
    }

    public func getItemVM(section: Int, item: Int) -> ATListItemVM? {
        if let sectionVM = getSectionVM(section: section) {
            if item < sectionVM.itemVMs.count {
                return sectionVM.itemVMs[item]
            }
        }
        return nil
    }

    public func getItemVM(indexPath: IndexPath) -> ATListItemVM? {
        getItemVM(section: indexPath.section, item: indexPath.item)
    }

    /// 挂到 collectionView 时由 `UICollectionView.config(viewProxy:)` 调用。
    /// 子类可在此配置 layout（例如 AutoProxy 打开 `estimatedItemSize`）。
    open func attach(collectionView: UICollectionView) {}

    /// 必须放在类本体才能被 Swift 子类 override。
    /// 默认返回 `automaticSize`，避免基类返回 `.zero` 把 self-sizing 关掉。
    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if let forwarder = forwarder, forwarder.responds(to: aSelector) {
            return forwarder
        }
        return super.forwardingTarget(for: aSelector)
    }

    public override func responds(to aSelector: Selector!) -> Bool {
        super.responds(to: aSelector) || (forwarder != nil && forwarder!.responds(to: aSelector))
    }
}

extension ATListViewProxyBase {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        if _defaultSectionVM == nil {
            return sectionVMs.count
        }
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionVM = getSectionVM(section: section)
        sectionVM?.collectionView = collectionView
        sectionVM?.section = section
        return sectionVM?.itemVMs.count ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let itemVM = getItemVM(indexPath: indexPath) else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UICollectionViewCell", for: indexPath)
            self.delegate?.listViewProxy(collectionView: collectionView, cell: cell, indexPath: indexPath)
            return cell
        }
        itemVM.indexPath = indexPath
        itemVM.collectionView = collectionView

        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemVM.cellId, for: indexPath) as? ATListCell {
            cell.config(itemVM: itemVM, indexPath: indexPath)
            self.delegate?.listViewProxy(collectionView: collectionView, cell: cell, indexPath: indexPath)
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UICollectionViewCell", for: indexPath)
        self.delegate?.listViewProxy(collectionView: collectionView, cell: cell, indexPath: indexPath)
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let itemVM = getItemVM(indexPath: indexPath)
        itemVM?.willDisplay()
        if let listCell = cell as? ATListCell {
            listCell.willDisplay()
        }
        self.delegate?.listViewProxy(collectionView: collectionView, cellWillDisplay: cell, indexPath: indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let itemVM = getItemVM(indexPath: indexPath)
        itemVM?.didEndDisplaying()
        if let listCell = cell as? ATListCell {
            listCell.didEndDisplaying()
        }
        self.delegate?.listViewProxy(collectionView: collectionView, cellDidEndDisplaying: cell, indexPath: indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let sectionVM = getSectionVM(section: indexPath.section) else {
            return UICollectionReusableView()
        }
        if kind == ATCollectionElementKind.sectionHeader {
            if let headerId = sectionVM.headerId {
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as! ATListReuseableView
                header.config(sectionVM: sectionVM, indexPath: indexPath)
                self.delegate?.listViewProxy(collectionView: collectionView, header: header, kind: kind, indexPath: indexPath)
                return header
            }
        } else if kind == ATCollectionElementKind.sectionFooter {
            if let footerId = sectionVM.footerId {
                let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: footerId, for: indexPath) as! ATListReuseableView
                footer.config(sectionVM: sectionVM, indexPath: indexPath)
                self.delegate?.listViewProxy(collectionView: collectionView, footer: footer, kind: kind, indexPath: indexPath)
                return footer
            }
        }
        return UICollectionReusableView()
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        // 没配 headerId/footerId 时 viewForSupplementary 会返回裸 UICollectionReusableView，这里静默跳过
        (view as? ATListReuseableView)?.willDisplay()
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        (view as? ATListReuseableView)?.didEndDisplaying()
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let itemVM = getItemVM(indexPath: indexPath) else { return }
        itemVM.onSelectItemBlock?(collectionView, indexPath, itemVM)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        getSectionVM(section: section)?.headerSize ?? .zero
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        getSectionVM(section: section)?.footerSize ?? .zero
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        getSectionVM(section: section)?.sectionInset ?? .zero
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        getSectionVM(section: section)?.minimumLineSpacing ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        getSectionVM(section: section)?.minimumInteritemSpacing ?? 0
    }
}
