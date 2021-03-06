//
//  AlertTransition.swift
//  RMAlertControllerExample
//
//  Created by Daniel Langh on 26/02/16.
//  Copyright © 2016 rumori. All rights reserved.
//

import UIKit

public class RMAlertTransition: NSObject, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
    
    public var showDuration: TimeInterval = 0.5
    public var hideDuration: TimeInterval = 0.3
    
    public var backgroundAlpha: CGFloat = 0.4
    public var springDamping: CGFloat = 0.7
    public var dismissEnabledWithBackgroundTap: Bool = false
    public var backgroundFadeDurationPercent: Double = 0.4
    
    public var minimumWidth: CGFloat = 250.0
    public var maximumWidth: CGFloat = 350.0
    public var centerVertically: Bool = true
    
    public var horizontalPadding: CGFloat = 20.0
    public var verticalPadding: CGFloat = 20.0

    fileprivate var fadeView: UIView?
    fileprivate var contentView: UIView?

    fileprivate var isDismissing: Bool = false
    
    fileprivate weak var presentedViewController: UIViewController?
    fileprivate weak var presentingViewController: UIViewController?
    fileprivate weak var containerView: UIView?
    
    fileprivate var centerYConstraint: NSLayoutConstraint?
    fileprivate var bottomConstraint: NSLayoutConstraint?
    fileprivate var centerYConstant: CGFloat = 0.0
    fileprivate var bottomConstant: CGFloat = 0.0
    
    // MARK: -
    
    override public init() {
        super.init()
        self.addObservers()
        self.bottomConstant = verticalPadding
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: -
    
    @objc func keyboardWillShow(_ notification:Notification) {
        
        if let endFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            let height = endFrame.height
            centerYConstant = -height / 2.0
            bottomConstant = height + verticalPadding
            
            if let
                centerYConstraint = self.centerYConstraint,
                let bottomConstraint = self.bottomConstraint {
                    
                centerYConstraint.constant = centerYConstant
                bottomConstraint.constant = bottomConstant
                UIView.animate(withDuration: 0.33, animations: { () -> Void in
                    self.containerView?.layoutIfNeeded()
                })
            }
        }
    }

    @objc func keyboardWillHide(_ notification:Notification) {

        centerYConstant = 0.0
        bottomConstant = verticalPadding

        if
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
        let centerYConstraint = self.centerYConstraint,
        let bottomConstraint = self.bottomConstraint {

            bottomConstraint.constant = bottomConstant
            centerYConstraint.constant = centerYConstant
                
            UIView.animate(withDuration: duration,
                delay: 0,
                options: UIView.AnimationOptions(rawValue: curve),
                animations: {
                    self.containerView?.layoutIfNeeded()
                },
                completion:nil)
        }
    }

    
    // MARK: -
    
    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.isDismissing = false
        self.presentedViewController = presented
        self.presentingViewController = presenting
        return self
    }
    
    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.isDismissing = true
        self.presentedViewController = nil
        self.presentingViewController = nil
        return self
    }
    
    // MARK:
    
    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.isDismissing ? hideDuration : showDuration
    }
    
    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let containerView = transitionContext.containerView
        
        self.containerView = containerView
        
        if isDismissing {
            
            if let contentView = self.contentView {
                
                let duration = self.transitionDuration(using: transitionContext)

                UIView.animate(withDuration: duration,
                    delay:0.0,
                    options: UIView.AnimationOptions.curveEaseIn,
                    animations: { () -> Void in
                        
                        contentView.transform = CGAffineTransform(translationX: 0, y: containerView.bounds.height/2.0 + contentView.bounds.height/2.0)
                    }, completion: { (finished) -> Void in
                        transitionContext.completeTransition(finished)
                })

                // animate fadeview
            
                let fadeView = self.fadeView
                let fadeDuration = self.transitionDuration(using: transitionContext) * backgroundFadeDurationPercent
                let fadeDelay = duration - fadeDuration
                UIView.animate(
                    withDuration: fadeDuration,
                    delay: fadeDelay,
                    options: UIView.AnimationOptions.curveLinear,
                    animations: { () -> Void in
                        fadeView?.alpha = 0.0
                    },
                    completion: nil)
                
                // animate tintcolors
                
                if let window = containerView.window {
                    UIView.animate(
                        withDuration: fadeDuration,
                        animations: { () -> Void in
                            window.tintAdjustmentMode = .normal
                        })
                }
            }
        
        } else {
            
            if
                let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) {
                    
                    // Create fadeview
                    
                    let fadeView = UIView(frame: containerView.bounds)
                    fadeView.backgroundColor = UIColor(white: 0.0, alpha: backgroundAlpha)
                    if dismissEnabledWithBackgroundTap {
                        fadeView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:))))
                    }
                    fadeView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    containerView.addSubview(fadeView)
                    self.fadeView = fadeView
                    
                    // Create contentview
                    
                    let contentView = UIView()
                    contentView.layer.cornerRadius = 10.0
                    contentView.clipsToBounds = true


                    // Add toview to contentview
                    
                    toView.translatesAutoresizingMaskIntoConstraints = false
                    contentView.addSubview(toView)
                    contentView.addConstraints([
                        NSLayoutConstraint(item: toView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: 0.0),
                        NSLayoutConstraint(item: toView, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: 0.0),
                        NSLayoutConstraint(item: toView, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1.0, constant: 0.0),
                        NSLayoutConstraint(item: toView, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1.0, constant: 0.0)
                        ])

                    
                    // Add contentview to container
                    
                    contentView.translatesAutoresizingMaskIntoConstraints = false
                    containerView.addSubview(contentView)
                
                    let bottomConstraint = NSLayoutConstraint(item: contentView, attribute: .bottom, relatedBy: .lessThanOrEqual, toItem: containerView, attribute: .bottom, multiplier: 1.0, constant: self.bottomConstant)
                    let minimumWidthConstraint = NSLayoutConstraint(item: contentView, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: self.minimumWidth)
                    let maximumWidthConstraint = NSLayoutConstraint(item: contentView, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: self.maximumWidth)
                    let centerXConstraint = NSLayoutConstraint(item: contentView, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1.0, constant: 0.0)
                    let leadingConstraint = NSLayoutConstraint(item: contentView, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: containerView, attribute: .leading, multiplier: 1.0, constant: horizontalPadding)
                    let trailingConstraint = NSLayoutConstraint(item: contentView, attribute: .trailing, relatedBy: .lessThanOrEqual, toItem: containerView, attribute: .trailing, multiplier: 1.0, constant: -horizontalPadding)
                    if centerVertically {
                        let topConstraint = NSLayoutConstraint(item: contentView, attribute: .top, relatedBy: .greaterThanOrEqual, toItem: containerView, attribute: .top, multiplier: 1.0, constant: self.verticalPadding)
                        let centerYConstraint = NSLayoutConstraint(item: contentView, attribute: .centerY, relatedBy: .equal, toItem: containerView, attribute: .centerY, multiplier: 1.0, constant: self.centerYConstant)
                        centerYConstraint.priority = UILayoutPriority.defaultHigh
                        containerView.addConstraints([leadingConstraint, trailingConstraint, centerYConstraint, topConstraint, bottomConstraint, centerXConstraint, minimumWidthConstraint, maximumWidthConstraint])
                        self.centerYConstraint = centerYConstraint
                    } else {
                        let topConstraint = NSLayoutConstraint(item: contentView, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .topMargin, multiplier: 1.0, constant: self.verticalPadding)
                        containerView.addConstraints([leadingConstraint, trailingConstraint, topConstraint, bottomConstraint, centerXConstraint, minimumWidthConstraint, maximumWidthConstraint])
                    }
                    self.contentView = contentView
                    self.bottomConstraint = bottomConstraint
                    
                    
                    // Animate appearances
                    
                    let duration = self.transitionDuration(using: transitionContext)
                    
                    contentView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
                    UIView.animate(
                        withDuration: duration,
                        delay: 0.0,
                        usingSpringWithDamping: springDamping,
                        initialSpringVelocity: 0.0,
                        options: UIView.AnimationOptions.curveEaseOut,
                        animations: { () -> Void in
                            contentView.transform = CGAffineTransform.identity
                        }, completion: { (finished) -> Void in
                            transitionContext.completeTransition(finished)
                        })
                    
                    // animate fadeview

                    let fadeDuration = duration * backgroundFadeDurationPercent

                    fadeView.alpha = 0.0
                    UIView.animate(
                        withDuration: fadeDuration,
                        delay: 0.0,
                        options: UIView.AnimationOptions.curveLinear,
                        animations: { () -> Void in
                            fadeView.alpha = 1.0
                        },
                        completion: nil)
                    
                    // animate tintcolors
                    
                    if let window = containerView.window {
                        UIView.animate(
                            withDuration: fadeDuration,
                            animations: { () -> Void in
                                window.tintAdjustmentMode = .dimmed
                            })
                    }
                    containerView.tintAdjustmentMode = .normal
            }
        }
    }
    
    // MARK: - User actions
    
    @objc func backgroundTapped(_ tap:UITapGestureRecognizer) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
