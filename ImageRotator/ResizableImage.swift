//
//  ResizableImage.swift
//  ImageRotator
//
//  Created by Stefan Boblic on 28.01.2023.
//

import UIKit

class ResizableImage: UIImageView {

    private enum CornerType {
        case topLeft, topRight, bottomLeft, bottomRight, rotate, delete
    }

    private var topLeft: CircleView!
    private var topRight: CircleView!
    private var bottomLeft: CircleView!
    private var bottomRight: CircleView!
    private var rotateCircle: CircleView!
    private var deleteCircle: CircleView!

    private var circleViews: [CircleView] {
        return [topLeft, topRight, bottomLeft, bottomRight, rotateCircle, deleteCircle]
    }

    private var previousLocation = CGPoint.zero
    private var circlesAreVisible = false

    override func didMoveToSuperview() {
        topLeft = CircleView(diameter: 20)
        topRight = CircleView(diameter: 20)
        bottomLeft = CircleView(diameter: 20)
        bottomRight = CircleView(diameter: 20)
        rotateCircle = CircleView(image1Name: "arrow.counterclockwise.circle", diameter: 40)
        deleteCircle = CircleView(image2Name: "trash.circle", diameter: 40)

        circleViews.forEach {
            superview?.addSubview($0)
            $0.isHidden = true
        }

        var pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        topLeft.addGestureRecognizer(pan)
        pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        topRight.addGestureRecognizer(pan)
        pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        bottomLeft.addGestureRecognizer(pan)
        pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        bottomRight.addGestureRecognizer(pan)

        pan = UIPanGestureRecognizer(target: self, action: #selector(handleRotate))
        rotateCircle.addGestureRecognizer(pan)

        let deleteGesture = UITapGestureRecognizer(target: self, action: #selector(handleDelete))
        deleteCircle?.addGestureRecognizer(deleteGesture)

        let movePanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleMoveGesture))
        superview?.addGestureRecognizer(movePanGesture)

        let viewTap = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        superview?.addGestureRecognizer(viewTap)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePincheGesture))
        superview?.addGestureRecognizer(pinchGesture)

        updateCircleViews()
    }

    private func updateCircleViews() {
        topLeft.center = self.transformedTopLeft()
        topRight.center = self.transformedTopRight()
        bottomLeft.center = self.transformedBottomLeft()
        bottomRight.center = self.transformedBottomRight()
        rotateCircle.center = self.transformedRotateHandle()
        deleteCircle.center = self.transformedDeleteHandle()
    }

    @objc private func handleMoveGesture(_ gesture:UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.superview!)
        var center = self.center
        center.x += translation.x
        center.y += translation.y
        self.center = center

        gesture.setTranslation(CGPointZero, in: self.superview!)
        updateCircleViews()
    }

    private func angleBetweenPoints(startPoint: CGPoint, endPoint: CGPoint)  -> CGFloat {
        let startX = startPoint.x - self.center.x
        let startY = startPoint.y - self.center.y
        let endX = endPoint.x - self.center.x
        let endY = endPoint.y - self.center.y
        let atanX = atan2(startX, startY)
        let atanY = atan2(endX, endY)
        return atanX - atanY
    }

    @objc private func handleRotate(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            previousLocation = rotateCircle.center
            hideCircleViews()
        default:
            break
        }
        showCircleViews()
        let location = gesture.location(in: self.superview!)
        let angle = angleBetweenPoints(startPoint: previousLocation, endPoint: location)
        self.transform = CGAffineTransformRotate(self.transform, angle)
        previousLocation = location
        updateCircleViews()
    }

    private func hideCircleViews() {
        circleViews.forEach { $0.isHidden = true }
        circlesAreVisible = false
        self.layer.borderWidth = 0
        self.layer.borderColor = UIColor.clear.cgColor
    }

    private  func showCircleViews() {
        circleViews.forEach { $0.isHidden = false }
        circlesAreVisible = true
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.white.cgColor
    }

    @objc private func handleTapGesture() {
        if circlesAreVisible {
            hideCircleViews()
        } else {
            showCircleViews()
        }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    @objc private func handleDelete() {
        DispatchQueue.main.async { [weak self] in
            self?.superview?.removeFromSuperview()
            self?.hideCircleViews()
        }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let aspectRatio = bounds.width / bounds.height
        switch gesture.view! {
        case topLeft:
            if gesture.state == .began {
                self.setAnchorPoint(anchorPoint: CGPointMake(1, 1))
            }
            self.bounds.size.width -= translation.x
            self.bounds.size.height = self.bounds.width / aspectRatio
        case topRight:
            if gesture.state == .began {
                self.setAnchorPoint(anchorPoint: CGPointMake(0, 1))
            }
            self.bounds.size.width += translation.x
            self.bounds.size.height = self.bounds.width / aspectRatio
        case bottomLeft:
            if gesture.state == .began {
                self.setAnchorPoint(anchorPoint: CGPointMake(1, 0))
            }
            self.bounds.size.width -= translation.x
            self.bounds.size.height = self.bounds.width / aspectRatio
        case bottomRight:
            if gesture.state == .began {
                self.setAnchorPoint(anchorPoint: CGPointZero)
            }
            self.bounds.size.width += translation.x
            self.bounds.size.height = self.bounds.width / aspectRatio
        default:
            break
        }
        gesture.setTranslation(CGPointZero, in: self)
        updateCircleViews()
        if gesture.state == .ended {
            self.setAnchorPoint(anchorPoint: CGPointMake(0.5, 0.5))
        }
    }

    @objc private func handlePincheGesture(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            hideCircleViews()
        case .changed:
            let scale = gesture.scale
            let newScale = self.transform.a * scale
            if newScale >= 0.7 {
                self.transform = self.transform.scaledBy(x: scale, y: scale)
                gesture.scale = 1.0
            }
        case .ended:
            showCircleViews()
        default:
            break
        }
        updateCircleViews()
    }
}

extension UIView {

    func offsetPointToParentCoordinates(point: CGPoint) -> CGPoint {
        return CGPointMake(point.x + self.center.x, point.y + self.center.y)
    }

    func pointInViewCenterTerms(point:CGPoint) -> CGPoint {
        return CGPointMake(point.x - self.center.x, point.y - self.center.y)
    }

    func pointInTransformedView(point: CGPoint) -> CGPoint {
        let offsetItem = self.pointInViewCenterTerms(point: point)
        let updatedItem = CGPointApplyAffineTransform(offsetItem, self.transform)
        let finalItem = self.offsetPointToParentCoordinates(point: updatedItem)
        return finalItem
    }

    func originalFrame() -> CGRect {
        let currentTransform = self.transform
        self.transform = CGAffineTransformIdentity
        let originalFrame = self.frame
        self.transform = currentTransform
        return originalFrame
    }

    func transformedTopLeft() -> CGPoint {
        let frame = self.originalFrame()
        let point = frame.origin
        return self.pointInTransformedView(point: point)
    }

    func transformedTopRight() -> CGPoint {
        let frame = self.originalFrame()
        var point = frame.origin
        point.x += frame.size.width
        return self.pointInTransformedView(point: point)
    }

    func transformedBottomRight() -> CGPoint {
        let frame = self.originalFrame()
        var point = frame.origin
        point.x += frame.size.width
        point.y += frame.size.height
        return self.pointInTransformedView(point: point)
    }

    func transformedBottomLeft() -> CGPoint {
        let frame = self.originalFrame()
        var point = frame.origin
        point.y += frame.size.height
        return self.pointInTransformedView(point: point)
    }

    func transformedRotateHandle() -> CGPoint {
        let frame = self.originalFrame()
        var point = frame.origin
        point.x += frame.size.width + 40
        point.y += frame.size.height / 2 - 30
        return self.pointInTransformedView(point: point)
    }

    func transformedDeleteHandle() -> CGPoint {
        let frame = self.originalFrame()
        var point = frame.origin
        point.x += frame.size.width + 40
        point.y += frame.size.height / 2 + 30
        return self.pointInTransformedView(point: point)
    }

    func setAnchorPoint(anchorPoint:CGPoint) {
        var newPoint = CGPointMake(self.bounds.size.width * anchorPoint.x, self.bounds.size.height * anchorPoint.y)
        var oldPoint = CGPointMake(self.bounds.size.width * self.layer.anchorPoint.x, self.bounds.size.height * self.layer.anchorPoint.y)

        newPoint = CGPointApplyAffineTransform(newPoint, self.transform)
        oldPoint = CGPointApplyAffineTransform(oldPoint, self.transform)

        var position = self.layer.position
        position.x -= oldPoint.x
        position.x += newPoint.x
        position.y -= oldPoint.y
        position.y += newPoint.y

        self.layer.position = position
        self.layer.anchorPoint = anchorPoint
    }
}
