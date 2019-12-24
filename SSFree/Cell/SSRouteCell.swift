//
//  SSRouteCell.swift
//  SSFree
//
//  Created by Ning Li on 2019/12/18.
//  Copyright © 2019 Ning Li. All rights reserved.
//

import UIKit

let kRouteCellId = "kRouteCellId"

/// 路线 cell
class SSRouteCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var selectedIconView: UIImageView!
    
    func set(_ model: SSRouteModel) {
        nameLabel.text = "\(model.ip_address):\(model.port)"
        selectedIconView.isHidden = !(model.isSelected ?? false)
    }
}
