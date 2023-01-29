//
//  ImageResizingViewController.swift
//  ImageRotator
//
//  Created by Stefan Boblic on 20.01.2023.
//

import UIKit

class ViewController: UIViewController {

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        let bundlePath = Bundle.main.path(forResource: "lockscreen", ofType: "jpeg")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(contentsOfFile: bundlePath ?? "")
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleToFill
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        let resizableView = ResizableImage(frame: CGRectMake(30, 130, view.frame.width - 100, view.frame.height - 260))
        resizableView.backgroundColor = UIColor(patternImage: imageView.image!)
        view.addSubview(resizableView)
    }
}
