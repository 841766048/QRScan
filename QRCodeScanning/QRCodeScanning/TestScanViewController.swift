//
//  TestScanViewController.swift
//  QRCodeScanning
//
//

import UIKit

class TestScanViewController: UIViewController {
    /// 底部显示的功能项
    var bottomItemsView:UIView?
    /// 相册
    var btnPhoto:UIButton = UIButton()
    /// 闪光灯
    var btnFlash:UIButton = UIButton()
    /// 我的二维码
    var btnMyQR:UIButton = UIButton()
    
    var manage:ScanManage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "扫一扫"
        
        axcBaseAddLeftBtnWithImage(imageName: "navigation_back_normal")
        /// 意思是让 View 的所有边都紧贴在容器内部
        edgesForExtendedLayout = .all
        view.backgroundColor = .black
       
        manage = ScanManage(addView:view, blockScanResult: { (result) in
            print("结果：",result)
        })
        
        drawBottomItems()
        
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
        manage!.startScan()
        manage!.stopDeviceReadying()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        manage!.requestCameraPemissionWithResult()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        manage!.stopScan()
        navigationController?.navigationBar.isHidden = true
    }
    deinit {
        print("当前页面销毁")
    }
    

    func drawBottomItems() {
        if let _ =  bottomItemsView {
            return
        }
        
        bottomItemsView = UIView(frame: CGRect(x: 0, y: view.frame.maxY - 164, width: view.frame.width, height: 100))
        bottomItemsView!.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        view.addSubview(bottomItemsView!)
        
        let size = CGSize(width:65, height:87)
        
        btnFlash.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        btnFlash.center = CGPoint(x: bottomItemsView!.frame.width * (3/4), y: bottomItemsView!.frame.height/2)
        btnFlash.setImage(UIImage(named: "qrcode_scan_btn_flash_nor"), for: .normal)
        btnFlash.setImage(UIImage(named: "qrcode_scan_btn_flash_down"), for: .selected)
        btnFlash.addTarget(self, action: #selector(openOrCloseFlash), for: .touchUpInside)
        bottomItemsView?.addSubview(btnFlash)
        
        btnPhoto.bounds = btnFlash.bounds
        btnPhoto.center = CGPoint(x: bottomItemsView!.frame.width/4, y: bottomItemsView!.frame.height/2)
        btnPhoto.setImage(UIImage(named: "qrcode_scan_btn_photo_nor"), for: .normal)
        btnPhoto.setImage(UIImage(named: "qrcode_scan_btn_photo_down"), for: .selected)
        btnPhoto.addTarget(self, action: #selector(openPhoto), for: .touchUpInside)
        bottomItemsView?.addSubview(btnPhoto)
        
    }
    
    /// 开关闪光灯
    @objc func openOrCloseFlash() {
        btnFlash.isSelected = !btnFlash.isSelected
        manage!.setTorch(torch:  btnFlash.isSelected)
    }
    
    /// 打开相册
    @objc func openPhoto() {
        manage!.openPhoto()
    }

}
extension TestScanViewController{
    func axcBaseAddLeftBtnWithImage(imageName:String) {
        let baseRightImageButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 40))
        baseRightImageButton.setImage(UIImage(named: imageName), for: .normal)
        baseRightImageButton.imageView?.contentMode = .scaleAspectFit
        baseRightImageButton.addTarget(self, action: #selector(axcBaseClickBaseLeftImageBtn), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: baseRightImageButton)
    }
    
    @objc func axcBaseClickBaseLeftImageBtn() {
        navigationController?.popViewController(animated: true)
    }
}
