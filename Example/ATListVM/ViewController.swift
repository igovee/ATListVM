//
//  ViewController.swift
//  ATListVM
//
//  Created by yebiaoli on 03/11/2025.
//  Copyright (c) 2025 yebiaoli. All rights reserved.
//

import UIKit
import SnapKit

/// 首页：手动 / 自动 两个分类，各自进入一个示例列表。
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ATListVM"
        view.backgroundColor = .systemBackground
        setupMenu()
    }

    private func setupMenu() {
        let manualBtn = makeButton(title: "手动布局")
        manualBtn.addTarget(self, action: #selector(openManual), for: .touchUpInside)
        let autoBtn = makeButton(title: "自动布局")
        autoBtn.addTarget(self, action: #selector(openAuto), for: .touchUpInside)

        let scenarioBtn = makeButton(title: "业务场景")
        scenarioBtn.addTarget(self, action: #selector(openScenario), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [manualBtn, autoBtn, scenarioBtn])
        stack.axis = .vertical
        stack.spacing = 16
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.equalToSuperview().offset(40)
            make.trailing.equalToSuperview().offset(-40)
        }
    }

    private func makeButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 10
        button.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        return button
    }

    @objc private func openManual() {
        let menu = DemoMenuViewController(
            title: "手动布局",
            entries: ManualLayoutDemos.entries + ManualBehaviorDemos.entries
        )
        navigationController?.pushViewController(menu, animated: true)
    }

    @objc private func openAuto() {
        let menu = DemoMenuViewController(
            title: "自动布局",
            entries: AutoDemos.entries
        )
        navigationController?.pushViewController(menu, animated: true)
    }

    @objc private func openScenario() {
        let menu = DemoMenuViewController(
            title: "业务场景",
            entries: BusinessScenarioDemos.entries
        )
        navigationController?.pushViewController(menu, animated: true)
    }

    /// storyboard 里还挂着一个隐藏按钮的 clickBtn:，留着避免连接悬空。
    @IBAction func clickBtn(_ sender: Any) {
        openManual()
    }
}
