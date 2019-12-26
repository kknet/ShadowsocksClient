//
//  SSEditRouteController.swift
//  SSFree
//
//  Created by Ning Li on 2019/12/24.
//  Copyright © 2019 Ning Li. All rights reserved.
//

import UIKit

/// 编辑线路
class SSEditRouteController: UIViewController {
    
    /// 线路
    private var route: SSRouteModel!
    private var completed: ((_ route: SSRouteModel) -> Void)?
    /// 加密方式
    private var encryptionType: SSEncryptionTypeModel!
    
    private lazy var navBar = UINavigationBar(frame: CGRect())
    private lazy var navItem = UINavigationItem(title: "编辑线路")
    /// 状态栏样式
    private var statusBarStyle = UIStatusBarStyle.default
    /// 二维码 ImageView
    private lazy var qrcodeImageView = UIImageView()
    
    @IBOutlet weak var topBGViewHeightCons: NSLayoutConstraint!
    @IBOutlet weak var ipTF: UITextField!
    @IBOutlet weak var portTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var encryptionTypeLabel: UILabel!
    /// 展示二维码按钮
    @IBOutlet weak var showQRCodeButton: UIButton!
    
    class func editRoute(route: SSRouteModel, completed: ((_ route: SSRouteModel) -> Void)?) -> SSEditRouteController {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(identifier: "EditRoute") as! SSEditRouteController
        vc.route = route
        vc.completed = completed
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
        
        // 保存按钮
        let saveButton = UIButton()
        saveButton.setTitle("保存", for: .normal)
        saveButton.setTitleColor(UIColor.white, for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        
        navItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)
        
        showQRCodeButton.layer.cornerRadius = 20
        showQRCodeButton.layer.shadowColor = UIColor.black.cgColor
        showQRCodeButton.layer.shadowRadius = 5
        showQRCodeButton.layer.shadowOpacity = 0.2
        showQRCodeButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        
        encryptionType = SSEncryptionTypeModel(name: route.encryptionType, isSelected: true)
        ipTF.text = route.ip_address
        portTF.text = "\(route.port)"
        passwordTF.text = route.password
        encryptionTypeLabel.text = route.encryptionType
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
    
    /// 选择加密方式
    @IBAction private func chooseEncryptionType() {
        let vc = SSChooseEncryptionTypeController.chooseEncryptionType(currentType: encryptionType) { type in
            self.encryptionType = type
            self.encryptionTypeLabel.text = type.name
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// 保存
    @objc private func save() {
        guard let ip_address = ipTF.text,
            let port = portTF.text,
            let password = passwordTF.text,
            let encryption = encryptionType
            else {
                return
        }
        let route = SSRouteModel(ip_address: ip_address, port: port, password: password, encryptionType: encryption.name!)
        route.isSelected = true
        
        guard let doc = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first,
            let data = try? JSONEncoder().encode(route)
            else {
                return
        }
        let routeFilePath = "\(doc)/Routes.data"
        guard let array = NSMutableArray(contentsOfFile: routeFilePath) else {
            return
        }
        let temp = array.compactMap { try? JSONDecoder().decode(SSRouteModel.self, from: $0 as! Data) }
        let index = Int((temp.firstIndex(where: { $0.ip_address == self.route.ip_address && $0.port == self.route.port }))!)
        array.replaceObject(at: index, with: data)
        if array.write(toFile: routeFilePath, atomically: true) {
            completed?(route)
            navigationController?.popViewController(animated: true)
        }
    }
    
    /// 展示二维码图片
    @IBAction private func showQRCode() {
        
        
    }
}
