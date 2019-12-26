//
//  SSPopoverTableView.swift
//  SSFree
//
//  Created by Ning Li on 2019/12/26.
//  Copyright © 2019 Ning Li. All rights reserved.
//

import UIKit

class SSPopoverTableView: UITableView {
    
    private lazy var actions = [SSPopoverAction]()
    private var complete: ((_ action: SSPopoverAction) -> Void)?

    convenience init(actions: [SSPopoverAction], frame: CGRect, complete: ((_ action: SSPopoverAction) -> Void)?) {
        self.init(frame: frame, style: .plain)
        self.actions = actions
        self.frame = frame
        self.complete = complete
        if actions.count <= 6 {
            isScrollEnabled = false
        }
    }
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        settingUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        settingUI()
    }
    
    private func settingUI() {
        dataSource = self
        delegate = self
        tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 1))
        register(SSPopoverViewCell.self, forCellReuseIdentifier: "SSPopoverViewCellId")
        clipsToBounds = true
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension SSPopoverTableView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SSPopoverViewCellId", for: indexPath) as! SSPopoverViewCell
        cell.set(action: actions[indexPath.row])
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return actions[indexPath.row].height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let action = actions[indexPath.row]
        complete?(action)
    }
}

// MARK: - SSPopoverViewCellDelegate
extension SSPopoverTableView: SSPopoverViewCellDelegate {
    func cell(_ cell: SSPopoverViewCell, isCollect action: SSPopoverAction) {
        actions.removeAll(where: { $0.index == action.index })
        let collected = actions.filter { $0.operateIsSelected }
        actions.insert(action, at: collected.count)
        reloadData()
    }
}

protocol SSPopoverViewCellDelegate: class {
    func cell(_ cell: SSPopoverViewCell, isCollect action: SSPopoverAction)
}

class SSPopoverViewCell: UITableViewCell {
    
    private lazy var operateButton = UIButton()
    private lazy var titleButton = UIButton()
    private var action: SSPopoverAction?
    weak var delegate: SSPopoverViewCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        settingUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        settingUI()
    }
    
    private func settingUI() {
        titleButton.titleEdgeInsets.left = 5
        titleButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        titleButton.isUserInteractionEnabled = false
        titleButton.setTitleColor(UIColor(named: "TextColor"), for: .normal)
        titleButton.titleLabel?.numberOfLines = 2
        titleButton.titleLabel?.textAlignment = .center
        contentView.addSubview(titleButton)
        
        separatorInset.right = 13
        separatorInset.left = 13
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(named: "Background")
        selectedBackgroundView = backgroundView
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if action?.operate != nil {
            operateButton.frame = CGRect(x: 10, y: 0, width: 20, height: contentView.bounds.height)
            titleButton.frame = CGRect(x: 32, y: 0, width: contentView.bounds.width - 32, height: contentView.bounds.height)
        } else {
            titleButton.frame = contentView.bounds
        }
    }
    
    func set(action: SSPopoverAction) {
        self.action = action
        titleButton.setImage(action.image, for: .normal)
        titleButton.setTitle(action.title, for: .normal)
        titleButton.isSelected = action.isSelected
        if action.operate != nil {
            titleButton.contentHorizontalAlignment = .left
            titleButton.titleLabel?.textAlignment = .left
        } else if action.image == nil {
            titleButton.contentHorizontalAlignment = .center
        } else {
            titleButton.contentHorizontalAlignment = .left
            titleButton.contentEdgeInsets.left = 13
        }
        
        if action.operate != nil {
            contentView.addSubview(operateButton)
            operateButton.setImage(action.operateNormalImage, for: .normal)
            operateButton.setImage(action.operateSelectedImage, for: .selected)
            operateButton.frame = CGRect(x: 10, y: 0, width: 20, height: bounds.height)
            operateButton.addTarget(self, action: #selector(operateButtonClick), for: .touchUpInside)
            operateButton.isSelected = action.operateIsSelected
        }
    }
    
    @objc private func operateButtonClick() {
        operateButton.isSelected = !operateButton.isSelected
        action?.operateIsSelected = operateButton.isSelected
        action?.operate?(operateButton.isSelected)
        delegate?.cell(self, isCollect: action!)
    }
}

struct SSPopoverAction {
    var title: String
    var image: UIImage?
    var height: CGFloat = 44
    var index: Int = 0
    var isSelected: Bool = false
    var operateNormalImage: UIImage?
    var operateSelectedImage: UIImage?
    var operateIsSelected: Bool = false
    var operate: ((Bool) -> Void)?
    
    init(title: String, image: UIImage?, height: CGFloat = 44, index: Int = 0, isSelected: Bool = false) {
        self.title = title
        self.image = image
        self.height = height
        self.index = index
        self.isSelected = isSelected
    }
    
    init(title: String, height: CGFloat = 44, index: Int = 0, operateNormalImage: UIImage, operateSelectedImage: UIImage, operateIsSelected: Bool, operate: ((Bool) -> Void)?) {
        self.title = title
        self.height = height
        self.index = index
        self.operateNormalImage = operateNormalImage
        self.operateSelectedImage = operateSelectedImage
        self.operateIsSelected = operateIsSelected
        self.operate = operate
    }
}
