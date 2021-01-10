//
//  ScanNetAnimation.swift
//  GridOperation
//
//

import UIKit

class ScanNetAnimation: UIView {
    var isAnimationing = false
    
    var animationRect:CGRect?
    
    var scanImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        animationRect = frame
        self.clipsToBounds = true
        self.addSubview(scanImageView)
    }
    
    @objc private func stepAnimation() {
        if !isAnimationing {
            return
        }
        self.frame = animationRect!;
        let scanNetImageViewW = self.frame.size.width
        let scanNetImageH = self.frame.size.height
        self.alpha = 0.5;
        scanImageView.frame = CGRect(x: 0, y: scanNetImageViewW - scanNetImageH , width: scanNetImageViewW, height: scanNetImageH)
        UIView.animate(withDuration: 1.4, animations: { [unowned self] in
            self.alpha = 1.0
            self.scanImageView.frame = CGRect(x: 0, y: scanNetImageViewW-scanNetImageH, width: scanNetImageViewW, height: scanNetImageH)
        } , completion: {[unowned self] (finished) in
            self.perform(#selector(stepAnimation), with: nil, afterDelay: 0.3)
        })
    }
    
    func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        self.perform(#selector(stepAnimation), with: nil, afterDelay: 0.3)
    }
    
    func startAnimating(animationRect:CGRect , parentView:UIView ,image:UIImage?) {
        scanImageView.image = image
        self.animationRect =  animationRect
        parentView.addSubview(self)
        
        self.isHidden = false
        isAnimationing = true
        stepAnimation()
    }
    
    deinit {
        stopLineAnimating()
    }
    
    func stopLineAnimating() {
        self.isHidden = true
        isAnimationing = false
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
