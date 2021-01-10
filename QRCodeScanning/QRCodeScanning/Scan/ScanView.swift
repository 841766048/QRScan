//
//  ScanView.swift
//  GridOperation
//
//

import UIKit

class ScanView: UIView {
    /// 扫码区域各种参数
    var viewStyle:ScanViewStyle?
    /// 扫码区域
    var scanRetangleRect:CGRect = CGRect.zero
    /// 线条扫码动画封装
    var scanLineAnimation:ScanLineAnimation?
    /// 网格扫码动画封装
    var scanNetAnimation:ScanNetAnimation?
    /// 线条在中间位置，不移动
    var scanLineStill:UIImageView?
    /// 启动相机时 菊花等待
    var activityView:UIActivityIndicatorView?
    /// 启动相机中的提示文字
    var labelReadying:UILabel?
    
    init(frame:CGRect, style:ScanViewStyle) {
        super.init(frame: frame)
        backgroundColor = .clear
        viewStyle = style
    }

    override func draw(_ rect: CGRect) {
        drawScanRect()
    }
    
    func startDeviceReadyingWith(text:String?) {
        let XRetangleLeft = viewStyle!.xScanRetangleOffset
        
        var sizeRetangle = CGSize(width:frame.width - CGFloat(XRetangleLeft*2), height:frame.width - CGFloat(XRetangleLeft*2))
     
        if !viewStyle!.isNeedShowRetangle {
            let w = sizeRetangle.width
            let h = NSInteger(w / CGFloat(viewStyle!.whRatio))
            
            sizeRetangle = CGSize(width: w, height: CGFloat(h));
        }
        
        //扫码区域Y轴最小坐标
        let YMinRetangle = frame.height / 2.0 - sizeRetangle.height/2.0 - CGFloat(viewStyle!.centerUpOffset);
        if activityView == nil {
            activityView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            
            if let _ = text {
                activityView!.center = CGPoint(x:CGFloat(XRetangleLeft) + CGFloat(sizeRetangle.width/2.0) - 50.0 , y: YMinRetangle + CGFloat(sizeRetangle.height/2.0))
            }else{
                activityView!.center = CGPoint(x:CGFloat(XRetangleLeft) + CGFloat(sizeRetangle.width/2.0), y: YMinRetangle + CGFloat(sizeRetangle.height/2.0))
            }
            activityView!.style = .whiteLarge
            self.addSubview(activityView!)
            
            let labelReadyRect = CGRect(x: activityView!.frame.origin.x + activityView!.frame.size.width + 10, y: activityView!.frame.origin.y, width: 100, height: 30)
            labelReadying = UILabel()
            labelReadying!.backgroundColor = .clear
            labelReadying!.textColor = .white
            labelReadying!.font = .systemFont(ofSize: 18)
            labelReadying!.frame = labelReadyRect
            labelReadying!.text = text
            self.addSubview(labelReadying!)
            
            activityView!.startAnimating()
        }
    }
    
    func stopDeviceReadying() {
        if let _ = activityView {
            activityView!.stopAnimating()
            activityView!.removeFromSuperview()
            labelReadying!.removeFromSuperview()
            
            activityView = nil
            labelReadying = nil
        }
    }
    
    /// 开始扫描动画
    func startScanAnimation() {
        switch viewStyle!.anmiationStyle {
        case .LineMove:
            //线动画
            if scanLineAnimation == nil &&  !scanRetangleRect.equalTo(.zero) {
                scanLineAnimation = ScanLineAnimation()
                scanLineAnimation!.startAnimating(animationRect: scanRetangleRect,
                                                  parentView: self,
                                                  image: viewStyle!.animationImage)
            }
        case .NetGrid:
        	//网格动画
            if scanNetAnimation == nil &&  !scanRetangleRect.equalTo(.zero) {
                scanNetAnimation = ScanNetAnimation()
                scanNetAnimation!.startAnimating(animationRect: scanRetangleRect,
                                                 parentView: self,
                                                 image: viewStyle!.animationImage)
            }
        case .LineStill:
            
            if scanLineStill == nil &&  !scanRetangleRect.equalTo(.zero) {
                let stillRect = CGRect(x:CGFloat(scanRetangleRect.origin.x + 20.0 ),
                                       y:scanRetangleRect.origin.y + scanRetangleRect.size.height/2,
                                       width:scanRetangleRect.size.width - 40,
                                       height:2)
                scanLineStill = UIImageView(frame: stillRect)
                scanLineStill!.image = viewStyle!.animationImage
            }
            self.addSubview(scanLineStill!)
            
        default:
            break
        }
    }
    
    func stopScanAnimation() {
        if let _ = scanLineAnimation {
            scanLineAnimation!.stopLineAnimating()
        }
        
        if let _ = scanNetAnimation {
            scanNetAnimation!.stopLineAnimating()
        }
        
        if let _ = scanLineStill {
            scanLineStill!.removeFromSuperview()
        }
    }
    
    func drawScanRect() {
        if viewStyle == nil {
            return
        }
        let XRetangleLeft = CGFloat(viewStyle!.xScanRetangleOffset)
        let width = frame.width - CGFloat(XRetangleLeft * 2)
        var sizeRetangle = CGSize(width:width, height:width)
        
        if viewStyle!.whRatio != 1 {
            let w = sizeRetangle.width
            let h = NSInteger(w / CGFloat(viewStyle!.whRatio))
            sizeRetangle = CGSize(width: Int(w), height: Int(h))
        }
        //扫码区域Y轴最小坐标
        let YMinRetangle = CGFloat((frame.height / 2.0) ) - CGFloat((sizeRetangle.height/2.0)) - CGFloat(viewStyle!.centerUpOffset)
        let YMaxRetangle = YMinRetangle + sizeRetangle.height
        let XRetangleRight = frame.width - CGFloat(XRetangleLeft)
        
        let context = UIGraphicsGetCurrentContext()
        if context == nil {
            return
        }
        let sc_components = viewStyle!.notRecoginitonArea.cgColor.components
        if sc_components == nil {
            return
        }
        let red_notRecoginitonArea = sc_components![0];
        let green_notRecoginitonArea = sc_components![1];
        let blue_notRecoginitonArea = sc_components![2];
        let alpa_notRecoginitonArea = sc_components![3];
        
        context!.setFillColor(red: red_notRecoginitonArea, green: green_notRecoginitonArea, blue: blue_notRecoginitonArea, alpha: alpa_notRecoginitonArea)
        
        //填充矩形
        var rect = CGRect(x: 0, y: 0, width: frame.width, height: YMinRetangle)
        context!.fill(rect)
        //扫码区域左边填充
        rect = CGRect(x: 0, y: YMinRetangle, width: CGFloat(XRetangleLeft), height: sizeRetangle.height)
        context!.fill(rect)
        
        //扫码区域右边填充
        rect = CGRect(x: XRetangleRight, y: YMinRetangle, width: CGFloat(XRetangleLeft),height: sizeRetangle.height);
        context!.fill(rect)
        
        //扫码区域下面填充
        rect = CGRect(x: 0, y: YMaxRetangle, width: self.frame.size.width,height: self.frame.size.height - YMaxRetangle);
        context!.fill(rect)
        //执行绘画
        context!.strokePath()
        
        if viewStyle!.isNeedShowRetangle {
            context!.setStrokeColor(viewStyle!.colorRetangleLine.cgColor)
            context!.setLineWidth(1)
            context!.addRect(CGRect(x: CGFloat(XRetangleLeft+0.5), y: YMinRetangle+0.5, width: sizeRetangle.width-1, height: sizeRetangle.height-1))
            context!.strokePath()
        }
        
        scanRetangleRect = CGRect(x: CGFloat(XRetangleLeft), y: YMinRetangle, width: sizeRetangle.width, height: sizeRetangle.height)
        //相框角的宽度和高度
        let wAngle = CGFloat(viewStyle!.photoframeAngleW)
        let hAngle = CGFloat(viewStyle!.photoframeAngleH)
        //4个角的 线的宽度
        let linewidthAngle = CGFloat(viewStyle!.photoframeLineW)
        //画扫码矩形以及周边半透明黑色坐标参数
        var diffAngle:CGFloat = 0.0
        
        switch viewStyle!.photoframeAngleStyle {
        case .Outer:
            diffAngle = CGFloat(linewidthAngle / 3.0);//框外面4个角，与框紧密联系在一起
        case .On:
            diffAngle = -0.5
        case .Inner:
            diffAngle = CGFloat(-(viewStyle!.photoframeLineW / 2))
        default:
            diffAngle = CGFloat(linewidthAngle / 3.0);
        }
        context!.setStrokeColor(viewStyle!.colorAngle.cgColor)
        context!.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        context!.setLineWidth(linewidthAngle)
        
        let leftX = XRetangleLeft - diffAngle
        let topY = YMinRetangle - diffAngle
        let rightX = XRetangleRight + diffAngle
        let bottomY = YMaxRetangle + diffAngle
        
        //左上角水平线
        context!.move(to: CGPoint(x: leftX - linewidthAngle/2, y: topY))
        context!.addLine(to: CGPoint(x: leftX + CGFloat(wAngle), y: topY))
        
        //左上角垂直线
        context!.move(to: CGPoint(x: leftX , y: topY - CGFloat(linewidthAngle/2)))
        context!.addLine(to: CGPoint(x: leftX , y: topY + hAngle))
        
        //左下角水平线
        context!.move(to: CGPoint(x: CGFloat(leftX-linewidthAngle/2) , y: bottomY))
        context!.addLine(to: CGPoint(x:  leftX + wAngle , y: bottomY))
        
        //左下角垂直线
        context!.move(to: CGPoint(x: leftX , y: CGFloat(bottomY+linewidthAngle/2)))
        context!.addLine(to: CGPoint(x:  leftX , y: bottomY - hAngle))
        
        //右上角水平线
        context!.move(to: CGPoint(x: CGFloat(rightX+linewidthAngle/2) , y: topY))
        context!.addLine(to: CGPoint(x:  rightX - wAngle , y: topY))
        
        //右上角垂直线
        context!.move(to: CGPoint(x: rightX , y: CGFloat(topY-linewidthAngle/2)))
        context!.addLine(to: CGPoint(x:  rightX  , y: topY + hAngle))
        //右下角水平线
        context!.move(to: CGPoint(x: CGFloat(rightX+linewidthAngle/2) , y: bottomY))
        context!.addLine(to: CGPoint(x: rightX - wAngle  , y: bottomY))
        
        //右下角垂直线
        context!.move(to: CGPoint(x: rightX , y: bottomY+linewidthAngle/2))
        context!.addLine(to: CGPoint(x: rightX , y: bottomY - hAngle))
        
        context!.strokePath()
    }
    
    func getScanRetangleRect() -> CGRect? {
        return scanRetangleRect
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ScanView{
    
    /// 根据矩形区域，获取识别区域
    static func getScanRectWith(preView:UIView ,style:ScanViewStyle) -> CGRect{
        let XRetangleLeft = style.xScanRetangleOffset - 10
        
        var sizeRetangle = CGSize(width: preView.frame.size.width - CGFloat(XRetangleLeft*2),height:preView.frame.size.width - CGFloat(XRetangleLeft*2))
        
        if style.whRatio != 1 {
            let w = sizeRetangle.width;
            let h =  NSInteger(w/CGFloat(style.whRatio))
            sizeRetangle = CGSize(width: w, height: CGFloat(h))
        }
        
         //扫码区域Y轴最小坐标
        let YMinRetangle = CGFloat(preView.frame.size.height / 2.0) - CGFloat(sizeRetangle.height/2.0) - CGFloat(style.centerUpOffset)
        
        //扫码区域坐标
        let cropRect =  CGRect(x:CGFloat(XRetangleLeft), y:YMinRetangle, width:sizeRetangle.width, height:sizeRetangle.height)
        
        var rectOfInterest:CGRect
        
        let size = preView.bounds.size;
        let p1 = size.height/size.width;
        let p2 = 1920.0/1080.0;  //使用了1080p的图像输出
        
        if Double(p1) < p2 {
            let fixHeight = size.width * 1920.0 / 1080.0
            let fixPadding = (fixHeight - size.height)/2;
            rectOfInterest = CGRect(x:(cropRect.origin.y + fixPadding)/fixHeight,
                                    y:cropRect.origin.x/size.width,
                                    width:cropRect.size.height/fixHeight,
                                    height:cropRect.size.width/size.width);
            
        }else{
            let fixWidth = size.height * 1080.0 / 1920.0
            let fixPadding = (fixWidth - size.width)/2
            rectOfInterest = CGRect(x:cropRect.origin.y/size.height,
                                    y:(cropRect.origin.x + fixPadding)/fixWidth,
                                    width:cropRect.size.height/size.height,
                                    height:cropRect.size.width/fixWidth)
        }
        
        return rectOfInterest
    }
    
    // 根据矩形区域，获取识别区域
    static func getZXingScanRectWith(preView:UIView ,style:ScanViewStyle)-> CGRect{
        var XRetangleLeft = style.xScanRetangleOffset

        var sizeRetangle = CGSize(width: preView.frame.size.width - CGFloat( XRetangleLeft*2.0), height: preView.frame.size.width - CGFloat(XRetangleLeft*2))
        
        if style.whRatio != 1 {
            let w = sizeRetangle.width;
            let h =  NSInteger(w/CGFloat(style.whRatio))
            sizeRetangle = CGSize(width: w, height: CGFloat(h))
        }
        
        var YMinRetangle = preView.frame.size.height / 2.0 - sizeRetangle.height/2.0 - CGFloat(style.centerUpOffset)
        
        XRetangleLeft = Double(CGFloat(XRetangleLeft) / preView.frame.size.width * 1080.0);
        YMinRetangle =  CGFloat(YMinRetangle) / preView.frame.size.height * 1920.0;
        let width  = sizeRetangle.width / preView.frame.size.width * 1080.0;
        let height = sizeRetangle.height / preView.frame.size.height * 1920.0;
        
        //扫码区域坐标
        let cropRect =  CGRect(x:CGFloat(XRetangleLeft), y:YMinRetangle, width:width,height:height);
        return cropRect;
    }
}
