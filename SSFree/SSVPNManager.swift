//
//  SSVPNManager.swift
//  SSFree
//
//  Created by Ning Li on 2019/10/21.
//  Copyright © 2019 Ning Li. All rights reserved.
//

import Foundation
import NetworkExtension

let kProxyServiceVPNStatusNotification = "kProxyServiceVPNStatusNotification"

enum SSVPNStatus {
    case off
    case connecting
    case on
    case disconnecting
}

struct SSUserConfig {
    let ip = "ip"
    let port = "port"
    let password = "password"
    let algorithm = "algorithm"
}

class SSVPNManager {
    public var ip_address: String = ""
    public var port: Int = 0
    public var password: String = ""
    public var algorithm: String = ""
    
    static let shared = SSVPNManager()
    var observerAdded: Bool = false
    
    private(set) var vpnStatus = SSVPNStatus.off {
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "kProxyServiceVPNStatusNotification"), object: nil)
        }
    }
    
    init() {
        loadProviderManager { [unowned self] (manager) in
            guard let manager = manager else {
                return
            }
            self.updateVPNStatus(manager)
        }
        addVPNStatusObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func loadProviderManager(_ complete: @escaping (NETunnelProviderManager?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            if let managers = managers,
                !managers.isEmpty {
                let manager = managers.first!
                complete(manager)
            } else {
                complete(nil)
            }
        }
    }
    
    private func addVPNStatusObserver() {
        if observerAdded {
           return
        }
        loadProviderManager { [unowned self] (manager) in
            if let manager = manager {
                self.observerAdded = true
                NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: manager.connection, queue: OperationQueue.main) { [unowned self] (notification) in
                    self.updateVPNStatus(manager)
                }
            }
        }
    }
    
    private func updateVPNStatus(_ manager: NEVPNManager) {
        switch manager.connection.status {
        case .connected:
            vpnStatus = .on
        case .connecting, .reasserting:
            vpnStatus = .connecting
        case .disconnecting:
            vpnStatus = .disconnecting
        case .disconnected, .invalid:
            vpnStatus = .off
        @unknown default:
            break
        }
    }
}

extension SSVPNManager {
    
    private func createProviderManager() -> NETunnelProviderManager {
        let manager = NETunnelProviderManager()
        let config = NETunnelProviderProtocol()
        config.serverAddress = "127.0.0.1"
        manager.protocolConfiguration = config
        manager.localizedDescription = "127.0.0.1"
        return manager
    }
    
    private func loadAndCreateProdiverManager(_ complete: @escaping (NETunnelProviderManager?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            guard let managers = managers else {
                return
            }
            let manager: NETunnelProviderManager
            if managers.isEmpty {
                manager = self.createProviderManager()
            } else {
                manager = managers.first!
                self.delDupConfig(managers)
            }
            
            manager.isEnabled = true
            self.setRuleConfig(manager)
            manager.saveToPreferences { (_) in
                manager.loadFromPreferences { (error) in
                    if error != nil {
                        complete(nil)
                    } else {
                        self.addVPNStatusObserver()
                        complete(manager)
                    }
                }
            }
        }
    }
    
    private func delDupConfig(_ managers: [NETunnelProviderManager]) {
        if managers.count > 1 {
            managers.forEach { (manager) in
                manager.removeFromPreferences { (_) in
                    
                }
            }
        }
    }
}

extension SSVPNManager {
    func connect() {
        loadAndCreateProdiverManager { (manager) in
            guard let manager = manager else {
                return
            }
            do {
                try manager.connection.startVPNTunnel(options: [:])
            } catch _ {
            }
        }
    }
    
    func disconnect() {
        loadProviderManager { (manager) in
            manager?.connection.stopVPNTunnel()
        }
    }
}

extension SSVPNManager {
    private func getRuleConfig() -> String {
        let path = Bundle.main.url(forResource: "NEKitRule", withExtension: "conf")!
        let data = try! Data(contentsOf: path)
        let str = String(data: data, encoding: .utf8)!
        return str
    }
    
    private func setRuleConfig(_ manager: NETunnelProviderManager) {
        var config = [String: Any]()
        config["ss_address"] = ip_address
        config["ss_port"] = port
        config["ss_method"] = algorithm
        config["ss_password"] = password
        config["ymal_conf"] = getRuleConfig()
        
        let originalConfig = manager.protocolConfiguration as! NETunnelProviderProtocol
        originalConfig.providerConfiguration = config
        manager.protocolConfiguration = originalConfig
    }
}
