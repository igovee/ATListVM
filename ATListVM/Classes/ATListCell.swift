//
//  ATListCell.swift
//  ATListVM
//

import UIKit

open class ATListCell: UICollectionViewCell {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        // contentView 钉满 cell，避免 TAMIC 关掉后内容溢出到下一个 cell
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        setupData()
        setupSubviews()
        setupLayout()
    }
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func setupData() {}
    open func setupSubviews() {}
    open func setupLayout() {}
    
    public private(set) var itemVM: ATListItemVM?
    public private(set) var indexPath:IndexPath?

    /// FlowLayout self-sizing 时锁正交轴，避免多行文字沿未约束方向无限撑开。
    private var fittingWidthConstraint: NSLayoutConstraint?
    private var fittingHeightConstraint: NSLayoutConstraint?
    
    final func config(itemVM: ATListItemVM, indexPath:IndexPath) {
        self.indexPath = indexPath
        configAndRefresh(itemVM: itemVM)
    }
    private func configAndRefresh(itemVM: ATListItemVM) {
        self.itemVM = itemVM
        refreshSubviews(isFromVM: false)
        layoutIfNeeded()
    }
    /// 插入行之后由 section 回写，保持 cell 的 indexPath 与真实位置一致。
    func syncIndexPath(_ newValue: IndexPath) {
        indexPath = newValue
    }
    open func willDisplay() {
        
    }
    open func didEndDisplaying() {
        
    }
    open func refreshSubviews(isFromVM:Bool) {
        
    }

    /// AutoProxy + FlowLayout `estimatedItemSize = automaticSize` 时由系统调用。
    /// 手动 `ATListViewProxy` 走明确 `sizeForItemAt`，不会进这里。
    /// 不要调 `super`：传入的 frame 经常是 `automaticSize`（极大值），super 会把 origin 算成 inf 直接崩。
    /// 也不要信任 `layoutAttributes.frame` 的宽高。
    open override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = layoutAttributes.copy() as! UICollectionViewLayoutAttributes
        let origin = finiteOrigin(from: layoutAttributes.frame.origin)

        // 双轴都给了明确尺寸 → 与 AutoProxy 的手动分支一致，直接采用
        if let itemSize = itemVM?.itemSize, itemSize.width > 0, itemSize.height > 0 {
            attributes.frame = CGRect(origin: origin, size: itemSize)
            return attributes
        }

        guard let collectionView = itemVM?.collectionView ?? (superview as? UICollectionView) else {
            attributes.frame.origin = origin
            return attributes
        }

        let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        let scrollDirection = flowLayout?.scrollDirection ?? .vertical
        let section = indexPath?.section ?? itemVM?.indexPath?.section ?? 0
        let sectionInset = sectionInset(for: collectionView, flowLayout: flowLayout, section: section)
        let contentInset = collectionView.adjustedContentInset

        if scrollDirection == .vertical {
            let lockedWidth: CGFloat
            if let width = itemVM?.itemSize.width, width > 0 {
                lockedWidth = width
            } else {
                lockedWidth = collectionView.bounds.width
                    - contentInset.left - contentInset.right
                    - sectionInset.left - sectionInset.right
            }
            guard lockedWidth > 0, lockedWidth.isFinite else {
                attributes.frame.origin = origin
                return attributes
            }

            updateFittingConstraint(lockWidth: true, constant: lockedWidth)
            let size = contentView.systemLayoutSizeFitting(
                CGSize(width: lockedWidth, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            attributes.frame = CGRect(origin: origin, size: CGSize(width: lockedWidth, height: finiteLength(ceil(size.height))))
        } else {
            let lockedHeight: CGFloat
            if let height = itemVM?.itemSize.height, height > 0 {
                lockedHeight = height
            } else {
                lockedHeight = collectionView.bounds.height
                    - contentInset.top - contentInset.bottom
                    - sectionInset.top - sectionInset.bottom
            }
            guard lockedHeight > 0, lockedHeight.isFinite else {
                attributes.frame.origin = origin
                return attributes
            }

            updateFittingConstraint(lockWidth: false, constant: lockedHeight)
            let size = contentView.systemLayoutSizeFitting(
                CGSize(width: UIView.layoutFittingCompressedSize.width, height: lockedHeight),
                withHorizontalFittingPriority: .fittingSizeLevel,
                verticalFittingPriority: .required
            )
            attributes.frame = CGRect(origin: origin, size: CGSize(width: finiteLength(ceil(size.width)), height: lockedHeight))
        }
        return attributes
    }

    /// `automaticSize` 的 origin 会是极大值（仍 isFinite），UICollectionView 四舍五入后变成 inf 崩溃。
    private func finiteOrigin(from origin: CGPoint) -> CGPoint {
        func sanitized(_ value: CGFloat) -> CGFloat {
            // 屏幕坐标不可能到 1e6，超过就当无效
            guard value.isFinite, abs(value) < 1_000_000 else { return 0 }
            return value
        }
        return CGPoint(x: sanitized(origin.x), y: sanitized(origin.y))
    }

    private func finiteLength(_ value: CGFloat) -> CGFloat {
        guard value.isFinite, value >= 0, value < 1_000_000 else { return 1 }
        return value
    }

    /// sectionInset 按 section 从 FlowLayout delegate（即 Proxy）取，不要只读 `flow.sectionInset`。
    private func sectionInset(for collectionView: UICollectionView, flowLayout: UICollectionViewFlowLayout?, section: Int) -> UIEdgeInsets {
        guard let flowLayout = flowLayout else { return .zero }
        if let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
           let inset = delegate.collectionView?(collectionView, layout: flowLayout, insetForSectionAt: section) {
            return inset
        }
        return flowLayout.sectionInset
    }

    private func updateFittingConstraint(lockWidth: Bool, constant: CGFloat) {
        // 999：显示时 cell 已有明确尺寸，避免和四边约束冲突
        let priority = UILayoutPriority(999)
        if lockWidth {
            fittingHeightConstraint?.isActive = false
            if let constraint = fittingWidthConstraint {
                constraint.constant = constant
                constraint.isActive = true
            } else {
                let constraint = contentView.widthAnchor.constraint(equalToConstant: constant)
                constraint.priority = priority
                constraint.isActive = true
                fittingWidthConstraint = constraint
            }
        } else {
            fittingWidthConstraint?.isActive = false
            if let constraint = fittingHeightConstraint {
                constraint.constant = constant
                constraint.isActive = true
            } else {
                let constraint = contentView.heightAnchor.constraint(equalToConstant: constant)
                constraint.priority = priority
                constraint.isActive = true
                fittingHeightConstraint = constraint
            }
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
}
