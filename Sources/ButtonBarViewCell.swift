//  ButtonBarViewCell.swift
//  XLPagerTabStrip ( https://github.com/xmartlabs/XLPagerTabStrip )
//
//  Copyright (c) 2016 Xmartlabs ( http://xmartlabs.com )
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

@IBDesignable
open class ButtonBarViewCell : UICollectionViewCell
{
    @IBOutlet open var imageView: UIImageView!
    @IBOutlet open lazy var label: UILabel! = { [unowned self] in
        let label = UILabel(frame: self.contentView.bounds)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 14.0)
        return label
    }()
    
    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        if label.superview != nil {
            contentView.addSubview(label)
        }
    }
    
    @IBInspectable public var maskEnabled: Bool = true {
        didSet {
            mkLayer.maskEnabled = maskEnabled
        }
    }
    @IBInspectable public var elevation: CGFloat = 0 {
        didSet {
            mkLayer.elevation = elevation
        }
    }
    @IBInspectable public var shadowOffset: CGSize = CGSize.zero {
        didSet {
            mkLayer.shadowOffset = shadowOffset
        }
    }
    @IBInspectable public var roundingCorners: UIRectCorner = UIRectCorner.allCorners {
        didSet {
            mkLayer.roundingCorners = roundingCorners
        }
    }
    @IBInspectable public var rippleEnabled: Bool = true {
        didSet {
            mkLayer.rippleEnabled = rippleEnabled
        }
    }
    @IBInspectable public var rippleDuration: CFTimeInterval = 0.35 {
        didSet {
            mkLayer.rippleDuration = rippleDuration
        }
    }
    @IBInspectable public var rippleScaleRatio: CGFloat = 1.0 {
        didSet {
            mkLayer.rippleScaleRatio = rippleScaleRatio
        }
    }
    @IBInspectable public var rippleLayerColor: UIColor = UIColor(hexString: "EEEEEEFF") {
        didSet {
            mkLayer.setRippleColor(color: rippleLayerColor)
        }
    }
    @IBInspectable public var backgroundAnimationEnabled: Bool = true {
        didSet {
            mkLayer.backgroundAnimationEnabled = backgroundAnimationEnabled
        }
    }
    
    override open var bounds: CGRect {
        didSet {
            mkLayer.superLayerDidResize()
        }
    }
    
    private lazy var mkLayer: MKLayer = MKLayer(withView: self)
    
    // MARK: Init
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayer()
    }
    
    // MARK: Setup
    private func setupLayer() {
        mkLayer = MKLayer(withView: self)
        mkLayer.elevation = self.elevation
        mkLayer.elevationOffset = self.shadowOffset
        mkLayer.roundingCorners = self.roundingCorners
        mkLayer.maskEnabled = self.maskEnabled
        mkLayer.rippleScaleRatio = self.rippleScaleRatio
        mkLayer.rippleDuration = self.rippleDuration
        mkLayer.rippleEnabled = self.rippleEnabled
        mkLayer.backgroundAnimationEnabled = self.backgroundAnimationEnabled
        mkLayer.setRippleColor(color: self.rippleLayerColor)
    }
    
    // MARK: Touch
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        mkLayer.touchesBegan(touches: touches, withEvent: event)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        mkLayer.touchesEnded(touches: touches, withEvent: event)
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        super.touchesCancelled(touches!, with: event)
        mkLayer.touchesCancelled(touches: touches, withEvent: event)
    }
    
    open override func touchesMoved(_
        touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        mkLayer.touchesMoved(touches: touches, withEvent: event)
    }
}

//
//  MKLayer.swift
//  MaterialKit
//
//  Created by Le Van Nghia on 11/15/14.
//  Copyright (c) 2014 Le Van Nghia. All rights reserved.
//

import UIKit

let kMKClearEffectsDuration = 0.3

public class MKLayer: CALayer, CALayerDelegate, CAAnimationDelegate {
    
    public var maskEnabled: Bool = true {
        didSet {
            self.mask = maskEnabled ? maskLayer : nil
        }
    }
    public var rippleEnabled: Bool = true
    public var rippleScaleRatio: CGFloat = 1.0 {
        didSet {
            self.calculateRippleSize()
        }
    }
    public var rippleDuration: CFTimeInterval = 0.35
    public var elevation: CGFloat = 0 {
        didSet {
            self.enableElevation()
        }
    }
    public var elevationOffset: CGSize = CGSize.zero {
        didSet {
            self.enableElevation()
        }
    }
    public var roundingCorners: UIRectCorner = UIRectCorner.allCorners {
        didSet {
            self.enableElevation()
        }
    }
    public var backgroundAnimationEnabled: Bool = true
    
    private var superView: UIView?
    private var superLayer: CALayer?
    private var rippleLayer: CAShapeLayer?
    private var backgroundLayer: CAShapeLayer?
    private var maskLayer: CAShapeLayer?
    private var userIsHolding: Bool = false
    private var effectIsRunning: Bool = false
    
    private override init(layer: Any) {
        super.init()
    }
    
    public init(superLayer: CALayer) {
        super.init()
        self.superLayer = superLayer
        setup()
    }
    
    public init(withView view: UIView) {
        super.init()
        self.superView = view
        self.superLayer = view.layer
        self.setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.superLayer = self.superlayer
        self.setup()
    }
    
    @objc
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath {
            if keyPath == "bounds" {
                self.superLayerDidResize()
            } else if keyPath == "cornerRadius" {
                if let superLayer = superLayer {
                    setMaskLayerCornerRadius(radius: superLayer.cornerRadius)
                }
            }
        }
    }
    
    public func superLayerDidResize() {
        if let superLayer = self.superLayer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.frame = superLayer.bounds
            self.setMaskLayerCornerRadius(radius: superLayer.cornerRadius)
            self.calculateRippleSize()
            CATransaction.commit()
        }
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if anim == self.animation(forKey: "opacityAnim") {
            self.opacity = 0
        } else if flag {
            if userIsHolding {
                effectIsRunning = false
            } else {
                self.clearEffects()
            }
        }
    }
    
    public func startEffects(atLocation touchLocation: CGPoint) {
        userIsHolding = true
        if let rippleLayer = self.rippleLayer {
            rippleLayer.timeOffset = 0
            rippleLayer.speed = backgroundAnimationEnabled ? 1 : 1.1
            if rippleEnabled {
                startRippleEffect(touchLocation: nearestInnerPoint(point: touchLocation))
            }
        }
    }
    
    public func stopEffects() {
        userIsHolding = false
        if !effectIsRunning {
            self.clearEffects()
        } else if let rippleLayer = rippleLayer {
            rippleLayer.timeOffset = rippleLayer.convertTime(CACurrentMediaTime(), from: nil)
            rippleLayer.beginTime = CACurrentMediaTime()
            rippleLayer.speed = 1.2
        }
    }
    
    public func stopEffectsImmediately() {
        userIsHolding = false
        effectIsRunning = false
        if rippleEnabled {
            if let rippleLayer = self.rippleLayer,
                let backgroundLayer = self.backgroundLayer {
                rippleLayer.removeAllAnimations()
                backgroundLayer.removeAllAnimations()
                rippleLayer.opacity = 0
                backgroundLayer.opacity = 0
            }
        }
    }
    
    public func setRippleColor(color: UIColor,
                               withRippleAlpha rippleAlpha: CGFloat = 0.3,
                               withBackgroundAlpha backgroundAlpha: CGFloat = 0.3) {
        if let rippleLayer = self.rippleLayer,
            let backgroundLayer = self.backgroundLayer {
            rippleLayer.fillColor = color.withAlphaComponent(rippleAlpha).cgColor
            backgroundLayer.fillColor = color.withAlphaComponent(backgroundAlpha).cgColor
        }
    }
    
    // MARK: Touches
    
    public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let first = touches.first, let superView = self.superView {
            let point = first.location(in: superView)
            startEffects(atLocation: point)
        }
    }
    
    public func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.stopEffects()
    }
    
    public func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        self.stopEffects()
    }
    
    public func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    }
    
    // MARK: Private
    
    private func setup() {
        rippleLayer = CAShapeLayer()
        rippleLayer!.opacity = 0
        self.addSublayer(rippleLayer!)
        
        backgroundLayer = CAShapeLayer()
        backgroundLayer!.opacity = 0
        backgroundLayer!.frame = superLayer!.bounds
        self.addSublayer(backgroundLayer!)
        
        maskLayer = CAShapeLayer()
        self.setMaskLayerCornerRadius(radius: superLayer!.cornerRadius)
        self.mask = maskLayer
        
        self.frame = superLayer!.bounds
        superLayer!.addSublayer(self)
        superLayer!.addObserver(
            self,
            forKeyPath: "bounds",
            options: NSKeyValueObservingOptions(rawValue: 0),
            context: nil)
        superLayer!.addObserver(
            self,
            forKeyPath: "cornerRadius",
            options: NSKeyValueObservingOptions(rawValue: 0),
            context: nil)
        
        self.enableElevation()
        self.superLayerDidResize()
    }
    
    private func setMaskLayerCornerRadius(radius: CGFloat) {
        if let maskLayer = self.maskLayer {
            maskLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: radius).cgPath
        }
    }
    
    private func nearestInnerPoint(point: CGPoint) -> CGPoint {
        let centerX = self.bounds.midX
        let centerY = self.bounds.midY
        let dx = point.x - centerX
        let dy = point.y - centerY
        let dist = sqrt(dx * dx + dy * dy)
        if let backgroundLayer = self.rippleLayer { // TODO: Fix it
            if dist <= backgroundLayer.bounds.size.width / 2 {
                return point
            }
            let d = backgroundLayer.bounds.size.width / 2 / dist
            let x = centerX + d * (point.x - centerX)
            let y = centerY + d * (point.y - centerY)
            return CGPoint(x: x, y: y)
        }
        return CGPoint.zero
    }
    
    private func clearEffects() {
        if let rippleLayer = self.rippleLayer,
            let backgroundLayer = self.backgroundLayer {
            rippleLayer.timeOffset = 0
            rippleLayer.speed = 1
            
            if rippleEnabled {
                rippleLayer.removeAllAnimations()
                backgroundLayer.removeAllAnimations()
                self.removeAllAnimations()
                
                let opacityAnim = CABasicAnimation(keyPath: "opacity")
                opacityAnim.fromValue = 1
                opacityAnim.toValue = 0
                opacityAnim.duration = kMKClearEffectsDuration
                opacityAnim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                opacityAnim.isRemovedOnCompletion = false
                opacityAnim.fillMode = kCAFillModeForwards
                opacityAnim.delegate = self
                
                self.add(opacityAnim, forKey: "opacityAnim")
            }
        }
    }
    
    private func startRippleEffect(touchLocation: CGPoint) {
        self.removeAllAnimations()
        self.opacity = 1
        if let rippleLayer = self.rippleLayer,
            let backgroundLayer = self.backgroundLayer,
            let superLayer = self.superLayer {
            rippleLayer.removeAllAnimations()
            backgroundLayer.removeAllAnimations()
            
            let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
            scaleAnim.fromValue = 0
            scaleAnim.toValue = 1
            scaleAnim.duration = rippleDuration
            scaleAnim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            scaleAnim.delegate = self
            
            let moveAnim = CABasicAnimation(keyPath: "position")
            moveAnim.fromValue = NSValue(cgPoint: touchLocation)
            moveAnim.toValue = NSValue(cgPoint: CGPoint(
                x: superLayer.bounds.midX,
                y: superLayer.bounds.midY))
            moveAnim.duration = rippleDuration
            moveAnim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            
            effectIsRunning = true
            rippleLayer.opacity = 1
            if backgroundAnimationEnabled {
                backgroundLayer.opacity = 1
            } else {
                backgroundLayer.opacity = 0
            }
            
            rippleLayer.add(moveAnim, forKey: "position")
            rippleLayer.add(scaleAnim, forKey: "scale")
        }
    }
    
    private func calculateRippleSize() {
        if let superLayer = self.superLayer {
            let superLayerWidth = superLayer.bounds.width
            let superLayerHeight = superLayer.bounds.height
            let center = CGPoint(
                x: superLayer.bounds.midX,
                y: superLayer.bounds.midY)
            let circleDiameter =
                sqrt(
                    powf(Float(superLayerWidth), 2)
                        +
                        powf(Float(superLayerHeight), 2)) * Float(rippleScaleRatio)
            let subX = center.x - CGFloat(circleDiameter) / 2
            let subY = center.y - CGFloat(circleDiameter) / 2
            
            if let rippleLayer = self.rippleLayer {
                rippleLayer.frame = CGRect(
                    x: subX, y: subY,
                    width: CGFloat(circleDiameter), height: CGFloat(circleDiameter))
                rippleLayer.path = UIBezierPath(ovalIn: rippleLayer.bounds).cgPath
                
                if let backgroundLayer = self.backgroundLayer {
                    backgroundLayer.frame = rippleLayer.frame
                    backgroundLayer.path = rippleLayer.path
                }
            }
        }
    }
    
    private func enableElevation() {
        if let superLayer = self.superLayer {
            superLayer.shadowOpacity = 0.5
            superLayer.shadowRadius = elevation / 4
            superLayer.shadowColor = UIColor.black.cgColor
            superLayer.shadowOffset = elevationOffset
        }
    }
}

extension UIColor {
    public convenience init(hexString: String) {
        let r, g, b, a: CGFloat
        if hexString.hasPrefix("#") {
            let start = hexString.index(hexString.startIndex, offsetBy: 1)
            let hexColor = hexString.substring(from: start)
            if hexColor.characters.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        self.init(red: 0, green: 0, blue: 0, alpha: 0)
    }
}
