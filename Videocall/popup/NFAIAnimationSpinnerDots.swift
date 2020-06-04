//
//  NFAIAnimationSpinnerDots.swift
//  NFClient
//
//  Created by NhatNguyen on 5/26/20.
//  Copyright © 2020 PeerClient. All rights reserved.
//

import Foundation
import UIKit

class NFAIAnimationSpinnerDots {

    func setUpAnimation(uv: UIView, color: UIColor) {
        let circleSize = 13
        
        if let viewWithTag = uv.viewWithTag(2000) {
            viewWithTag.removeFromSuperview()
        }
        
        for i in 0 ..< 5 {
            let factor = Float(i) * 1 / 5
            let circle = layerWith(size: CGSize(width: circleSize, height: circleSize), color: color)
            let animation = rotateAnimation(factor, x: uv.bounds.size.width / 2, y: uv.bounds.size.height / 2, size: CGSize(width: 40, height: 40))

            circle.frame = CGRect(x: 0, y: 0, width: circleSize, height: circleSize)
            circle.add(animation, forKey: "animation")
            let viewLoading: UIView = UIView()
            viewLoading.frame = uv.bounds
            viewLoading.tag = 2000
            uv.layer.insertSublayer(circle, at: 5)
        }
    }

    func rotateAnimation(_ rate: Float, x: CGFloat, y: CGFloat, size: CGSize) -> CAAnimationGroup {
        let duration: CFTimeInterval = 2
        let fromScale = 0.6 - rate
        let toScale = 0.2 + rate
        let timeFunc = CAMediaTimingFunction(controlPoints: 0.5, 0.15 + rate, 0.5, 1)

        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.duration = duration
        scaleAnimation.repeatCount = HUGE
        scaleAnimation.fromValue = fromScale
        scaleAnimation.toValue = toScale

        let positionAnimation = CAKeyframeAnimation(keyPath: "position")
        positionAnimation.duration = duration
        positionAnimation.repeatCount = HUGE
        positionAnimation.path = UIBezierPath(arcCenter: CGPoint(x: x, y: y), radius: size.width / 2, startAngle: CGFloat(3 * Double.pi * 0.5), endAngle: CGFloat(3 * Double.pi * 0.5 + 2 * Double.pi), clockwise: true).cgPath

        let animation = CAAnimationGroup()
        animation.animations = [scaleAnimation, positionAnimation]
        animation.timingFunction = timeFunc
        animation.duration = duration
        animation.repeatCount = HUGE
        animation.isRemovedOnCompletion = false

        return animation
    }
    
    func layerWith(size: CGSize, color: UIColor) -> CALayer {
        let layer: CAShapeLayer = CAShapeLayer()
        let path: UIBezierPath = UIBezierPath()

        path.addArc(withCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                   radius: size.width / 2,
                   startAngle: 0,
                   endAngle: CGFloat(2 * Double.pi),
                   clockwise: false)
        layer.fillColor = color.cgColor

        layer.backgroundColor = nil
        layer.path = path.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        return layer
    }
}
