//
//  ScanViewStyle .swift
//  GridOperation
//
//  Created by 张海彬 on 2021/1/6.
//

import Foundation

///扫码区域动画效果枚举
enum RichScanViewAnimationStyle {
    ///线条上下移动
    case LineMove
    /// 网格
	case NetGrid
    /// 线条停止在扫码区域中央
    case LineStill
    /// 无动画
    case None
}


enum RichScanViewPhotoframeAngleStyle {
    /// 内嵌，一般不显示矩形框情况下
    case Inner
    /// 外嵌,包围在矩形框的4个角
    case Outer
    /// 在矩形框的4个角上，覆盖
    case On
}

class ScanViewStyle: NSObject {
    /// 是否需要绘制扫码矩形框，默认YES
    var isNeedShowRetangle = true
    /// 默认扫码区域为正方形，如果扫码区域不是正方形，设置宽高比
    var whRatio = 1.0
    /// 矩形框(视频显示透明区)域向上移动偏移量，0表示扫码透明区域在当前视图中心位置，< 0 表示扫码区域下移, >0 表示扫码区域上移
    var centerUpOffset = 80.0
    /// 矩形框(视频显示透明区)域离界面左边及右边距离，默认60
    var xScanRetangleOffset = 60.0
    /// 矩形框线条颜色
    var colorRetangleLine = UIColor(red: 0.0, green: 167.0/255.0 , blue: 231.0/255.0 , alpha: 1.0)
    /// 扫码区域的4个角类型
    var photoframeAngleStyle:RichScanViewPhotoframeAngleStyle = .On
    /// 4个角的颜色
    var colorAngle = UIColor(red: 0.0, green: 167.0/255.0 , blue: 231.0/255.0 , alpha: 1.0)
    /// 扫码区域4个角的宽度
    var photoframeAngleW = 18.0
    /// 扫码区域的4个角高度
    var photoframeAngleH = 18.0
    /// 扫码区域4个角的线条宽度,默认6，建议8到4之间
    var photoframeLineW = 6.0
    /// 扫码动画效果:线条或网格
    var anmiationStyle:RichScanViewAnimationStyle = .LineMove
 	/// 动画效果的图像，如线条或网格的图像，如果为nil，表示不需要动画效果
    var animationImage = UIImage(named: "sc_qrcode_scan_light_green@2x")
    /// 必须由UIColor创建
    var notRecoginitonArea = UIColor(red: 0.0, green: 0.0 , blue: 0.0 , alpha: 0.5)
}
