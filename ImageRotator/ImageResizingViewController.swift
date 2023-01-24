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

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()

    private let buttonStackView = UIStackView()

    private var topLeftCircleView = CircleView()
    private var topRightCircleView = CircleView()
    private var bottomLeftCircleView = CircleView()
    private var bottomRightCircleView = CircleView()

    private var containerViewWidthConstraint: NSLayoutConstraint!
    private var containerViewHeightConstraint: NSLayoutConstraint!

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
        let containerViewXAnchorConstraint = containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let containerViewYAnchorConstraint = containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        containerViewWidthConstraint = containerView.widthAnchor.constraint(equalToConstant: 120)
        containerViewHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 320)

        NSLayoutConstraint.activate([containerViewWidthConstraint, containerViewHeightConstraint, containerViewXAnchorConstraint, containerViewYAnchorConstraint])

        let imageViewTopConstraint = imageView.topAnchor.constraint(equalTo: containerView.topAnchor)
        let imageViewBottomConstraint = imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        let imageViewLeftConstraint = imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
        let imageViewTrailingConstraint = imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)

        NSLayoutConstraint.activate([imageViewTopConstraint, imageViewBottomConstraint, imageViewLeftConstraint, imageViewTrailingConstraint])

        let borderViewTopConstraint = borderView.topAnchor.constraint(equalTo: imageView.topAnchor)
        let borderViewLeftConstraint = borderView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor)
        let borderViewRightConstraint = borderView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor)
        let borderViewBottomConstraint = borderView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)

        NSLayoutConstraint.activate([borderViewTopConstraint, borderViewLeftConstraint, borderViewRightConstraint, borderViewBottomConstraint])

        buttonStackView.addArrangedSubview(rotateButton)
        buttonStackView.addArrangedSubview(deleteButton)
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 20
        buttonStackView.distribution = .fillEqually

        buttonStackView.isUserInteractionEnabled = true
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        let stackViewCenterXConstraint = buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let stackViewBottomConstraint = buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        let stackViewWidthConstraint = buttonStackView.widthAnchor.constraint(equalToConstant: 100)
        let stackViewHeightConstraint = buttonStackView.heightAnchor.constraint(equalToConstant: 50)

        NSLayoutConstraint.activate([stackViewCenterXConstraint, stackViewBottomConstraint, stackViewWidthConstraint, stackViewHeightConstraint])
    }

    private func setupView() {
        view.addSubview(containerView)
        containerView.addSubview(imageView)
        view.addSubview(buttonStackView)
        imageView.addSubview(borderView)
    }

    private func addRotationGesture() {
        rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotationGesture))
        rotateButton.addTarget(self, action: #selector(handleButtonPress), for: .touchUpInside)
    }

    @objc private func handleButtonPress() {
        if rotateButton.isSelected {
            containerView.removeGestureRecognizer(rotationGesture)
            rotationGesture.state = .possible
            rotateButton.tintColor = .systemPink
            rotateButton.isSelected = false
        } else {
            containerView.addGestureRecognizer(rotationGesture)
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
                self?.containerView.removeFromSuperview()
                self?.isResizing = false
            }
        }

        alert.addAction(cancelAction)
        alert.addAction(deleteAction)

        present(alert, animated: true, completion: nil)
    }

    private func addTapGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageViewTap))
        containerView.addGestureRecognizer(tapGesture)
    }

    private func addPinchGestureRecognizer() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePincheGesture))
        containerView.addGestureRecognizer(pinchGesture)
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
        case (containerView.frame.maxX-proxyFactor...containerView.frame.maxX+proxyFactor, containerView.frame.maxY-proxyFactor...containerView.frame.maxY+proxyFactor):
            resizeRect.rightTouch = true
            resizeRect.bottomTouch = true
            topLeftCircleView.isHidden = true
            topRightCircleView.isHidden = true
            bottomLeftCircleView.isHidden = true
            bottomRightCircleView.isHidden = false
            bottomRightCircleView.shapeLayer.lineWidth = 80
            bottomRightCircleView.shapeLayer.opacity = 0.6
        case (containerView.frame.minX-proxyFactor...containerView.frame.minX+proxyFactor, containerView.frame.maxY-proxyFactor...containerView.frame.maxY+proxyFactor):
            resizeRect.leftTouch = true
            resizeRect.bottomTouch = true
            topLeftCircleView.isHidden = true
            topRightCircleView.isHidden = true
            bottomLeftCircleView.isHidden = false
            bottomRightCircleView.isHidden = true
            bottomLeftCircleView.shapeLayer.lineWidth = 80
            bottomLeftCircleView.shapeLayer.opacity = 0.6
        case (containerView.frame.maxX-proxyFactor...containerView.frame.maxX+proxyFactor, containerView.frame.minY-proxyFactor...containerView.frame.minY+proxyFactor):
            resizeRect.rightTouch = true
            resizeRect.topTouch = true
            topLeftCircleView.isHidden = true
            topRightCircleView.isHidden = false
            bottomLeftCircleView.isHidden = true
            bottomRightCircleView.isHidden = true
            topRightCircleView.shapeLayer.lineWidth = 80
            topRightCircleView.shapeLayer.opacity = 0.6
        case (containerView.frame.minX-proxyFactor...containerView.frame.minX+proxyFactor, containerView.frame.minY-proxyFactor...containerView.frame.minY+proxyFactor):
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
        let aspectRatio = containerView.bounds.width / containerView.bounds.height
        let newWidth = containerView.bounds.width + widthDiff
        let newHeight = newWidth / aspectRatio
        let minWidth: CGFloat = 120
        let maxWidth: CGFloat = 195
        let minHeight: CGFloat = 320
        let maxHeight: CGFloat = 520

        let newWidthSize = max(minWidth, min(maxWidth, newWidth))
        let newHeightSize = max(minHeight, min(maxHeight, newHeight))

        switch (resizeRect.topTouch, resizeRect.leftTouch, resizeRect.rightTouch, resizeRect.bottomTouch) {
        case (true, true, _, _):
            containerViewWidthConstraint.constant = newWidthSize
            containerViewHeightConstraint.constant = newHeightSize
        case (true, _, true, _):
            containerViewWidthConstraint.constant = newWidthSize
            containerViewHeightConstraint.constant = newHeightSize
        case (_, true, _, true):
            containerViewWidthConstraint.constant = newWidthSize
            containerViewHeightConstraint.constant = newHeightSize
        case (_, _, true, true):
            containerViewWidthConstraint.constant = newWidthSize
            containerViewHeightConstraint.constant = newHeightSize
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
