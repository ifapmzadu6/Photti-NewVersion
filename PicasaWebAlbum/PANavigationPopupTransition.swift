//
//  PANavigationPopupTransition.swift
//  Photti
//
//  Created by Keisuke Karijuku on 2014/11/22.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

import Foundation
import UIKit

class PANavigationPopupTransition : NSObject {
    
    var isPop = false
    var enabled : Bool = true {
        didSet {
            if (self.popRecognizerView != nil && self.popGestureRecognizer != nil) {
                var contained  = (popRecognizerView!.gestureRecognizers! as NSArray).containsObject(popGestureRecognizer!)
                if contained {
                    popRecognizerView?.removeGestureRecognizer(popGestureRecognizer!)
                }
                if enabled {
                    popRecognizerView?.addGestureRecognizer(popGestureRecognizer!)
                }
            }
        }
    }
    
    var imageForSource : UIImage?
    
    var frameForSource : CGRect?
    func setFrameForSource(frame : CGRect) {
        frameForSource = frame
    }
    var frameForDestination : CGRect?
    func setFrameForDestination(frame : CGRect) {
        frameForDestination = frame
    }
    
    var interactivePopTransition : UIPercentDrivenInteractiveTransition?
    var popGestureRecognizer : UIScreenEdgePanGestureRecognizer?
    var popRecognizerView : UIView?
    
    var navigationController : UINavigationController?
    
    override init() {
        super.init()
        
        popGestureRecognizer = UIScreenEdgePanGestureRecognizer()
        popGestureRecognizer?.addTarget(self, action: "handlePopRecognizer:")
        popGestureRecognizer?.edges = UIRectEdge.Left
    }    
}

extension PANavigationPopupTransition : UIViewControllerAnimatedTransitioning {
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.35
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
        
        let containerView = transitionContext.containerView()
        let duration = transitionDuration(transitionContext)
        
        let popupImageView = UIImageView()
        popupImageView.image = imageForSource
        popupImageView.contentMode = UIViewContentMode.ScaleAspectFill
        popupImageView.backgroundColor = UIColor.clearColor()
        popupImageView.clipsToBounds = true
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.whiteColor()
        
        navigationController = fromViewController?.navigationController
        
        if self.isPop {
            popupImageView.frame = frameForDestination!
            
            toViewController?.view.frame = transitionContext.finalFrameForViewController(toViewController!)
            fromViewController?.view.alpha = 0.0
            containerView.insertSubview(toViewController!.view, belowSubview: fromViewController!.view)
            backgroundView.frame = fromViewController!.view.frame
            backgroundView.alpha = 1.0
            containerView.addSubview(backgroundView)
            containerView.addSubview(popupImageView)
            
            UIView.animateWithDuration(
                duration,
                delay: 0.0,
                options: UIViewAnimationOptions(7<<16),
                animations: { () in
                    backgroundView.alpha = 0.0
                    popupImageView.frame = self.frameForSource!
                },
                completion: { finish in
                    backgroundView.removeFromSuperview()
                    popupImageView.removeFromSuperview()
                    
                    if transitionContext.transitionWasCancelled() {
                        fromViewController?.view.alpha = 1.0
                    }
                    
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                }
            )
        }
        else {
            popupImageView.frame = frameForSource!
            
            toViewController?.view.frame = transitionContext.finalFrameForViewController(toViewController!)
            toViewController?.view.alpha = 0.0
            
            containerView.addSubview(toViewController!.view)
            backgroundView.frame = transitionContext.finalFrameForViewController(toViewController!)
            backgroundView.alpha = 0.0
            containerView.addSubview(backgroundView)
            containerView.addSubview(popupImageView)
            
            UIView.animateWithDuration(duration,
                delay: 0.0,
                options: UIViewAnimationOptions(7<<16),
                animations: { () -> Void in
                    backgroundView.alpha = 1.0
                    popupImageView.frame = containerView.convertRect(self.frameForDestination!, fromView: toViewController?.view)
                },
                completion: { final -> Void in
                    backgroundView.removeFromSuperview()
                    popupImageView.removeFromSuperview()
                    
                    if !transitionContext.transitionWasCancelled() {
                        toViewController?.view.alpha = 1.0
                    }
                    
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                    
                    self.isPop = true
                }
            )
        }
    }
}

extension PANavigationPopupTransition : UINavigationControllerDelegate {
    func navigationController(
        navigationController: UINavigationController,
        animationControllerForOperation operation: UINavigationControllerOperation,
        fromViewController fromVC: UIViewController,
        toViewController toVC: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            if self.enabled {
                return self
            }
            
            return nil
    }
    
    func navigationController(navigationController: UINavigationController, interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactivePopTransition
    }
}

extension PANavigationPopupTransition  {
    func handlePopRecognizer(recognizer : UIScreenEdgePanGestureRecognizer) {
        var progress = recognizer.translationInView(recognizer.view!).x / recognizer.view!.bounds.size.width*1.0
        progress = min(1.0, max(0.0, progress))
        
        switch recognizer.state {
        case UIGestureRecognizerState.Began:
            interactivePopTransition = UIPercentDrivenInteractiveTransition()
            
            navigationController?.popViewControllerAnimated(true)
            
        case UIGestureRecognizerState.Changed:
            interactivePopTransition?.updateInteractiveTransition(progress)
            
        case UIGestureRecognizerState.Ended:
            fallthrough
        case UIGestureRecognizerState.Cancelled:
            if (progress > 0.5) {
                interactivePopTransition?.finishInteractiveTransition()
            }
            else {
                interactivePopTransition?.cancelInteractiveTransition()
            }
            interactivePopTransition = nil;
        default:
            interactivePopTransition?.cancelInteractiveTransition()
        }
    }
}


