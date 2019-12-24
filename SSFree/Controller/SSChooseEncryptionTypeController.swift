//
//  SSChooseEncryptionTypeController.swift
//  SSFree
//
//  Created by Ning Li on 2019/12/17.
//  Copyright © 2019 Ning Li. All rights reserved.
//

import UIKit

/// 选择加密方式
class SSChooseEncryptionTypeController: UIViewController {
    
    /// 当前选择的加密方式
    private var currentType: SSEncryptionTypeModel?
    /// 加密方式数据
    private lazy var encryptionTypeData = [SSEncryptionTypeModel]()
    /// 完成回调
    private var complete: ((_ type: SSEncryptionTypeModel) -> Void)?
    
    private lazy var navBar = UINavigationBar(frame: CGRect())
    private lazy var navItem = UINavigationItem(title: "加密方式")
    /// 状态栏样式
    private var statusBarStyle = UIStatusBarStyle.default
    
    @IBOutlet weak var topBGViewHeightCons: NSLayoutConstraint!
    @IBOutlet weak var mainTableView: UITableView!
    
    class func chooseEncryptionType(currentType: SSEncryptionTypeModel?, complete: ((_ type: SSEncryptionTypeModel) -> Void)?) -> SSChooseEncryptionTypeController {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(identifier: "EncryptionType") as! SSChooseEncryptionTypeController
        vc.currentType = currentType
        vc.complete = complete
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "nav_back"), style: .plain, target: self, action: #selector(back))
        navBar.items = [navItem]
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.shadowImage = UIImage()
        navBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        view.addSubview(navBar)
        
        setupTableView()
        
        loadEncrytionTypeData()
        
        mainTableView.reloadData()
    }
    
    private func setupTableView() {
        mainTableView.rowHeight = 44
        mainTableView.contentInset.top = 5
        mainTableView.register(UINib(nibName: "SSEncryptionTypeCell", bundle: nil), forCellReuseIdentifier: kEncryptionTypeCellId)
        mainTableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 1))
    }
    
    /// 加载加密方式数据
    private func loadEncrytionTypeData() {
        guard let url = Bundle.main.url(forResource: "EncryptionType", withExtension: "plist"),
            let array = NSArray(contentsOf: url),
            let data = try? JSONSerialization.data(withJSONObject: array, options: []),
            let temp = try? JSONDecoder().decode([SSEncryptionTypeModel].self, from: data)
            else {
                return
        }
        encryptionTypeData = temp
        
        if let type = currentType {
            encryptionTypeData.forEach { (model) in
                model.isSelected = (model.name == type.name)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        let y = UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 20
        navBar.frame = CGRect(x: 0, y: y, width: UIScreen.main.bounds.width, height: 44)
        topBGViewHeightCons.constant = (UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 20) + 44
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let traitCollection = previousTraitCollection else {
            return
        }
        
        switch traitCollection.userInterfaceStyle {
        case .dark:
            statusBarStyle = .lightContent
        default:
            statusBarStyle = .default
        }
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }
    
    /// 返回
    @objc private func back() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension SSChooseEncryptionTypeController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return encryptionTypeData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kEncryptionTypeCellId, for: indexPath) as! SSEncryptionTypeCell
        cell.set(encryptionTypeData[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = encryptionTypeData[indexPath.row]
        encryptionTypeData.forEach { $0.isSelected = false }
        model.isSelected = true
        tableView.reloadData()
        complete?(model)
    }
}
