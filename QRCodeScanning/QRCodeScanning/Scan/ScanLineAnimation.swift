//
//  ScanLineAnimation.swift
//  GridOperation
//
//  Created by 张海彬 on 2021/1/6.
//

import Foundation

class ScanLineAnimation: UIImageView {
    var num:Int32 = 0
    var down = false
    var timer:Timer?
    var isAnimationing = false
    var animationRect:CGRect?
    
    @objc private func stepAnimation() {
        if !isAnimationing {
            return
        }
        
        let leftx = animationRect!.origin.x  + 5
        
        let width = animationRect!.size.width - 10
        
        self.frame = CGRect(x: leftx, y: animationRect!.origin.y, width: width, height: 8)
        
        self.alpha = 0.0
        
        self.isHidden = false
        
        UIView.animate(withDuration: 0.5, animations: {[weak self] in
            self?.alpha = 1.0
        })
        
        UIView.animate(withDuration: 3, animations: { [unowned self] in
            let leftx = self.animationRect!.origin.x  + 5
            let width = self.animationRect!.size.width - 10
            let y = self.animationRect!.origin.y + self.animationRect!.size.height - 8
            self.frame = CGRect(x: leftx, y: y , width: width, height: 4)
            
        }, completion: { [weak self]  (finished) in
            self?.isHidden = true
            //延迟5秒执行
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                self?.stepAnimation()
            }
//            self.perform(#selector(stepAnimation), with: nil, afterDelay: 0.3)
        })
    }
    
    private func startAnimating_UIViewAnimation() {
        stepAnimation()
    }
    
    func startAnimating(animationRect:CGRect , parentView:UIView ,image:UIImage?) {
        if isAnimationing {
            return
        }
        
        isAnimationing = true
        
        self.animationRect = animationRect
        down = true
        num = 0
        
        let centery = animationRect.minY + animationRect.height/2
        
        let leftx = animationRect.origin.x + 5;
        
        let width = animationRect.size.width - 10;
        
        let y = centery + CGFloat((2 * num))
        
        self.frame = CGRect(x: leftx, y:y , width: width, height: 2)
        
        self.image = image
        
        parentView.addSubview(self)
        
        startAnimating_UIViewAnimation()
    }
    
    private func startAnimating_NSTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(scanLineAnimation), userInfo: nil, repeats: true)
    }
    
    @objc private func scanLineAnimation() {
        let centery = animationRect!.minY + animationRect!.height/2
        let leftx = animationRect!.origin.x + 5;
        let width = animationRect!.size.width - 10;
        
        if down {
            num += 1
            let y = centery + CGFloat((2 * num))
            self.frame = CGRect(x: leftx, y:y , width: width, height: 2)
            
            if y > (animationRect!.minY + animationRect!.height - 5) {
                down = false
            }
        }else{
            num -= 1
            let y = centery + CGFloat((2 * num))
            self.frame = CGRect(x: leftx, y:y , width: width, height: 2)
            if y < (animationRect!.minY + 5) {
                down = true
            }
        }
    }
    
    func stopLineAnimating() {
        if isAnimationing {
            isAnimationing = false
            if let _ = self.timer {
                self.timer!.invalidate()
                self.timer = nil
            }
            self.removeFromSuperview()
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    deinit {
        stopLineAnimating()
    }
}
