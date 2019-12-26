//
//  SSScanQRCodeView.swift
//  SSFree
//
//  Created by Ning Li on 2019/12/26.
//  Copyright © 2019 Ning Li. All rights reserved.
//

import UIKit

/// 动画时长
private let animateDuration: TimeInterval = 2.5
/// 线条颜色
private let lineColor: UIColor = UIColor(red: 67 / 255.0, green: 152 / 255.0, blue: 246 / 255.0, alpha: 1.0)

class SSScanQRCodeView: UIView {
    
    /// 亮度值
    var brightnessValue: Double = 0 {
        didSet {
            if brightnessValue < -1 {
                flashButton.isHidden = false
            } else {
                if !flashButton.isSelected {
                    flashButton.isHidden = true
                }
            }
        }
    }
    
    /// 扫描区域
    lazy var scanRect: CGRect = {
        let width = UIScreen.main.bounds.width * (260.0 / 375.0)
        let x = (UIScreen.main.bounds.width - width) * 0.5
        let y = (UIScreen.main.bounds.height - width) * 0.4
        return CGRect(x: x, y: y, width: width, height: width)
    }()
    /// Tap 手势
    private lazy var tap = UITapGestureRecognizer(target: self, action: #selector(setFocusPoint(tap:)))
    
    /// 提示 label
    private lazy var tipLabel: UILabel = {
        let tipLabel = UILabel()
        tipLabel.text = "将取景框对准二维码,即可自动扫描"
        tipLabel.textColor = UIColor.white
        tipLabel.font = UIFont.systemFont(ofSize: 12)
        tipLabel.sizeToFit()
        return tipLabel
    }()
    
    /// 打开手电筒按钮
    private lazy var flashButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("轻点照亮", for: .normal)
        button.setTitle("轻点关闭", for: .selected)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setImage(#imageLiteral(resourceName: "btn_light_on"), for: .normal)
        button.setImage(#imageLiteral(resourceName: "btn_light_off"), for: .selected)
        button.sizeToFit()
        button.titleEdgeInsets = UIEdgeInsets(top: button.imageView!.bounds.height + button.titleLabel!.bounds.height,
                                              left: -button.imageView!.bounds.width,
                                              bottom: 0,
                                              right: 0)
        button.imageEdgeInsets = UIEdgeInsets(top: 0,
                                              left: 0,
                                              bottom: 0,
                                              right: -button.titleLabel!.bounds.width)
        button.frame.size.height = button.imageView!.bounds.height + button.titleLabel!.bounds.height
        button.addTarget(self, action: #selector(operateFlashLight), for: .touchUpInside)
        return button
    }()
    
    /// 扫描区域边框
    private lazy var borderLayer: CAShapeLayer = {
        let borderLayer = CAShapeLayer()
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = lineColor.cgColor
        borderLayer.lineWidth = 1
        return borderLayer
    }()
    /// 执行动画的 layer
    private lazy var animLayer = CALayer()
}

// MARK: - 监听事件
extension SSScanQRCodeView {
    /// 打开/关闭手电筒
    @objc private func operateFlashLight() {
        if flashButton.isSelected {
            flashButton.isSelected = false
            // 关闭手电筒
            SSScanQRCodeHelperTool.closeFlashLight()
        } else {
            flashButton.isSelected = true
            // 打开手电筒
            SSScanQRCodeHelperTool.openFlashLight()
        }
    }
    
    /// 设置焦点 - tap 手势回调
    @objc private func setFocusPoint(tap: UITapGestureRecognizer) {
        let tapPoint = tap.location(in: self)
        let focusPoint = CGPoint(x: tapPoint.y / bounds.height, y: 1 - tapPoint.x / bounds.width)
        SSScanQRCodeHelperTool.setFocusPoint(point: focusPoint)
    }
}

// MARK: - 设置界面
extension SSScanQRCodeView {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        tipLabel.center = CGPoint(x: center.x,
                                  y: scanRect.maxY + 20)
        flashButton.center.x = center.x
        flashButton.center.y = scanRect.maxY - flashButton.bounds.height
        
        // 添加手势
        addGestureRecognizer(tap)
    }
    
    /// 显示扫描视图
    func showScanView() {
        // 绘制扫描区域边框
        drawBorder()
    }
    
    /// 扫码框四周填充
    private func fillScanRectOutside() {
        let topFillRect = CGRect(x: 0,
                                 y: 0,
                                 width: bounds.width,
                                 height: scanRect.minY - 0.5)
        fillRect(rect: topFillRect)

        let leftFillRect = CGRect(x: 0,
                                  y: topFillRect.maxY,
                                  width: scanRect.minX - 0.5,
                                  height: bounds.height - topFillRect.maxY)
        fillRect(rect: leftFillRect)

        let bottomFillRect = CGRect(x: leftFillRect.maxX,
                                    y: scanRect.maxY + 0.5,
                                    width: bounds.width - leftFillRect.maxX,
                                    height: bounds.height - scanRect.maxY - 0.5)
        fillRect(rect: bottomFillRect)

        let rightFillRect = CGRect(x: scanRect.maxX + 0.5,
                                   y: topFillRect.maxY,
                                   width: bounds.width - scanRect.maxX - 0.5,
                                   height: scanRect.height + 1)
        fillRect(rect: rightFillRect)
    }
    
    /// 填充
    ///
    /// - Parameter rect: 填充区域
    private func fillRect(rect: CGRect) {
        let fillLayer = CAShapeLayer()
        fillLayer.fillColor = UIColor.black.withAlphaComponent(0.3).cgColor
        let path = UIBezierPath(rect: rect)
        fillLayer.path = path.cgPath
        layer.insertSublayer(fillLayer, at: 0)
    }
    
    /// 绘制边框
    private func drawBorder() {
        animLayer.frame = scanRect
        animLayer.backgroundColor = UIColor.clear.cgColor
        layer.addSublayer(animLayer)
        
        let borderPath = UIBezierPath(rect: animLayer.bounds)
        borderLayer.path = borderPath.cgPath
        animLayer.addSublayer(borderLayer)
        
        let anim = CABasicAnimation(keyPath: "transform")
        anim.fromValue = CATransform3DMakeAffineTransform(CGAffineTransform(scaleX: 0.2, y: 0.2))
        anim.toValue = CATransform3DMakeAffineTransform(CGAffineTransform.identity)
        anim.duration = 0.3
        anim.repeatCount = 1
        anim.delegate = self
        
        animLayer.add(anim, forKey: nil)
    }
    
    /// 绘制相框角
    private func drawCorner() {
        let lineWidth: CGFloat = 4
        let lineLength: CGFloat = 18
        let offset = lineWidth * 0.5
        
        let cornerLayer = CAShapeLayer()
        cornerLayer.strokeColor = lineColor.cgColor
        cornerLayer.lineWidth = lineWidth
        let linePath = UIBezierPath()
        // 左上角
        var startPoint = CGPoint(x: scanRect.minX, y: scanRect.minY + offset)
        linePath.move(to: startPoint)
        linePath.addLine(to: CGPoint(x: startPoint.x + lineLength, y: startPoint.y))
        startPoint = CGPoint(x: scanRect.minX + offset, y: scanRect.minY)
        linePath.move(to: startPoint)
        linePath.addLine(to: CGPoint(x: startPoint.x, y: startPoint.y + lineLength))
        
        // 左下角
        startPoint = CGPoint(x: scanRect.minX, y: scanRect.maxY - offset)
        linePath.move(to: startPoint)
        linePath.addLine(to: CGPoint(x: startPoint.x + lineLength, y: startPoint.y))
        startPoint = CGPoint(x: scanRect.minX + offset, y: scanRect.maxY)
        linePath.move(to: startPoint)
        linePath.addLine(to: CGPoint(x: startPoint.x, y: startPoint.y - lineLength))
        
        // 右上角
        startPoint = CGPoint(x: scanRect.maxX, y: scanRect.minY + offset)
        linePath.move(to: startPoint)
        linePath.addLine(to: CGPoint(x: startPoint.x - lineLength, y: startPoint.y))
        startPoint = CGPoint(x: scanRect.maxX - offset, y: scanRect.minY)
        linePath.move(to: startPoint)
        linePath.addLine(to: CGPoint(x: startPoint.x, y: startPoint.y + lineLength))
        
        // 右下角
        startPoint = CGPoint(x: scanRect.maxX, y: scanRect.maxY - offset)
        linePath.move(to: startPoint)
        linePath.addLine(to: CGPoint(x: startPoint.x - lineLength, y: startPoint.y))
        startPoint = CGPoint(x: scanRect.maxX - offset, y: scanRect.maxY)
        linePath.move(to: startPoint)
        linePath.addLine(to: CGPoint(x: startPoint.x, y: startPoint.y - lineLength))
        
        cornerLayer.path = linePath.cgPath
        layer.addSublayer(cornerLayer)
    }
}

// MARK: - CAAnimationDelegate
extension SSScanQRCodeView: CAAnimationDelegate {
    /// 动画完成回调
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        // 添加提示文字
        // addSubview(tipLabel)
        // 手电筒按钮
        addSubview(flashButton)
        // 绘制相框角
        drawCorner()
        
        fillScanRectOutside()
    }
}
