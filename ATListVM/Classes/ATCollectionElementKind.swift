//
//  ATCollectionElementKind.swift
//  ATListVM
//

import UIKit

/// `UICollectionView.elementKindSectionHeader` / `...Footer` were only introduced in Swift 4.2.
/// Projects (or pod targets) still compiling in an older language mode only know the global
/// `UICollectionElementKindSection*` constants, so both spellings are bridged here.
enum ATCollectionElementKind {
    static var sectionHeader: String {
        #if swift(>=4.2)
        return UICollectionView.elementKindSectionHeader
        #else
        return UICollectionElementKindSectionHeader
        #endif
    }

    static var sectionFooter: String {
        #if swift(>=4.2)
        return UICollectionView.elementKindSectionFooter
        #else
        return UICollectionElementKindSectionFooter
        #endif
    }
}
