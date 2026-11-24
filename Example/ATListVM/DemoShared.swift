//
//  DemoShared.swift
//  ATListVM_Example
//
//  两级菜单的公共件：DemoEntry 与分类列表 DemoMenuViewController。
//

import UIKit
import SnapKit
import ATListVM

/// 一条示例。`title` / `detail` 进列表，`make` 在点击时才创建页面。
struct DemoEntry {
    let title: String
    let detail: String
    let make: () -> UIViewController
}

/// 分类列表。手动、自动两张列表共用，条目由各 demo 文件里的 `entries` 拼出来。
final class DemoMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let entries: [DemoEntry]
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    init(title: String, entries: [DemoEntry]) {
        self.entries = entries
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DemoEntryCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "DemoEntryCell")
        let entry = entries[indexPath.row]
        cell.textLabel?.text = entry.title
        cell.detailTextLabel?.text = entry.detail
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.detailTextLabel?.numberOfLines = 2
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(entries[indexPath.row].make(), animated: true)
    }
}

// MARK: - 手动类公用件

/// 一个「说明 + 列表」的通用页面。手动类与自动类的 demo 都用它。
class DemoListViewController: UIViewController {

    private let listVM: ATListVM
    private let note: String
    private let noteLabel = UILabel()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .systemBackground
        view.config(listVM: listVM)
        view.config(viewProxy: listVM.viewProxy)
        return view
    }()

    init(title: String, note: String, listVM: ATListVM) {
        self.listVM = listVM
        self.note = note
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        noteLabel.text = note
        noteLabel.font = .systemFont(ofSize: 13)
        noteLabel.textColor = .secondaryLabel
        noteLabel.numberOfLines = 0
        view.addSubview(noteLabel)
        view.addSubview(collectionView)
        noteLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(noteLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        listVM.createData()
        listVM.reloadData()
    }
}

/// 手动类最常见的 cell：标题 + 副标题，尺寸完全由 `itemSize` 决定。
class DemoTextItemVM: ATListItemVM {
    var title = ""
    var subtitle = ""
    var background: UIColor = .secondarySystemBackground

    override func setupData() {
        super.setupData()
        cellId = DemoTextCell.reuseId
    }
}

final class DemoTextCell: ATListCell {
    static let reuseId = "DemoTextCell"

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override func setupSubviews() {
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
    }

    override func setupLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-10)
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard let item = itemVM as? DemoTextItemVM else { return }
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        contentView.backgroundColor = item.background
    }
}

/// header / footer 共用。高度由 `headerSize` / `footerSize` 给，不会自适应。
final class DemoSectionTitleView: ATListReuseableView {
    static let headerId = "DemoSectionHeader"
    static let footerId = "DemoSectionFooter"

    private let label = UILabel()

    static func register(on collectionView: UICollectionView) {
        collectionView.register(DemoSectionTitleView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: headerId)
        collectionView.register(DemoSectionTitleView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: footerId)
    }

    override func setupSubviews() {
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        addSubview(label)
    }

    override func setupLayout() {
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    override func refreshSubviews(isFromVM: Bool) {
        guard reuseIdentifier == Self.headerId else {
            label.text = "▼ footer：高度来自 footerSize"
            return
        }
        label.text = "▲ header：高度来自 headerSize"
    }
}
