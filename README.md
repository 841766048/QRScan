
# QRScan
扫一扫实现，集成简单，自动放大
### 快速上手

| Key | 模块 | 备注 |
| ----- | ----  | ---- |
| NSPhotoLibraryUsageDescription | Picker | 允许访问相册 |
| NSPhotoLibraryAddUsageDescription | Picker | 允许保存图片至相册 |
| PHPhotoLibraryPreventAutomaticLimitedAccessAlert | Picker | 设置为 `YES` iOS 14+ 以禁用自动弹出添加更多照片的弹框(Picker 已适配 Limited 功能，可由用户主动触发，提升用户体验)|
| NSCameraUsageDescription | Capture | 允许使用相机 |
| NSMicrophoneUsageDescription | Capture | 允许使用麦克风 |


```swift
// 在头文件里添加权限判断的OC文件
#import "LBXPermission.h"
在你需要布局的文件里声明全局一个变量
var manage:ScanManage?

在你viewDidLoad方法中执行初始化方法
注意：一定要先初始化，在进行其他的布局

override func viewDidLoad() {
    super.viewDidLoad()
    self.title = "扫一扫"
    
    axcBaseAddLeftBtnWithImage(imageName: "navigation_back_normal")
    /// 意思是让 View 的所有边都紧贴在容器内部
    edgesForExtendedLayout = .all
    view.backgroundColor = .black
   // 扫一扫的界面
    manage = ScanManage(addView:view, blockScanResult: { (result) in
        print("结果：",result)
    })
    
    drawBottomItems() // 自己的布局
    
}
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.navigationBar.isHidden = false
    //开关闪光灯
    if manage!.getFlashMode() {
        btnFlash.isSelected = true
    }else{
        btnFlash.isSelected = false
    }
    manage!.startScan()// 启动设备
    manage!.stopDeviceReadying() // 停止设备准备
}

override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    manage!.requestCameraPemissionWithResult()// 请求使用相机
}

override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    manage!.stopScan() // 离开页面时调用停止相机的使用
    navigationController?.navigationBar.isHidden = true
}

```
