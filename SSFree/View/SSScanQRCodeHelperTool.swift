//
//  SSScanQRCodeHelperTool.swift
//  SSFree
//
//  Created by Ning Li on 2019/12/26.
//  Copyright © 2019 Ning Li. All rights reserved.
//

import AVFoundation

class SSScanQRCodeHelperTool {

    /// 打开手电筒
    class func openFlashLight() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        // 判断是否可用
        if captureDevice.hasTorch && captureDevice.isTorchAvailable {
            try? captureDevice.lockForConfiguration()
            captureDevice.torchMode = .on
            captureDevice.unlockForConfiguration()
        }
    }
    
    /// 关闭手电筒
    class func closeFlashLight() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        // 判断是否可用
        if captureDevice.hasTorch && captureDevice.isTorchAvailable {
            try? captureDevice.lockForConfiguration()
            captureDevice.torchMode = .off
            captureDevice.unlockForConfiguration()
        }
    }
    
    /// 对焦
    ///
    /// - Parameter point: 焦点
    class func setFocusPoint(point: CGPoint) {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        if captureDevice.isFocusModeSupported(.autoFocus) && captureDevice.isFocusPointOfInterestSupported {
            try? captureDevice.lockForConfiguration()
            captureDevice.focusPointOfInterest = point
            captureDevice.focusMode = .autoFocus
            captureDevice.unlockForConfiguration()
        }
    }
}
