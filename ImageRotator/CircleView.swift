//
//  CircleView.swift
//  ImageRotator
//
//  Created by Stefan Boblic on 23.01.2023.
//

import UIKit

class CircleView: UIView {

    lazy var shapeLayer: CAShapeLayer = self.layer as! CAShapeLayer

    override class var layerClass: AnyClass {
        return CAShapeLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        shapeLayer.fillColor = UIColor.systemPink.cgColor
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.lineWidth = 6
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.path = UIBezierPath(ovalIn: bounds).cgPath
    }

}
