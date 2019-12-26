//
//  SSPopoverView.swift
//  SSFree
//
//  Created by Ning Li on 2019/12/26.
//  Copyright © 2019 Ning Li. All rights reserved.
//

import Popover

struct SSPopoverView {
    
    static func createTableView(actions: [SSPopoverAction], width: CGFloat, complete: ((_ action: SSPopoverAction) -> Void)?) -> UITableView {
        let height: CGFloat
        if actions.count > 6 {
            height = 6.5 * actions[0].height
        } else {
            height = CGFloat(actions.count) * actions[0].height
        }
        let v = SSPopoverTableView(actions: actions, frame: CGRect(origin: CGPoint(), size: CGSize(width: width, height: height)), complete: complete)
        return v
    }
    
    static func show(actions: [SSPopoverAction], width: CGFloat, arrowType: PopoverType = .auto, from: UIView, complete: ((_ action: SSPopoverAction) -> Void)?) {
        if actions.isEmpty {
            return
        }
        let options = [
            .type(arrowType),
            .cornerRadius(4),
            .animationIn(0.3),
            .arrowSize(CGSize(width: 10, height: 8)),
            .sideEdge(10)
            ] as [PopoverOption]
        let popover = Popover(options: options, showHandler: nil, dismissHandler: nil)
        let content = createTableView(actions: actions, width: width) { action in
            popover.dismiss()
            complete?(action)
        }
        popover.show(content, fromView: from)
        popover.layer.shadowColor = UIColor.gray.cgColor
        popover.layer.shadowOffset = CGSize(width: -2, height: 2)
        popover.layer.shadowOpacity = 0.5
    }
}
