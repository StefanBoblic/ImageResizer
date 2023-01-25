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

    private let rotateButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let newSize = CGSize(width: 35, height: 35)
        let image = UIImage(systemName: "arrow.counterclockwise.circle")
        let resizedImage = image?.withConfiguration(UIImage.SymbolConfiguration(pointSize: newSize.width, weight: .medium))
        button.setImage(resizedImage, for: .normal)
        button.tintColor = .systemPink
        button.isHidden = true
        return button
    }()

    private let deleteButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let newSize = CGSize(width: 35, height: 35)
        let image = UIImage(systemName: "trash.circle")
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

    private let buttonStackView: UIStackView = {
        let buttonStackView = UIStackView()
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 20
        buttonStackView.distribution = .fillEqually
        return buttonStackView
    }()

    private var topLeftCircleView = CircleView()
    private var topRightCircleView = CircleView()
    private var bottomLeftCircleView = CircleView()
    private var bottomRightCircleView = CircleView()

    private var circleViews: [CircleView] {
        return [topLeftCircleView, topRightCircleView, bottomLeftCircleView, bottomRightCircleView]
    }
    private var containerViewTopConstraint: NSLayoutConstraint!
    private var containerViewBottomConstraint: NSLayoutConstraint!
    private var containerViewLeftConstraint: NSLayoutConstraint!
    private var containerViewRightConstraint: NSLayoutConstraint!

    private var containerViewWidthConstraint: NSLayoutConstraint!
    private var containerViewHeightConstraint: NSLayoutConstraint!
    private var containerViewXAnchorConstraint: NSLayoutConstraint!

    private var isResizing: Bool = false {
        didSet {
            [topLeftCircleView, topRightCircleView, bottomLeftCircleView, bottomRightCircleView, rotateButton, deleteButton].forEach { $0.isHidden = !isResizing }
            borderView.layer.borderWidth = isResizing ? 2.0 : 0.0
        }
    }

    private var resizeRect = ResizeRect()
    private var proxyFactor: CGFloat = 10.0

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
        containerViewTopConstraint = containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 180)
        containerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -180)
        containerViewLeftConstraint = containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 70)
        containerViewRightConstraint = containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -70)

        NSLayoutConstraint.activate([containerViewTopConstraint, containerViewBottomConstraint , containerViewLeftConstraint, containerViewRightConstraint])

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
        buttonStackView.addArrangedSubview(rotateButton)
        buttonStackView.addArrangedSubview(deleteButton)
        imageView.addSubview(borderView)
    }

    private func addRotationGesture() {
        let rotationGesture = UIPanGestureRecognizer(target: self, action: #selector(handleRotationGesture))
        rotateButton.addGestureRecognizer(rotationGesture)
    }

    @objc private func handleRotationGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.state == .began {
            circleViews.forEach { $0.isHidden = true }
        }
        guard let view = gestureRecognizer.view else { return }
        let translation = gestureRecognizer.translation(in: view)
        containerView.transform = containerView.transform.rotated(by: -1 * translation.x / 100)
        gestureRecognizer.setTranslation(.zero, in: view)
        if gestureRecognizer.state == .ended {
            circleViews.forEach { $0.isHidden = false }
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
        circleViews.forEach {
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

    private func updateCircleViews(top: Bool, left: Bool, right: Bool, bottom: Bool) {
        resizeRect.topTouch = top
        resizeRect.leftTouch = left
        resizeRect.rightTouch = right
        resizeRect.bottomTouch = bottom
        topLeftCircleView.isHidden = !top || !left
        topRightCircleView.isHidden = !top || !right
        bottomLeftCircleView.isHidden = !bottom || !left
        bottomRightCircleView.isHidden = !bottom || !right
        circleViews.filter { !$0.isHidden }.forEach {
            $0.shapeLayer.lineWidth = 80
            $0.shapeLayer.opacity = 0.6
        }
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
            updateCircleViews(top: false, left: false, right: true, bottom: true)
        case (containerView.frame.minX-proxyFactor...containerView.frame.minX+proxyFactor, containerView.frame.maxY-proxyFactor...containerView.frame.maxY+proxyFactor):
            updateCircleViews(top: false, left: true, right: false, bottom: true)
        case (containerView.frame.maxX-proxyFactor...containerView.frame.maxX+proxyFactor, containerView.frame.minY-proxyFactor...containerView.frame.minY+proxyFactor):
            updateCircleViews(top: true, left: false, right: true, bottom: false)
        case (containerView.frame.minX-proxyFactor...containerView.frame.minX+proxyFactor, containerView.frame.minY-proxyFactor...containerView.frame.minY+proxyFactor):
            updateCircleViews(top: true, left: true, right: false, bottom: false)
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
        var heightDiff: CGFloat = .zero

        let aspectRatio = containerView.bounds.width / containerView.bounds.height

        switch (resizeRect.topTouch, resizeRect.leftTouch, resizeRect.rightTouch, resizeRect.bottomTouch) {
        case (true, true, _, _):
            widthDiff = location.x - previousLocation.x
            heightDiff = widthDiff / aspectRatio
            containerViewLeftConstraint.constant += widthDiff
            containerViewTopConstraint.constant += heightDiff
        case (true, _, true, _):
            widthDiff = previousLocation.x - location.x
            heightDiff = widthDiff / aspectRatio
            containerViewRightConstraint.constant -= widthDiff
            containerViewTopConstraint.constant += heightDiff
        case (_, true, _, true):
            widthDiff = location.x - previousLocation.x
            heightDiff = widthDiff / aspectRatio
            containerViewLeftConstraint.constant += widthDiff
            containerViewBottomConstraint.constant -= heightDiff
        case (_, _, true, true):
            widthDiff = previousLocation.x - location.x
            heightDiff = widthDiff / aspectRatio
            containerViewRightConstraint.constant -= widthDiff
            containerViewBottomConstraint.constant -= heightDiff
        default:
            break
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        circleViews.forEach {
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
