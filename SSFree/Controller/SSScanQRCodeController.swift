//
//  SSScanQRCodeController.swift
//  SSFree
//
//  Created by Ning Li on 2019/12/26.
//  Copyright © 2019 Ning Li. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

/// 二维码扫描
class SSScanQRCodeController: UIViewController {
    
    /// 完成回调
    private var complete: ((_ info: String?) -> Void)?
    /// 全局扫码回调
    private var globalScanClosure: ((_ info: Any) -> Void)?
    /// 音效 id
    private var soundId: SystemSoundID = 0
    /// 扫描后展示 cell
    private lazy var isAnimDisplayCell: Bool = false
    /// 身份信息数组
    private lazy var stockIdentityArray = [String]()
    /// 正在识别标记
    private var isRecognizing: Bool = false
    
    /// 扫描视图
    @IBOutlet private var scanView: SSScanQRCodeView!
    /// 指示器
    private lazy var loadIndicator = UIActivityIndicatorView(style: .large)
    private lazy var navBar = UINavigationBar(frame: CGRect())
    private lazy var navItem = UINavigationItem(title: "扫描二维码")
    /// 状态栏样式
    private var statusBarStyle = UIStatusBarStyle.default
    
    /// 摄像设备
    private var device: AVCaptureDevice?
    /// 摄像输入流
    private var input: AVCaptureDeviceInput?
    /// 元数据输出流
    private var metadataOutput: AVCaptureMetadataOutput?
    /// 摄像数据输出流
    private var videoDataOutput: AVCaptureVideoDataOutput?
    /// 链接对象
    private var session: AVCaptureSession?
    /// 显示 layer
    private var previewLayer: AVCaptureVideoPreviewLayer?
    /// 打开相册按钮
    private lazy var openPhotoAlbumButton: UIButton = {
        let button = UIButton()
        button.setTitle("相册", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        button.sizeToFit()
        button.addTarget(self, action: #selector(openPhotoAlbum), for: .touchUpInside)
        return button
    }()
    
    /// 扫码
    ///
    /// - Parameter completion: 扫描结果回调
    class func scan(complete: @escaping (_ info: String?) -> Void) -> SSScanQRCodeController {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(identifier: "Scan") as! SSScanQRCodeController
        vc.complete = complete
        return vc
    }
    
    // MARK: - 生命周期方法
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showLoadIndicator()
        
        settingUpUI()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        let statusBarHeight = UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 20
        navBar.frame = CGRect(x: 0, y: statusBarHeight, width: UIScreen.main.bounds.width, height: 44)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
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
    
    /// 返回
    @objc private func back() {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if session?.isRunning ?? false {
            return
        } else if session != nil {
            startSession()
            return
        }
        // 检测相机是否可用
        isAvailableCamera { (success) in
            if success {
                // 初始化设备
                self.initScanDevice()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if session?.isRunning ?? false {
            stopSession()
        }
    }
    
    deinit {
        // 注销音效
        AudioServicesDisposeSystemSoundID(soundId)
    }
    
    private func settingUpUI() {
        navItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "nav_back"), style: .plain, target: self, action: #selector(back))
        navItem.rightBarButtonItem = UIBarButtonItem(customView: openPhotoAlbumButton)
        navBar.items = [navItem]
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.shadowImage = UIImage()
        navBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        view.addSubview(navBar)
    }
    
    /// 显示加载指示器
    private func showLoadIndicator() {
        loadIndicator.center = view.center
        view.addSubview(loadIndicator)
        
        loadIndicator.startAnimating()
    }
    
    /// 隐藏指示器
    private func hiddenLoadIndicator() {
        loadIndicator.stopAnimating()
        loadIndicator.removeFromSuperview()
    }
    
    /// 初始化设备
    private func initScanDevice() {
        // 初始化摄像设备
        device = AVCaptureDevice.default(for: .video)
        // 初始化摄像输入流
        input = try? AVCaptureDeviceInput(device: device!)
        // 初始化元数据输出流
        metadataOutput = AVCaptureMetadataOutput()
        // 设置输出代理
        metadataOutput!.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        // 摄像数据输出流
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput!.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        // 链接对象
        session = AVCaptureSession()
        // 采集质量
        session!.canSetSessionPreset(.inputPriority)
        // 添加输入输出流
        if session!.canAddInput(input!) {
            session!.addInput(input!)
        }
        if session!.canAddOutput(metadataOutput!) {
            session!.addOutput(metadataOutput!)
        }
        if session!.canAddOutput(videoDataOutput!) {
            session!.addOutput(videoDataOutput!)
        }
        
        // 设置支持的编码格式
        metadataOutput!.metadataObjectTypes = [AVMetadataObject.ObjectType.qr,
                                               AVMetadataObject.ObjectType.code128,
                                               AVMetadataObject.ObjectType.ean8,
                                               AVMetadataObject.ObjectType.ean13,
                                               AVMetadataObject.ObjectType.code39,
                                               AVMetadataObject.ObjectType.code93]
        // 设置扫描区域
        let interestRect = scanView.scanRect
        let statusBarHeight = UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 20
        metadataOutput!.rectOfInterest = CGRect(x: (interestRect.minY + (statusBarHeight + 44) * 0.5) / view.bounds.height,
                                                y: interestRect.minX / view.bounds.width,
                                                width: interestRect.height / view.bounds.height,
                                                height: interestRect.width / view.bounds.width)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session!)
        previewLayer!.videoGravity = .resizeAspectFill
        previewLayer!.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        view.layer.insertSublayer(previewLayer!, at: 0)
        
        startSession()
        
        // 隐藏指示图,显示扫描视图
        hiddenLoadIndicator()
        scanView.showScanView()
        
        // 创建系统音效
        guard let fileURL = Bundle.main.url(forResource: "scan", withExtension: "m4a") else {
            return
        }
        var soundId: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(fileURL as CFURL, &soundId)
        // 记录音效 id
        self.soundId = soundId
    }
    
    /// 检测相机是否可用
    private func isAvailableCamera(completion: @escaping (_ isSuccess: Bool)->()) {
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            // 模拟器不支持相机
            hiddenLoadIndicator()
            return
        }
        // 获取相机授权状态
        let state = AVCaptureDevice.authorizationStatus(for: .video)
        if state == .authorized {
            completion(true)
        } else {
            // 请求相机权限
            requestCameraAuthorization(completion: completion)
        }
    }
    
    /// 识别图片二维码
    ///
    /// - Parameters:
    ///   - image: 二维码图片
    ///   - completion: 识别结果回调
    private func recognizeImageQRCode(image: UIImage, completion: ((_ result: String?) -> Void)?) {
        // 系统自带识别方法
        let context = CIContext(options: nil)
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else {
            return
        }
        
        let features = detector.features(in: CIImage(image: image)!)
        if features.count > 0 {
            let feature = features[0] as! CIQRCodeFeature
            guard let scanResult = feature.messageString else {
                return
            }
            
            completion?(scanResult)
        }
    }
    
    /// 展示图片选择控制器
    private func showImagePickerVC() {
        // 打开相册
        let imagePickerVC = UIImagePickerController()
        imagePickerVC.sourceType = .photoLibrary
        imagePickerVC.delegate = self
        present(imagePickerVC, animated: true, completion: nil)
    }
    
    /// 启动 session
    private func startSession() {
        DispatchQueue.global().async {
            self.session?.startRunning()
        }
    }
    
    /// 停止 session
    private func stopSession() {
        DispatchQueue.global().async {
            self.session?.stopRunning()
        }
    }
}

// MARK: - 请求系统权限
extension SSScanQRCodeController {
    /// 请求相机权限
    private func requestCameraAuthorization(completion: @escaping (_ isSuccess: Bool)->()) {
        AVCaptureDevice.requestAccess(for: .video) { (success) in
            DispatchQueue.main.async {
                if success {
                    completion(true)
                } else {
                    let message = "请到【设置】->【隐私】->【相机】\n开启相机的访问权限"
                    let alertVC = UIAlertController(title: "相机权限未开启", message: message, preferredStyle: .alert)
                    alertVC.addAction(UIAlertAction(title: "好", style: .cancel, handler: nil))
                    alertVC.addAction(UIAlertAction(title: "去设置", style: .default, handler: { (_) in
                        let url = URL(string: UIApplication.openSettingsURLString)!
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        } else {
                            UIApplication.shared.openURL(url)
                        }
                    }))
                    self.present(alertVC, animated: true, completion: nil)
                    completion(false)
                }
            }
        }
    }
    
    /// 请求相册权限
    private func requestPhotoAlbumAuthorization() {
        PHPhotoLibrary.requestAuthorization { (state) in
            DispatchQueue.main.async {
                switch state {
                case .authorized:
                    // 选择图片
                    self.showImagePickerVC()
                default:
                    let message = "请到【设置】->【隐私】->【相册】\n开启相册的访问权限"
                    let alertVC = UIAlertController(title: "相册权限未开启", message: message, preferredStyle: .alert)
                    alertVC.addAction(UIAlertAction(title: "好", style: .cancel, handler: nil))
                    alertVC.addAction(UIAlertAction(title: "去设置", style: .default, handler: { (_) in
                        let url = URL(string: UIApplication.openSettingsURLString)!
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }))
                    self.present(alertVC, animated: true, completion: nil)
                }
            }
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension SSScanQRCodeController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        // 获取第一个结果
        guard let metadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let result = metadata.stringValue
            else {
                return
        }
        
        // 停止 session
        stopSession()
        AudioServicesPlaySystemSound(soundId)
        
        // 回调结果
        complete?(result)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension SSScanQRCodeController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 获取亮度值
        let metadataDict = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
        let metadata = metadataDict as! [String: Any]
        guard let exifMetadata = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any],
            let brightnessValue = exifMetadata[kCGImagePropertyExifBrightnessValue as String] as? Double else {
                return
        }
        
        scanView.brightnessValue = brightnessValue
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension SSScanQRCodeController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        startSession()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        picker.dismiss(animated: true) {
            // 识别图片二维码
            self.recognizeImageQRCode(image: image, completion: self.complete)
        }
    }
}

// MARK: - 监听事件
extension SSScanQRCodeController {
    /// 打开相册
    @objc private func openPhotoAlbum() {
        // 停止 session
        stopSession()
        
        // 判断相册权限
        let photoAuthState = PHPhotoLibrary.authorizationStatus()
        switch photoAuthState {
        case .authorized: // 已授权
            // 打开相册
            showImagePickerVC()
        default:
            // 请求权限
            requestPhotoAlbumAuthorization()
        }
    }
}
