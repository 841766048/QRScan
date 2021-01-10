//
//  ScanPermissions.swift
//  GridOperation
//
//

import Foundation
import AVFoundation
import AssetsLibrary
import Photos
import UIKit

class ScanPermissions {
    /// 相机权限
    class func cameraPemission() -> Bool {
        var isHavePemission = true
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authorizationStatus {
        case .authorized:
            //玩家授权
            isHavePemission = true
        case .denied:
            //未授权
            isHavePemission = false
        case .notDetermined:
            //没有询问是否开启麦克风
            break
        case .restricted:
            //未授权，家长限制
            isHavePemission = false
        @unknown default:
            isHavePemission = false
            fatalError()
        }
        return isHavePemission
    }
    /// 请求相机权限
    class func requestCameraPemissionWithResult(completion: @escaping (Bool) -> Void) {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authorizationStatus {
        case .authorized:
            //玩家授权
            completion(true)
        case .denied:
            //未授权
            completion(false)
        case .notDetermined:
            //没有询问是否开启麦克风
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
                DispatchQueue.main.async{
                    if (granted) {
                        completion(true);
                    } else {
                        completion(false);
                    }
                }
            })
        case .restricted:
            //未授权，家长限制
            completion(false)
        @unknown default:
            completion(false)
            fatalError()
        }
    }
    /// 相册是否许可
    class func photoPermission() -> Bool{
        if #available(iOS 8.0, *){
            let author = PHPhotoLibrary.authorizationStatus()
            if author == .denied {
                return false
            }
            return true
        }  else{
            let author = ALAssetsLibrary.authorizationStatus()
            if author == .denied {
                return false
            }
            return true
        }
    }
    
}
