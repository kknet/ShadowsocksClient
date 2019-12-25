//
//  SSRouteListController.swift
//  SSFree
//
//  Created by Ning Li on 2019/12/17.
//  Copyright © 2019 Ning Li. All rights reserved.
//

import UIKit

/// 路线列表
class SSRouteListController: UIViewController {
    
    private let defaultStand = UserDefaults.init(suiteName: "group.com.ssfree")!
    
    private lazy var navBar = UINavigationBar(frame: CGRect())
    private lazy var navItem = UINavigationItem(title: "选择线路")
    /// 状态栏样式
    private var statusBarStyle = UIStatusBarStyle.default
    /// 线路数据
    private lazy var routeData = [SSRouteModel]()
    /// 当前线路
    private var currentRoute: SSRouteModel?
    /// 完成回调
    private var complete: ((_ route: SSRouteModel) -> Void)?
    
    @IBOutlet weak var topBGViewHeightCons: NSLayoutConstraint!
    @IBOutlet weak var mainTableView: UITableView!
    
    class func routeList(currentRoute: SSRouteModel?, complete: ((_ route: SSRouteModel) -> Void)?) -> SSRouteListController {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(identifier: "RouteList") as! SSRouteListController
        vc.currentRoute = currentRoute
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
        
        loadRouteData()
    }
    
    private func setupTableView() {
        mainTableView.contentInset.top = 5
        mainTableView.rowHeight = 44
        mainTableView.register(UINib(nibName: "SSRouteCell", bundle: nil), forCellReuseIdentifier: kRouteCellId)
        mainTableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 1))
    }
    
    /// 加载线路数据
    private func loadRouteData() {
        let manager = FileManager.default
        guard let doc = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return
        }
        let routeFilePath = "\(doc)/Routes.data"
        if manager.fileExists(atPath: routeFilePath) {
            guard let array = NSArray(contentsOfFile: routeFilePath)
                else {
                    return
            }
            let temp = array.compactMap { try? JSONDecoder().decode(SSRouteModel.self, from: $0 as! Data) }
            routeData = temp
            
            if let route = currentRoute {
                routeData.forEach { $0.isSelected = ($0.id == route.id) }
            }
            
            mainTableView.reloadData()
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
    
    @objc private func back() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension SSRouteListController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routeData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kRouteCellId, for: indexPath) as! SSRouteCell
        cell.set(routeData[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let model = routeData[indexPath.row]
        let vc = SSEditRouteController.editRoute(route: model) { (route) in
            self.routeData.remove(at: indexPath.row)
            self.routeData.insert(route, at: indexPath.row)
            if route.isSelected ?? false {
                self.complete?(route)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = routeData[indexPath.row]
        complete?(model)
        defer {
            navigationController?.popViewController(animated: true)
        }
        
        guard let data = try? JSONEncoder().encode(model) else {
            return
        }
        // 保存为默认路线
        defaultStand.set(data, forKey: "DefaultRoute")
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let model = routeData[indexPath.row]
        return !(model.isSelected ?? false)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "删除") { (action, _, complete) in
            self.routeData.remove(at: indexPath.row)
            self.removeRoute(index: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            complete(true)
        }
        let config = UISwipeActionsConfiguration(actions: [action])
        return config
    }
    
    private func removeRoute(index: Int) {
        guard let doc = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return
        }
        let routeFilePath = "\(doc)/Routes.data"
        guard let array = NSMutableArray(contentsOfFile: routeFilePath) else {
            return
        }
        array.removeObject(at: index)
        array.write(toFile: routeFilePath, atomically: true)
    }
}
