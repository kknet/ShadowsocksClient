//
//  TodayViewController.swift
//  SSWidget
//
//  Created by Ning Li on 2019/10/22.
//  Copyright © 2019 Ning Li. All rights reserved.
//

import UIKit
import NotificationCenter
import TrafficPolice

class TodayViewController: UIViewController, NCWidgetProviding {
    
    let defaultStand = UserDefaults.init(suiteName: "group.com.ssfree")!
    
    /// 开关
    @IBOutlet weak var switchView: UISwitch!
    @IBOutlet weak var uploadSpeedLabel: UILabel!
    @IBOutlet weak var downloadSpeedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let route = loadDefaultRoute() {
            SSVPNManager.shared.ip_address = route.ip_address
            SSVPNManager.shared.port = route.port
            SSVPNManager.shared.password = route.password
            SSVPNManager.shared.algorithm = route.encryptionType
        }
        
        preferredContentSize = CGSize(width: UIScreen.main.bounds.width, height: 64)
        TrafficManager.shared.delegate = self
    }
    
    /// 加载默认路线
    private func loadDefaultRoute() -> SSRouteModel? {
        guard let data = defaultStand.value(forKey: "DefaultRoute") as? Data,
            let route = try? JSONDecoder().decode(SSRouteModel.self, from: data)
            else {
                return nil
        }
        return route
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        TrafficManager.shared.start()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        TrafficManager.shared.cancel()
    }
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        
        if SSVPNManager.shared.vpnStatus == .on {
            switchView.setOn(true, animated: false)
        } else {
            switchView.setOn(false, animated: false)
        }
        
        completionHandler(NCUpdateResult.newData)
    }
    
    @IBAction func switchAction(_ sender: UISwitch) {
        if sender.isOn {
            SSVPNManager.shared.connect()
        } else {
            SSVPNManager.shared.disconnect()
        }
    }
}

extension TodayViewController: TrafficManagerDelegate {
    func post(summary: TrafficSummary) {
        let receive = summary.speed.received
        if receive > 1024 * 1024 {
            let receiveSpeed = String(format: "%.1lf M/s", receive / 1024 / 1024)
            downloadSpeedLabel.text = receiveSpeed
        } else {
            let receiveSpeed = String(format: "%d K/s", Int(receive / 1024))
            downloadSpeedLabel.text = receiveSpeed
        }
        let sent = summary.speed.sent
        if sent > 1024 * 1024 {
            let sentSpeed = String(format: "%.1lf M/s", sent / 1024 / 1024)
            uploadSpeedLabel.text = sentSpeed
        } else {
            let sentSpeed = String(format: "%d K/s", Int(sent / 1024))
            uploadSpeedLabel.text = sentSpeed
        }
    }
}
