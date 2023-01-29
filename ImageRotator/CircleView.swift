//
//  CircleView.swift
//  ImageRotator
//
//  Created by Stefan Boblic on 23.01.2023.
//

import UIKit

class CircleView: UIView {

    private var fillColor: UIColor
    private var strokeColor: UIColor
    private var strokeWidth: CGFloat
    private var image1: UIImage
    private var image2: UIImage

    static func createResizedImage(name: String, diameter: CGFloat) -> UIImage {
        guard let image = UIImage(systemName: name) else { return UIImage() }
        return image.withConfiguration(UIImage.SymbolConfiguration(pointSize: diameter, weight: .medium))
    }

    init(fillColor: UIColor = .systemPink, strokeColor: UIColor = .white, strokeWidth: CGFloat = 6, image1Name: String = "", image2Name: String = "", diameter: CGFloat) {
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.image1 = CircleView.createResizedImage(name: image1Name, diameter: diameter)
        self.image2 = CircleView.createResizedImage(name: image2Name, diameter: diameter)
        super.init(frame: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        self.backgroundColor = .clear

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let handlePath = UIBezierPath(ovalIn: rect.insetBy(dx: strokeWidth / 2, dy: strokeWidth / 2))
        fillColor.setFill()
        handlePath.fill()
        strokeColor.setStroke()
        handlePath.lineWidth = 6
        handlePath.stroke()

        let image1Rect = CGRect(x: rect.width/4, y: rect.height/4, width: rect.width/2, height: rect.height/2)
        image1.draw(in: image1Rect)

        let image2Rect = CGRect(x: rect.width/4, y: rect.height/4, width: rect.width/2, height: rect.height/2)
        image2.draw(in: image2Rect)
    }
}
