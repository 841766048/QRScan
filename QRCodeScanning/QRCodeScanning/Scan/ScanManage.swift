//
//  ScanManage.swift
//  QRCodeScanning
//
//

import UIKit

class ScanManage: NSObject, UIGestureRecognizerDelegate {
    
    /// 相机启动提示
    var cameraInvokeMsg:String = "相机启动中..."
    /// 自定义扫描框界面效果参数
    var style:ScanViewStyle = ScanViewStyle()
    /// 启动区域识别功能
    var isOpenInterestRect:Bool = true
    /// 增加拉近/远视频界面
    var isVideoZoom:Bool = true
    /// 闪关灯开启状态记录
    var isOpenFlash:Bool = true
    /// 扫码存储的当前图片
    var scanImage:UIImage?
    
    var scanObj:ScanNative?
    /// 扫码区域视图,二维码一般都是框
    var qRScanView:ScanView?
    /// 记录开始的缩放比例
    var beginGestureScale:CGFloat = 0.0
    /// 最后的缩放比例
    var effectiveScale:CGFloat =  1.0
    typealias scanResult = ([String])->()
    
    var blockScanResult:scanResult
    
    let addView:UIView
    
    init(addView:UIView, blockScanResult:@escaping scanResult) {
        self.blockScanResult = blockScanResult
        self.addView = addView
        super.init()
        cameraInitOver()
        drawScanView()
    }
    
    /// 绘制扫描区域
    func drawScanView() {
        if qRScanView == nil {
            var rect = addView.frame
            rect.origin = CGPoint(x:0, y:0)
            qRScanView = ScanView(frame: rect, style: style)
            addView.addSubview(qRScanView!)
        }
        qRScanView!.startDeviceReadyingWith(text: cameraInvokeMsg)
    }
    
    /// 获取闪光灯状态
    func getFlashMode() -> Bool {
        return ScanNative().getFlashMode()
    }
    /// 停止相机状态
    func stopDeviceReadying() {
        qRScanView?.stopDeviceReadying()
    }
    
    /// 权限判断
    func authorityJudgment() {
        ScanPermissions.requestCameraPemissionWithResult {[unowned self] (granted) in
            if granted {
                //延迟5秒执行
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                    self.startScan()
                }
            }else{
                self.qRScanView?.stopDeviceReadying()
                LBXPermissionSetting.showAlertToDislayPrivacySetting(withTitle: "温馨提示", msg: "请到设置隐私中开启本程序相机权限", cancel: "取消", setting: "设置")
            }
        }
    }
    
    /// 请求相机权限
    func requestCameraPemissionWithResult() {
        ScanPermissions.requestCameraPemissionWithResult {[unowned self] (granted) in
            if granted {
                //延迟5秒执行
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                    self.startScan()
                }
            }else{
                self.qRScanView?.stopDeviceReadying()
                LBXPermissionSetting.showAlertToDislayPrivacySetting(withTitle: "温馨提示", msg: "请到设置隐私中开启本程序相机权限", cancel: "取消", setting: "设置")
            }
        }
    }
    
    /// 增加拉近/远视频界面
    func cameraInitOver() {
        if isVideoZoom {
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchDetected(_:)))
            pinch.delegate = self
            addView.addGestureRecognizer(pinch)
        }
    }
    
    /// 启动设备
    func startScan() {
        guard ScanPermissions.cameraPemission() else {
            qRScanView?.stopDeviceReadying()
            LBXPermissionSetting.showAlertToDislayPrivacySetting(withTitle: "温馨提示", msg: "请到设置隐私中开启本程序相机权限", cancel: "取消", setting: "设置")
            return
        }
        
        let videoView = UIView(frame: CGRect(x: 0, y: 0, width: addView.frame.width, height: addView.frame.height))
        videoView.backgroundColor = .clear
        addView.insertSubview(videoView, at: 0)
        
        if scanObj == nil {
            var cropRect = CGRect.zero
            if isOpenInterestRect {
                cropRect = ScanView.getScanRectWith(preView: addView, style: style)
            }
            scanObj = ScanNative(preView: videoView, objType: nil, cropRect: cropRect, success: {[unowned self] (result) in
                self.blockScanResult(result)
            })
            scanObj?.setNeedCaptureImage(isNeedCaputureImg: false)
            scanObj?.setNeedAutoVideoZoom(isAutoVideoZoom: true)
        }
        scanObj?.startScan()
        qRScanView?.stopDeviceReadying()
        qRScanView?.startScanAnimation()
        addView.backgroundColor = .clear
    }
    
    func stopScan() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        scanObj?.stopScan()
        qRScanView?.stopScanAnimation()
        
    }
    
    func reStartDevice() {
        scanObj?.startScan()
    }
    
    /// 开关闪光灯
    func setTorch(torch:Bool) {
        scanObj?.setTorch(torch:torch)
    }
    
    /// 打开相册
    func openPhoto() {
        LBXPermission.authorize(with: .photos) {[unowned self]  (granted, firstTime) in
            if granted {
                self.openLocalPhoto(allowsEditing: false)
            }else{
                LBXPermissionSetting.showAlertToDislayPrivacySetting(withTitle: "温馨提示", msg: "没有相册权限，是否前往设置", cancel: "取消", setting: "设置")
            }
        }
    }
    
    /// 打开相册
    private func openLocalPhoto(allowsEditing:Bool){
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = allowsEditing
        if let vc = self.appearController() {
            vc.present(picker, animated: true, completion: nil)
        }
    }
    
    @objc func pinchDetected(_ recogniser:UIPinchGestureRecognizer) {
        effectiveScale = beginGestureScale * recogniser.scale
        if (effectiveScale < 1.0){
            effectiveScale = 1.0;
        }
        scanObj?.setVideoScale(scale: effectiveScale)
    }
}

extension ScanManage:UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            var image = info[UIImagePickerController.InfoKey.editedImage]
            image = info[UIImagePickerController.InfoKey.originalImage]
            if let _ = image {
                image = info[UIImagePickerController.InfoKey.originalImage]
            }
            if let img = image as? UIImage{
                ScanNative.recognizeImage(image: img) {[unowned self] (result) in
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
                        self.blockScanResult(result)
                    }
                }
            }
            
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension NSObject {
    /// 是否为模拟器
    var isSimulator: Bool{
        get {
            var isSim = false
            #if arch(i386) || arch(x86_64)
            isSim = true
            #endif
            return isSim
        }
    }
    
    // MARK: - 查找顶层控制器
    /// 获取顶层控制器 根据window
    func appearController() -> (UIViewController?) {
        var window = UIApplication.shared.windows.first
        //是否为当前显示的window
        if window?.windowLevel != UIWindow.Level.normal {
            let windows = UIApplication.shared.windows
            for  windowTemp in windows{
                if windowTemp.windowLevel == UIWindow.Level.normal{
                    window = windowTemp
                    break
                }
            }
        }
        let vc = window?.rootViewController
        return appearController(currentVC: vc)
    }
    
    /// 根据控制器获取 顶层控制器
    func appearController(currentVC VC: UIViewController?) -> UIViewController? {
        if VC == nil {
            return nil
        }
        if let presentVC = VC?.presentedViewController {
            //modal出来的 控制器
            return appearController(currentVC: presentVC)
        }else if let tabVC = VC as? UITabBarController {
            // tabBar 的跟控制器
            if let selectVC = tabVC.selectedViewController {
                return appearController(currentVC: selectVC)
            }
            return nil
        } else if let naiVC = VC as? UINavigationController {
            // 控制器是 nav
            return appearController(currentVC:naiVC.visibleViewController)
        } else {
            // 返回顶控制器
            return VC
        }
    }
}
