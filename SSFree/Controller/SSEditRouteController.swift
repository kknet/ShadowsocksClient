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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
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
        guard let ip_address = ipTF.text,
            let port = portTF.text,
            let password = passwordTF.text,
            let encryption = encryptionType
            else {
                let alertVC = UIAlertController(title: nil, message: "信息不完整", preferredStyle: .alert)
                let action = UIAlertAction(title: "好", style: .default, handler: nil)
                alertVC.addAction(action)
                present(alertVC, animated: true, completion: nil)
                return
        }
        
        // 拼接二维码字符串
        // 加密方式+密码 base64
        let passwordString = "\(encryption.name!):\(password)"
        let passwordData = passwordString.data(using: .utf8)!
        let passwordBase64 = passwordData.base64EncodedString()
        
        let qrcodeContent = "ss://\(passwordBase64)@\(ip_address):\(port)/?#"
        let qrcodeImageWidth = view.bounds.width - 100
        let qrcodeSize = CGSize(width: qrcodeImageWidth, height: qrcodeImageWidth)
        guard let qrcodeImage = createQRCodeImage(content: qrcodeContent, size: qrcodeSize) else {
            return
        }
        qrcodeImageView.image = qrcodeImage
        qrcodeImageView.bounds.size = qrcodeSize
        qrcodeImageView.center = CGPoint(x: view.bounds.width * 0.5, y: view.bounds.height * 0.5)
        let qrcodeImageContainer = UIView(frame: CGRect(origin: CGPoint(x: 0, y: view.bounds.height), size: view.bounds.size))
        qrcodeImageContainer.backgroundColor = UIColor.white
        qrcodeImageContainer.addSubview(qrcodeImageView)
        view.addSubview(qrcodeImageContainer)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hiddenQRCode))
        qrcodeImageContainer.addGestureRecognizer(tap)
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
            self.qrcodeImageView.superview!.frame.origin.y = 0
        }, completion: nil)
    }
    
    /// 隐藏二维码
    @objc private func hiddenQRCode() {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
            self.qrcodeImageView.superview!.frame.origin.y = self.view.bounds.height
        }, completion: nil)
    }
}

// MARK: - 绘制二维码
extension SSEditRouteController {
    fileprivate func createQRCodeImage(content: String, size: CGSize) -> UIImage? {
        //creat 二维码滤镜
        let filter = CIFilter(name: "CIQRCodeGenerator")
        //恢复默认属性
        filter?.setDefaults()
        let data = content.data(using: .utf8)
        filter?.setValue(data, forKey: "inputMessage")
        //生成二维码
        guard let ciImage = filter?.outputImage else {
            return nil
        }
        let image = transitionCIImageToUIImage(ciImage: ciImage, size: size)
        return image
    }
    
    fileprivate func transitionCIImageToUIImage(ciImage: CIImage, size: CGSize) -> UIImage? {
        //获取ciimage的bounds
        let extent = ciImage.extent
        //获取缩放比例
        let scale = min(size.width / extent.width, size.height / extent.height) * UIScreen.main.scale
        //创建bitmap(位图)
        let context = CIContext(options: nil)
        guard let bitImage = context.createCGImage(ciImage, from: extent) else { return nil }
        
        let width = extent.width * scale
        let height = extent.height * scale
        //创建灰度空间
        let cs = CGColorSpaceCreateDeviceGray()
        //创建位图上下文
        let bitRef = CGContext.init(data: nil, width:Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.none.rawValue)
        bitRef?.interpolationQuality = .none
        bitRef?.scaleBy(x: scale, y: scale)
        bitRef?.draw(bitImage, in: extent)
        //绘制
        guard let scaleImage = bitRef?.makeImage() else { return nil }
        
        let image = UIImage.init(cgImage: scaleImage)
        
        return image
    }
}
