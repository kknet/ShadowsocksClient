//
//  ViewController.swift
//  SSFree
//
//  Created by Ning Li on 2019/10/21.
//  Copyright © 2019 Ning Li. All rights reserved.
//

import UIKit
import NetworkExtension
import Lottie

class ViewController: UIViewController {
    
    let defaultStand = UserDefaults.init(suiteName: "group.com.ssfree")
    
    var status: SSVPNStatus {
        didSet {
            switch status {
            case .on:
                bgLayer.removeAllAnimations()
                switchImageView.image = #imageLiteral(resourceName: "success")
                gradientLayer1.colors = [UIColor.white.cgColor, UIColor.white.cgColor]
                gradientLayer1.locations = [0, 1]
                gradientLayer2.colors = [UIColor.white.cgColor, UIColor.white.cgColor]
                gradientLayer2.locations = [0, 1]
                switchImageView.isUserInteractionEnabled = true
            case .off:
                bgLayer.removeAllAnimations()
                switchImageView.image = #imageLiteral(resourceName: "kaiguan")
                gradientLayer1.colors = [UIColor.white.cgColor, UIColor.white.cgColor]
                gradientLayer1.locations = [0, 1]
                gradientLayer2.colors = [UIColor.white.cgColor, UIColor.white.cgColor]
                gradientLayer2.locations = [0, 1]
                switchImageView.isUserInteractionEnabled = true
            default:
                break
            }
        }
    }
    
    /// 渐变
    private lazy var gradientLayer1 = CAGradientLayer()
    private lazy var gradientLayer2 = CAGradientLayer()
    /// 渐变背景
    private lazy var bgLayer = CALayer()
    /// 渐变遮罩
    private lazy var gradientMaskLayer = CAShapeLayer()
    /// 状态栏样式
    private var statusBarStyle = UIStatusBarStyle.default
    /// 当前线路
    private var currentRoute: SSRouteModel?

    @IBOutlet weak var topBGViewHeightCons: NSLayoutConstraint!
    /// 开关
    @IBOutlet weak var switchImageView: UIImageView!
    /// 路线信息
    @IBOutlet weak var routeInfoLabel: UILabel!
    
    required init?(coder: NSCoder) {
        self.status = SSVPNManager.shared.vpnStatus
        super.init(coder: coder)
        NotificationCenter.default.addObserver(self, selector: #selector(onVPNStatusChanged), name: NSNotification.Name(kProxyServiceVPNStatusNotification), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupGradient()
        
        requestBaidu()
        
        setupAnimationView()
        
        loadDefaultRoute()
    }
    
    private func setupUI() {
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "add"), style: .plain, target: self, action: #selector(addRoute))
    }
    
    private func setupGradient() {
        gradientLayer1.colors = [UIColor.white.cgColor, UIColor.white.cgColor]
        gradientLayer1.locations = [0, 1]
        gradientLayer2.colors = [UIColor.white.cgColor, UIColor.white.cgColor]
        gradientLayer2.locations = [0 ,1]
        
        bgLayer.addSublayer(gradientLayer1)
        bgLayer.addSublayer(gradientLayer2)
        
        switchImageView.superview!.layer.insertSublayer(bgLayer, at: 0)
        
        gradientMaskLayer.lineWidth = 1
        gradientMaskLayer.lineCap = .round
        gradientMaskLayer.fillColor = UIColor.clear.cgColor
        gradientMaskLayer.strokeColor = UIColor.white.cgColor
        let radius: CGFloat = 70
        let path = UIBezierPath(arcCenter: CGPoint(x: radius, y: radius), radius: radius - 1, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        gradientMaskLayer.path = path.cgPath
        bgLayer.mask = gradientMaskLayer
    }
    
    /// 加载默认路线
    private func loadDefaultRoute() {
        guard let data = defaultStand?.value(forKey: "DefaultRoute") as? Data,
            let route = try? JSONDecoder().decode(SSRouteModel.self, from: data)
            else {
                return
        }
        currentRoute = route
        routeInfoLabel.text = "\(route.ip_address):\(route.port)"
    }
    
    private func setupAnimationView() {
        let animView = AnimationView(name: "animation")
        animView.backgroundColor = UIColor.white
        animView.frame = UIScreen.main.bounds
        animView.play { (_) in
            UIView.animate(withDuration: 0.5, animations: {
                animView.alpha = 0
            }) { (_) in
                animView.removeFromSuperview()
            }
        }
        view.addSubview(animView)
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        topBGViewHeightCons.constant = (UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 20) + 44
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        status = SSVPNManager.shared.vpnStatus
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.navigationBar.isHidden = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bgLayer.frame = CGRect(x: (UIScreen.main.bounds.width - 140) * 0.5, y: (UIScreen.main.bounds.width * 0.7 - 140) * 0.5, width: 140, height: 140)
        gradientLayer1.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: bgLayer.bounds.width * 0.5, height: bgLayer.bounds.height))
        gradientLayer2.frame = CGRect(origin: CGPoint(x: bgLayer.bounds.width * 0.5, y: 0), size: CGSize(width: bgLayer.bounds.width * 0.5, height: bgLayer.bounds.height))
        gradientMaskLayer.frame = bgLayer.bounds
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
    
    private func requestBaidu() {
        let url = URL(string: "https://m.baidu.com")!
        let request = URLRequest(url: url)
        let session = URLSession.shared
        session.dataTask(with: request).resume()
    }
}

// MARK: - 监听事件
extension ViewController {
    // 连接 / 断开连接
    @IBAction private func openOrCloseVPN(_ sender: UITapGestureRecognizer) {
        switch status {
        case .off:
            if let route = currentRoute {
                SSVPNManager.shared.ip_address = route.ip_address
                SSVPNManager.shared.port = route.port
                SSVPNManager.shared.password = route.password
                SSVPNManager.shared.algorithm = route.encryptionType
                SSVPNManager.shared.connect()
                startAnimation()
                switchImageView.isUserInteractionEnabled = false
            } else {
                let alertVC = UIAlertController(title: nil, message: "请选择路线", preferredStyle: .alert)
                let action = UIAlertAction(title: "好", style: .default, handler: nil)
                alertVC.addAction(action)
                present(alertVC, animated: true, completion: nil)
            }
        case .on:
            SSVPNManager.shared.disconnect()
            switchImageView.isUserInteractionEnabled = false
            startAnimation()
        default:
            break
        }
    }
    
    private func startAnimation() {
        gradientLayer1.colors = [UIColor(white: 1, alpha: 1).cgColor, UIColor(white: 1, alpha: 0.7).cgColor]
        gradientLayer1.locations = [0.5, 1]
        
        gradientLayer2.colors = [UIColor(white: 1, alpha: 0).cgColor, UIColor(white: 1, alpha: 0.7).cgColor]
        gradientLayer2.locations = [0.1, 1]
        // 开启动画
        let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        anim.fromValue = 0
        anim.toValue = CGFloat.pi * 2
        anim.repeatCount = Float.infinity
        anim.duration = 1.5
        
        bgLayer.add(anim, forKey: nil)
    }
    
    /// 选择路线
    @IBAction private func chooseRoute() {
        let vc = SSRouteListController.routeList(currentRoute: currentRoute) { route in
            self.currentRoute = route
            self.routeInfoLabel.text = "\(route.ip_address):\(route.port)"
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// 添加路线
    @objc private func addRoute() {
        let vc = SSAddRouteController.addRoute()
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension ViewController {
    @objc private func onVPNStatusChanged() {
        self.status = SSVPNManager.shared.vpnStatus
    }
}
