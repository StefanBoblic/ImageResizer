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
        imageView.clipsToBounds = false
        return imageView
    }()

    private let rotateButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let newSize = CGSize(width: 25, height: 25)
        let image = UIImage(systemName: "rotate.left")
        let resizedImage = image?.withConfiguration(UIImage.SymbolConfiguration(pointSize: newSize.width, weight: .medium))
        button.setImage(resizedImage, for: .normal)
        button.tintColor = .systemPink
        button.isHidden = true
        return button
    }()

    private let deleteButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let newSize = CGSize(width: 25, height: 25)
        let image = UIImage(systemName: "trash")
        let resizedImage = image?.withConfiguration(UIImage.SymbolConfiguration(pointSize: newSize.width, weight: .medium))
        button.setImage(resizedImage, for: .normal)
        button.tintColor = .systemPink
        button.isHidden = true
        return button
    }()

    private let borderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 0
        return view
    }()

    private var topLeftCircleView = CircleView()
    private var topRightCircleView = CircleView()
    private var bottomLeftCircleView = CircleView()
    private var bottomRightCircleView = CircleView()

    private var imageViewTopConstraint: NSLayoutConstraint!
    private var imageViewBottomConstraint: NSLayoutConstraint!
    private var imageViewLeftConstraint: NSLayoutConstraint!
    private var imageViewRightConstraint: NSLayoutConstraint!
    private var imageViewWidthConstraint: NSLayoutConstraint!
    private var imageViewHeightConstraint: NSLayoutConstraint!

    private var rotateButtonBottomAnchorConstraint: NSLayoutConstraint!
    private var rotateButtonTrailingAnchorConstraint: NSLayoutConstraint!
    private var deleteButtonTopAnchorConstraint: NSLayoutConstraint!
    private var deleteButtonTrailingAnchorConstraint: NSLayoutConstraint!

    private var isResizing: Bool = false {
        didSet {
            [topLeftCircleView, topRightCircleView, bottomLeftCircleView, bottomRightCircleView, rotateButton, deleteButton].forEach { $0.isHidden = !isResizing }
            borderView.layer.borderWidth = isResizing ? 2.0 : 0.0
        }
    }

    private var resizeRect = ResizeRect()
    private var proxyFactor: CGFloat = 10.0
    private var rotationGesture: UIRotationGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupView()
        addConstraintsForItems()
        createCircles()

        addTapGestureRecognizer()
        addPinchGestureRecognizer()
        addRotationGesture()
        addDeletePhotoButton()
    }

    private func addConstraintsForItems() {
        let imageViewXAnchorConstraint = imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let imageViewYAnchorConstraint = imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        imageViewWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: 120)
        imageViewHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 320)

        NSLayoutConstraint.activate([imageViewWidthConstraint, imageViewHeightConstraint, imageViewXAnchorConstraint, imageViewYAnchorConstraint])

        let borderViewTopConstraint = borderView.topAnchor.constraint(equalTo: imageView.topAnchor)
        let borderViewLeftConstraint = borderView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor)
        let borderViewRightConstraint = borderView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor)
        let borderViewBottomConstraint = borderView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)

        NSLayoutConstraint.activate([borderViewTopConstraint, borderViewLeftConstraint, borderViewRightConstraint, borderViewBottomConstraint])

        let buttonStackView = UIStackView()
        buttonStackView.addArrangedSubview(rotateButton)
        buttonStackView.addArrangedSubview(deleteButton)
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 20
        buttonStackView.distribution = .fillEqually
        view.addSubview(buttonStackView)

        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        let trailingStackViewConstraint = buttonStackView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 40)
        let centerYStackViewConstraint = buttonStackView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        let stackViewWidthConstraint = buttonStackView.widthAnchor.constraint(equalToConstant: 50)
        let stackViewHeightConstraint = buttonStackView.heightAnchor.constraint(equalToConstant: 100)

        NSLayoutConstraint.activate([trailingStackViewConstraint, centerYStackViewConstraint, stackViewWidthConstraint, stackViewHeightConstraint])
    }

    private func setupView() {
        view.addSubview(imageView)
        view.addSubview(rotateButton)
        view.addSubview(deleteButton)
        imageView.addSubview(borderView)
    }

    private func addRotationGesture() {
        rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotationGesture))
        rotateButton.addTarget(self, action: #selector(handleButtonPress), for: .touchUpInside)
    }

    @objc private func handleButtonPress() {
        if rotateButton.isSelected {
            imageView.removeGestureRecognizer(rotationGesture)
            rotationGesture.state = .possible
            rotateButton.tintColor = .systemPink
            rotateButton.isSelected = false
        } else {
            imageView.addGestureRecognizer(rotationGesture)
            rotateButton.tintColor = .systemBlue
            rotateButton.isSelected = true
        }
    }

    @objc private func handleRotationGesture(_ gestureRecognizer: UIRotationGestureRecognizer) {
        if gestureRecognizer.state == .began {
            isResizing = false
        }
        guard let view = gestureRecognizer.view else { return }
        view.transform = view.transform.rotated(by: gestureRecognizer.rotation)
        gestureRecognizer.rotation = 0
        if gestureRecognizer.state == .ended {
            isResizing = true
        }
    }

    private func addDeletePhotoButton() {
        deleteButton.addTarget(self, action: #selector(handleDeleteImage), for: .touchUpInside)
    }

    @objc private func handleDeleteImage() {
        let alert = UIAlertController(title: "Delete image?", message: "Are you sure you want to delete this image?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            DispatchQueue.main.async {
                self?.imageView.removeFromSuperview()
                self?.isResizing = false
            }
        }

        alert.addAction(cancelAction)
        alert.addAction(deleteAction)

        present(alert, animated: true, completion: nil)
    }

    private func addTapGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageViewTap))
        imageView.addGestureRecognizer(tapGesture)
    }

    private func addPinchGestureRecognizer() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePincheGesture))
        imageView.addGestureRecognizer(pinchGesture)
    }

    @objc private func handlePincheGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {
        if gestureRecognizer.state == .began {
            isResizing = false
        }
        gestureRecognizer.view?.transform = (gestureRecognizer.view?.transform)!.scaledBy(x: gestureRecognizer.scale, y: gestureRecognizer.scale)
        gestureRecognizer.scale = 1.0
        if gestureRecognizer.state == .ended {
            isResizing = true
        }
    }

    @objc private func handleImageViewTap(gesture: UITapGestureRecognizer) {
        isResizing.toggle()
    }

    private func createCircles() {
        [topLeftCircleView, topRightCircleView, bottomLeftCircleView, bottomRightCircleView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.widthAnchor.constraint(equalToConstant: 20).isActive = true
            $0.heightAnchor.constraint(equalTo: $0.widthAnchor).isActive = true
            $0.isHidden = true
            imageView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            topLeftCircleView.centerXAnchor.constraint(equalTo: imageView.leadingAnchor),
            topLeftCircleView.centerYAnchor.constraint(equalTo: imageView.topAnchor),

            topRightCircleView.centerXAnchor.constraint(equalTo: imageView.trailingAnchor),
            topRightCircleView.centerYAnchor.constraint(equalTo: imageView.topAnchor),

            bottomLeftCircleView.centerXAnchor.constraint(equalTo: imageView.leadingAnchor),
            bottomLeftCircleView.centerYAnchor.constraint(equalTo: imageView.bottomAnchor),

            bottomRightCircleView.centerXAnchor.constraint(equalTo: imageView.trailingAnchor),
            bottomRightCircleView.centerYAnchor.constraint(equalTo: imageView.bottomAnchor),
        ])
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isResizing else { return }
        guard let touch = touches.first else { return }
        let touchStart = touch.location(in: self.view)
        resizeRect.topTouch = false
        resizeRect.leftTouch = false
        resizeRect.rightTouch = false
        resizeRect.bottomTouch = false

        switch (touchStart.x, touchStart.y) {
        case (imageView.frame.maxX-proxyFactor...imageView.frame.maxX+proxyFactor, imageView.frame.maxY-proxyFactor...imageView.frame.maxY+proxyFactor):
            resizeRect.rightTouch = true
            resizeRect.bottomTouch = true
            topLeftCircleView.isHidden = true
            topRightCircleView.isHidden = true
            bottomLeftCircleView.isHidden = true
            bottomRightCircleView.isHidden = false
            bottomRightCircleView.shapeLayer.lineWidth = 80
            bottomRightCircleView.shapeLayer.opacity = 0.6
        case (imageView.frame.minX-proxyFactor...imageView.frame.minX+proxyFactor, imageView.frame.maxY-proxyFactor...imageView.frame.maxY+proxyFactor):
            resizeRect.leftTouch = true
            resizeRect.bottomTouch = true
            topLeftCircleView.isHidden = true
            topRightCircleView.isHidden = true
            bottomLeftCircleView.isHidden = false
            bottomRightCircleView.isHidden = true
            bottomLeftCircleView.shapeLayer.lineWidth = 80
            bottomLeftCircleView.shapeLayer.opacity = 0.6
        case (imageView.frame.maxX-proxyFactor...imageView.frame.maxX+proxyFactor, imageView.frame.minY-proxyFactor...imageView.frame.minY+proxyFactor):
            resizeRect.rightTouch = true
            resizeRect.topTouch = true
            topLeftCircleView.isHidden = true
            topRightCircleView.isHidden = false
            bottomLeftCircleView.isHidden = true
            bottomRightCircleView.isHidden = true
            topRightCircleView.shapeLayer.lineWidth = 80
            topRightCircleView.shapeLayer.opacity = 0.6
        case (imageView.frame.minX-proxyFactor...imageView.frame.minX+proxyFactor, imageView.frame.minY-proxyFactor...imageView.frame.minY+proxyFactor):
            resizeRect.leftTouch = true
            resizeRect.topTouch = true
            topLeftCircleView.isHidden = false
            topRightCircleView.isHidden = true
            bottomLeftCircleView.isHidden = true
            bottomRightCircleView.isHidden = true
            topLeftCircleView.shapeLayer.lineWidth = 80
            topLeftCircleView.shapeLayer.opacity = 0.6
        default:
            break
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isResizing else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: view)
        let previousLocation = touch.previousLocation(in: view)
        var widthDiff: CGFloat = .zero
        if (resizeRect.topTouch && resizeRect.leftTouch) || (resizeRect.bottomTouch && resizeRect.leftTouch) {
            widthDiff = previousLocation.x - location.x
        } else if (resizeRect.topTouch && resizeRect.rightTouch) || (resizeRect.bottomTouch && resizeRect.rightTouch) {
            widthDiff = location.x - previousLocation.x
        }
        let aspectRatio = imageView.bounds.width / imageView.bounds.height
        let newWidth = imageView.bounds.width + widthDiff
        let newHeight = newWidth / aspectRatio
        let minWidth: CGFloat = 120
        let maxWidth: CGFloat = 195
        let minHeight: CGFloat = 320
        let maxHeight: CGFloat = 520

        let newWidthSize = max(minWidth, min(maxWidth, newWidth))
        let newHeightSize = max(minHeight, min(maxHeight, newHeight))

        switch (resizeRect.topTouch, resizeRect.leftTouch, resizeRect.rightTouch, resizeRect.bottomTouch) {
        case (true, true, _, _):
            imageViewWidthConstraint.constant = newWidthSize
            imageViewHeightConstraint.constant = newHeightSize
        case (true, _, true, _):
            imageViewWidthConstraint.constant = newWidthSize
            imageViewHeightConstraint.constant = newHeightSize
        case (_, true, _, true):
            imageViewWidthConstraint.constant = newWidthSize
            imageViewHeightConstraint.constant = newHeightSize
        case (_, _, true, true):
            imageViewWidthConstraint.constant = newWidthSize
            imageViewHeightConstraint.constant = newHeightSize
        default:
            break
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        [topLeftCircleView, topRightCircleView, bottomLeftCircleView, bottomRightCircleView].forEach {
            $0.isHidden = false
            $0.shapeLayer.lineWidth = 6
            $0.shapeLayer.opacity = 1
        }
    }
}

struct ResizeRect{
    var topTouch = false
    var leftTouch = false
    var rightTouch = false
    var bottomTouch = false
}
