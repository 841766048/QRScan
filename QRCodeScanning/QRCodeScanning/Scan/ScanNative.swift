//
//  ScanNative.swift
//  GridOperation
//
//  Created by 张海彬 on 2021/1/6.
//

import UIKit
import AVFoundation
import AssetsLibrary
import Photos

class ScanNative: NSObject {
    
    var bNeedScanResult = false
    var bHadAutoVideoZoom = false
    
//    lazy var device:AVCaptureDevice? = AVCaptureDevice.default(for: .video)
    private var device:AVCaptureDevice?
    
    var input:AVCaptureDeviceInput?
    
    var output:AVCaptureMetadataOutput?
    
    var session:AVCaptureSession?
    
    var preview:AVCaptureVideoPreviewLayer?
    
    var stillImageOutput:AVCaptureStillImageOutput?
    
    var isNeedCaputureImage = false
    
    var isAutoVideoZoom = false
    
    var arrayResult:[String] = []
    
    var arrayBarCodeType:[AVMetadataObject.ObjectType] = []
    ///视频预览显示视图
    var videoPreView:UIView?
    /// 专门用于保存描边的图层
    var containerLayer:CALayer = CALayer()
    
    typealias scanResult = ([String])->()
    
    var blockScanResult:scanResult?
    
    
    var defaultMetaDataObjectTypes:[AVMetadataObject.ObjectType] {
        get {
            var types:[AVMetadataObject.ObjectType] = [.qr,
                                                       .upce,
                                                       .code39,
                                                       .code39Mod43,
                                                       .ean13,
                                                       .ean8,
                                                       .code93,.code128,.pdf417,.aztec]
            if floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_0 {
                types.append(.interleaved2of5)
                types.append(.itf14)
                types.append(.dataMatrix)
            }
            return types
        }
    }
    
    /// 设置扫码成功后是否拍照
    func setNeedCaptureImage(isNeedCaputureImg:Bool) {
        isNeedCaputureImage = isNeedCaputureImg;
    }
    
    func setNeedAutoVideoZoom(isAutoVideoZoom:Bool) {
        self.isAutoVideoZoom = isAutoVideoZoom;
    }
    override init() {
        super.init()
    }
    /// 初始化采集相机
    /// - Parameters:
    ///   - preView: 视频显示区域
    ///   - objType:  识别码类型：如果为nil，默认支持很多类型。(二维码QR：AVMetadataObjectTypeQRCode,条码如：AVMetadataObjectTypeCode93Code
    ///   - success: 识别结果
    /// - Returns: ScanNative的实例
    init(preView:UIView, objType:[AVMetadataObject.ObjectType]? ,success:@escaping ([String]) ->()) {
        super.init()
        var TYPE:[AVMetadataObject.ObjectType]
        if let type = objType {
            TYPE = type
        }else{
            TYPE = defaultMetaDataObjectTypes
        }
        
        initParaWith(videoPreView: preView, objType: TYPE, cropRect: CGRect.zero, success: success)
    }
    
    /// 初始化采集相机
    /// - Parameters:
    ///   - preView: 视频显示区域
    ///   - objType: 识别码类型：如果为nil，默认支持很多类型。(二维码如QR：AVMetadataObjectTypeQRCode,条码如：AVMetadataObjectTypeCode93Code
    ///   - cropRect: 识别区域，值CGRectZero 全屏识别
    ///   - success: 识别结果
    /// - Returns: ScanNative的实例
    init(preView:UIView, objType:[AVMetadataObject.ObjectType]? ,cropRect:CGRect, success:@escaping ([String]) ->() ) {
        super.init()
        var TYPE:[AVMetadataObject.ObjectType]
        if let type = objType {
            TYPE = type
        }else{
            TYPE = defaultMetaDataObjectTypes
        }
        initParaWith(videoPreView: preView, objType: TYPE, cropRect: cropRect, success: success)
    }
    
    private func initParaWith(videoPreView:UIView, objType:[AVMetadataObject.ObjectType]? ,cropRect:CGRect , success:@escaping ([String]) ->() ) {
//        self.arrayBarCodeType = objType ?? self.defaultMetaDataObjectTypes
        self.arrayBarCodeType = [.qr, .ean13, .ean8, .upce, .code39, .code39Mod43, .code93, .code128, .pdf417]
        self.blockScanResult = success
        self.videoPreView = videoPreView
        
        guard let device = AVCaptureDevice.default(for: .video) else {
            return
        }
        self.device  = device
        if let deviceInput = try? AVCaptureDeviceInput(device: device) {
            input = deviceInput
            bNeedScanResult = true
            output = AVCaptureMetadataOutput()
            output!.setMetadataObjectsDelegate(self, queue:.main)
            if !cropRect.equalTo(CGRect.zero) {
                output!.rectOfInterest = cropRect
            }
            stillImageOutput = AVCaptureStillImageOutput()
            if #available(iOS 11.0, *) {
                stillImageOutput!.outputSettings = [AVVideoCodecKey:AVVideoCodecType.jpeg]
            } else {
                
                stillImageOutput!.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
            }
            
            session = AVCaptureSession()
            session!.canSetSessionPreset(.high)
            
            if session!.canAddInput(input!) {  session!.addInput(input!) }
            
            if session!.canAddOutput(output!) { session!.addOutput(output!) }
            
            if session!.canAddOutput(stillImageOutput!) { session!.addOutput(stillImageOutput!) }
            output!.metadataObjectTypes = self.arrayBarCodeType
            
            preview = AVCaptureVideoPreviewLayer(session: session!)
            preview?.videoGravity = .resizeAspectFill
            
            var frame = videoPreView.frame
            frame.origin = CGPoint.zero
            preview?.frame = frame
            
            videoPreView.layer.insertSublayer(preview!, at: 0)
            
            // 7.添加容器图层
            videoPreView.layer.addSublayer(containerLayer)
            containerLayer.frame = frame
            try? input!.device.lockForConfiguration()
//            let _ = connectionWithMediaType(mediaType: AVMediaType.video.rawValue, connections: stillImageOutput?.connections)
            
            //自动白平衡
            if device.isWhiteBalanceModeSupported(AVCaptureDevice.WhiteBalanceMode.autoWhiteBalance) {
                input?.device.whiteBalanceMode = .autoWhiteBalance
            }
            
            //先进行判断是否支持控制对焦,不开启自动对焦功能，很难识别二维码。
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.continuousAutoFocus){
                input?.device.focusMode = .continuousAutoFocus
            }
            
            //自动曝光
            if device.isExposureModeSupported(.continuousAutoExposure) {
                input!.device.exposureMode = .autoExpose
            }
            
            input!.device.unlockForConfiguration()
        }
        
        
    }
    
    /// 获取闪光灯状态
    func getFlashMode() -> Bool {
        let torch = input?.device.torchMode
        if torch == nil {
            return false
        }
        if torch! == .on {
            return true
        }
        return false
    }
    
    /// 获取摄像机最大拉远镜头
    func getVideoMaxScale() -> CGFloat {
        do {
            try input?.device.lockForConfiguration()
        }catch { }
        
        let videoConnection = connectionWithMediaType(mediaType: AVMediaType.video.rawValue, connections: stillImageOutput?.connections)
        
        let maxScale = videoConnection!.videoMaxScaleAndCropFactor
        
        input!.device.unlockForConfiguration()
        return maxScale
    }
    
    /// 获取摄像机当前镜头系数
    func getVideoZoomFactor() -> CGFloat {
        return input!.device.videoZoomFactor;
    }
    
    func getVideoPreview() -> AVCaptureVideoPreviewLayer {
        return preview!
    }
    
    /// 拉近拉远镜头
    func setVideoScale( scale: CGFloat) {
        var scale_copy = scale
        
        do {
            try input?.device.lockForConfiguration()
        }catch { }
        
        let videoConnection = connectionWithMediaType(mediaType: AVMediaType.video.rawValue, connections: stillImageOutput?.connections)
        
        let maxScaleAndCropFactor = stillImageOutput!.connection(with: .video)!.videoMaxScaleAndCropFactor/16.0
        
        if scale_copy > maxScaleAndCropFactor  {
            scale_copy = maxScaleAndCropFactor
        }
        
        let zoom = scale_copy / videoConnection!.videoScaleAndCropFactor
        
        videoConnection!.videoScaleAndCropFactor = scale
        
        input!.device.unlockForConfiguration()
        
        let transform = videoPreView?.transform
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.025)
        videoPreView!.transform = transform!.scaledBy(x: zoom, y: zoom)
        CATransaction.commit()
    }
    
    /// 修改扫码类型：二维码、条形码
    func changeScanType(objType:[AVMetadataObject.ObjectType]) {
        output?.metadataObjectTypes = objType
    }
    
    /// 开始扫码
    func startScan() {
        if let sess = session {
            if !sess.isRunning {
                sess.startRunning()
                bNeedScanResult = true
                videoPreView!.layer.insertSublayer(preview!, at: 0)
            }
            bNeedScanResult = true;
            bHadAutoVideoZoom = false;
            
            setVideoScale(scale: 1)
        }

       
    }
    
    override class func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
    }
    
    /// 停止扫码
    func stopScan() {
        bNeedScanResult = false
        if let sess = session {
            if sess.isRunning {
                bNeedScanResult = false;
                sess.stopRunning()
            }
        }
    }
    
    ///开启关闭闪光灯
    func setTorch(torch:Bool) {
        do {
            try input!.device.lockForConfiguration()
        }catch { }
        input!.device.torchMode = torch ? .on : .off
        input!.device.unlockForConfiguration()
    }
    
    /// 自动根据闪关灯状态去改变
    func changeTorch() {
        if input == nil {
            return
        }
        var torch = input!.device.torchMode
        switch input!.device.torchMode {
        case .auto:
            break
        case .off:
            torch = .on
        case .on:
            torch = .off
        default:
            break
        }
        do {
            try input!.device.lockForConfiguration()
        }catch { }
        input!.device.torchMode = torch
        input!.device.unlockForConfiguration()
    }
    
    func connectionWithMediaType(mediaType:String ,connections:[AVCaptureConnection]?) -> AVCaptureConnection? {
        if let conn = connections {
            for connection in conn {
                for port in connection.inputPorts {
                    if port.mediaType.rawValue == mediaType {
                        return connection
                    }
                }
            }
        }
        return nil
    }
    
    func getImageFromLayer(layer:CALayer, size:CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, true, UIScreen.main.scale)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func captureImage() {
        let stillImageConnection = connectionWithMediaType(mediaType: AVMediaType.video.rawValue, connections: stillImageOutput?.connections)
        
        stillImageOutput!.captureStillImageAsynchronously(from: stillImageConnection!, completionHandler: {[unowned self] (imageDataSampleBuffer, error) in
            self.stopScan()
            if let blockScanResult = self.blockScanResult {
                blockScanResult(arrayResult)
            }
        })
    }
    
    func changeVideoScale(objc:AVMetadataMachineReadableCodeObject) {
        let array = objc.corners
        if array.count > 2 {
            let point1 = array[1]
            let point2 = array[2]
            let scace = 150.0 / (point2.x - point1.x)
            
            if  scace > 1{
                var i:CGFloat = 1.0
                while i <= scace {
                    setVideoScale(scale: i)
                    i += 0.001
                }
            }
        }
    }
    
    func drawLine(objc:AVMetadataMachineReadableCodeObject) {
        let array = objc.corners
        
        // 1.创建形状图层, 用于保存绘制的矩形
        let layer = CAShapeLayer()
        // 设置线宽
        layer.lineWidth = 2
        layer.strokeColor = UIColor.green.cgColor
        layer.fillColor = UIColor.clear.cgColor
        
        let path = UIBezierPath()
        let index = 0
        
        let point = array[index+1]
        
        path.move(to: point)
        
        var i = 0
        
        while i < array.count {
            let poi = array[i]
            path.addLine(to: poi)
            i += 1
        }
        path.close()
        layer.path = path.cgPath
        containerLayer.addSublayer(layer)
        
    }
    
    func clearLayers() {
        if (containerLayer.sublayers != nil) {
            for subLayer in containerLayer.sublayers! {
                subLayer.removeFromSuperlayer()
            }
        }
    }
    
}

extension ScanNative: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if !bNeedScanResult {
            return
        }
        
        bNeedScanResult = false
        
        arrayResult.removeAll()
        
        for current in metadataObjects {
            if let metadataObject = current as? AVMetadataMachineReadableCodeObject {
                bNeedScanResult = false
                let scannedResult = metadataObject.stringValue
                if let value = scannedResult  {
                    arrayResult.append(value)
                }
            }
        }
        
        if arrayResult.count < 1 {
            bNeedScanResult = false
            return
        }
        
        if isAutoVideoZoom && !bHadAutoVideoZoom {
            let obj = preview!.transformedMetadataObject(for: metadataObjects.last!)
            changeVideoScale(objc: obj as! AVMetadataMachineReadableCodeObject)
            bNeedScanResult = true;
            bHadAutoVideoZoom = true;
            return
        }
        
        if isNeedCaputureImage {
            captureImage()
        }else{
            stopScan()
            if let block = blockScanResult {
                block(arrayResult)
            }
        }
    }
}

extension ScanNative {
    
    /// 识别条码图片
    /// - Parameters:
    ///   - image: 图片
    ///   - success: 结果回调
    /// - Returns:
    static func recognizeImage( image:UIImage ,success:@escaping ([String]) -> ()) {
        if #available(iOS 8.0, *) {
            let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])
            if detector == nil {
                return
            }
            let features = detector?.features(in: CIImage(cgImage: image.cgImage!))
            var mutableArray:[String] = []
     
            for feature in  features! {
                if let frat = feature as? CIQRCodeFeature {
                    if let scannedResult = frat.messageString {
                        mutableArray.append(scannedResult)
                    }
                }
            }
            success(mutableArray)
        }else{
            
        }
    }
    
    /// 生成条形码
    static func generateBarcode(_ content: String, size: CGSize) -> UIImage? {
        guard let barcodeFilter = CIFilter(name: "CICode128BarcodeGenerator") else { return nil }
        // 条形码内容
        barcodeFilter.setValue(content.data(using: .utf8), forKey: "inputMessage")
        // 左右间距
        barcodeFilter.setValue(0, forKey: "inputQuietSpace")
        // 高度 -> "inputBarcodeHeight"
        
        guard let outputImage = barcodeFilter.outputImage else { return nil }
        
        // 调整图片大小及位置（小数跳转为整数）位置值向下调整，大小只向上调整
        let extent = outputImage.extent.integral
        
        // 条形码放大 处理模糊
        let scaleX = size.width / extent.width
        let scaleY = size.height / extent.height
        let clearImage = UIImage(ciImage: outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY)))
        
        return clearImage
    }

    /// 往 条形码中插入 文本
    static func insertTextToBarcode(_ text: String?, attributes: [NSAttributedString.Key: Any]?, height: CGFloat, barcodeImage: UIImage) -> UIImage? {
        guard let text = text else { return barcodeImage }
        let barcodeSize = barcodeImage.size
        
        // 开启上下文
        UIGraphicsBeginImageContext(CGSize(width: barcodeSize.width, height: barcodeSize.height + 20))
        
        // 绘制条形码图片
        barcodeImage.draw(in: CGRect(origin: .zero, size: barcodeSize))
        
        // 文本样式
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.black,
            .kern: 2,
            .paragraphStyle: style
        ]
        let attributes = attributes ?? defaultAttributes
        
        // 绘制文本
        (text as NSString).draw(in: CGRect(x: 0, y: barcodeSize.height, width: barcodeSize.width, height: height), withAttributes: attributes)
        // 获取图片
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        // 关闭上下文
        UIGraphicsEndImageContext()
        return outputImage
    }
    
    /// 生成二维码
    static func generateQRCode(_ content: String, size: CGFloat, avatar: UIImage?, foregroundColor: UIColor = .black, backgroundColor: UIColor = .white) -> UIImage? {
        guard let generateFilter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        // 设置二维码内容
        generateFilter.setValue(content.data(using: .utf8), forKey: "inputMessage")
        // 设置二维码的级别(纠错率) L: 7% M(默认): 15% Q: 25% H: 30%
        generateFilter.setValue("H", forKeyPath: "inputCorrectionLevel")
        
        // 直接返回 UIImage(ciImage: outputImage) 会是模糊的二维码
        guard let outputImage = generateFilter.outputImage else { return nil }

        // 转化为 清晰的图像
        guard let clearImage = generateNonInterpolatedQRCode(outputImage, size: size) else { return nil }
        
        // 设置二维码 颜色
        guard let colorsImage = setQRCodeColors(clearImage, foregroundColor: foregroundColor, backgroundColor: backgroundColor) else { return nil}
        
        // 返回插入头像的二维码
        return insertAvatarToQRCode(avatar, qrCodeImage: colorsImage)
        
    }

    /// 生成清晰的 二维码
    static func generateNonInterpolatedQRCode(_ ciImage: CIImage, size: CGFloat) -> UIImage? {
        // 调整图片大小及位置（小数跳转为整数）位置值向下调整，大小只向上调整
        let extent = ciImage.extent.integral
        
        // 获取图片大小
        let scale = min(size / extent.width, size / extent.height)
        let outputImageWidth = extent.width * scale
        let outputImageHeight = extent.height * scale
        
        // 创建依赖于设备的灰度颜色通道
        let space = CGColorSpaceCreateDeviceGray()
        
        // 创建图形上下文
        let bitmapContext = CGContext(data: nil, width: Int(outputImageWidth), height: Int(outputImageHeight), bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: 0)
        
        // 设置缩放
        bitmapContext?.scaleBy(x: scale, y: scale)
        // 设置上下文渲染等级
        bitmapContext?.interpolationQuality = .none
        
        // 上下文
        let context = CIContext(options: nil)
        // 创建 cgImage
        guard let cgImage = context.createCGImage(ciImage, from: extent) else { return nil }
            
        // 绘图
        bitmapContext?.draw(cgImage, in: extent)
        
        // 从图形上下文中创建图片
        guard let scaledImage = bitmapContext?.makeImage() else { return nil }
        
        // 返回UIImage
        return UIImage(cgImage: scaledImage)
        
    }

    /// 设置二维码前景色 和背景色
    static func setQRCodeColors(_ image: UIImage, foregroundColor: UIColor, backgroundColor: UIColor) -> UIImage? {

        guard let colorFilter = CIFilter(name: "CIFalseColor") else { return nil }
        let ciImage = CIImage(image: image)
        
        // 设置图片
        colorFilter.setValue(ciImage, forKey: "inputImage")
        // 设置前景色
        colorFilter.setValue(CIColor(color: foregroundColor), forKey: "inputColor0")
        // 设置背景色
        colorFilter.setValue(CIColor(color: backgroundColor), forKey: "inputColor1")
        
        // 输出图片
        guard let outputImage = colorFilter.outputImage else { return nil }
        
        return UIImage(ciImage: outputImage)
    }

    /// 往 二维码中 插入头像
    static func insertAvatarToQRCode(_ avatar: UIImage?, qrCodeImage: UIImage) -> UIImage? {
        guard let avatarSize = avatar?.size else { return qrCodeImage }
        let qrCodeSize = qrCodeImage.size
        // 开启上下文
        UIGraphicsBeginImageContext(qrCodeSize)
        
        // 设置头像的最大值
        var maxAvatarSize = min(avatarSize.width, avatarSize.height)
        maxAvatarSize = min(qrCodeSize.width / 3, maxAvatarSize)
        
        // 绘制二维码图片
        qrCodeImage.draw(in: CGRect(origin: .zero, size: qrCodeSize))
        // 绘制头像
        avatar?.draw(in: CGRect(x: (qrCodeSize.width - maxAvatarSize) / 2, y: (qrCodeSize.height - maxAvatarSize) / 2, width: maxAvatarSize, height: maxAvatarSize))
        // 获取图片
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        // 关闭上下文
        UIGraphicsEndImageContext()
        return outputImage
    }
}
