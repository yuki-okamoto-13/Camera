//
//  ViewController.swift
//  Camera
//
//  Created by okamoto yuki on 2023/04/12.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var photoFrameImageView: UIImageView!

    var captureSession: AVCaptureSession?

    var isMainCamera = true
    var currentDevice: AVCaptureDevice?
    var mainCamera: AVCaptureDevice?
    var innerCamera: AVCaptureDevice?

    var photoOutput: AVCapturePhotoOutput?
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupDevice()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setupCaptureSession()
        setupPreviewLayer()

        startCaptureSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stopCaptureSession()
    }

    @IBAction private func onTapShutterButton(_ sender: Any) {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }

    @IBAction private func onTapPhotoFrameButton(_ sender: Any) {
        photoFrameImageView.image = UIImage(named: "frame0073")
    }

    @IBAction private func onTapChangeCamera(_ sender: Any) {
        stopCaptureSession()

        currentDevice = isMainCamera ? innerCamera : mainCamera
        isMainCamera = !isMainCamera

        setupCaptureSession()
        setupPreviewLayer()

        startCaptureSession()
    }

    // デバイスの設定
    private func setupDevice() {
        // プロパティ設定
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )

        // カメラデバイスの取得
        let devices = deviceDiscoverySession.devices

        for device in devices {
            if device.position == .back {
                mainCamera = device
            } else if device.position == .front {
                innerCamera = device
            }
        }

        // 起動時のカメラを設定
        currentDevice = mainCamera ?? innerCamera
    }

    private func setupCaptureSession() {
        guard let device = currentDevice else {
            return
        }

        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        // 入力ファイルフォーマット
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: device)
            captureSession.addInput(captureDeviceInput)
        } catch {
            print(error)
        }

        // 出力ファイルフォーマット
        let photoOutput = AVCapturePhotoOutput()
        photoOutput.setPreparedPhotoSettingsArray(
            [AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg, ])]
        )
        captureSession.addOutput(photoOutput)

        self.photoOutput = photoOutput
        self.captureSession = captureSession
    }

    // レイヤの設定
    private func setupPreviewLayer() {
        guard let captureSession = captureSession else {
            return
        }

        let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer.videoGravity = .resizeAspectFill
        cameraPreviewLayer.connection?.videoOrientation = .portrait
        cameraPreviewLayer.frame = cameraView.layer.bounds
        cameraView.layer.sublayers?.removeAll(where: { $0 is AVCaptureVideoPreviewLayer})
        cameraView.layer.addSublayer(cameraPreviewLayer)

        self.cameraPreviewLayer = cameraPreviewLayer
    }

    private func startCaptureSession() {
        DispatchQueue.global(qos: .background).async { [self] in
            captureSession?.startRunning()
        }
    }

    private func stopCaptureSession() {
        DispatchQueue.global(qos: .background).async { [self] in
            captureSession?.stopRunning()
        }
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(),
           let image = UIImage(data: imageData) {
            let compositedImage = compositeFrameIntoImage(image: image)
            UIImageWriteToSavedPhotosAlbum(compositedImage, self, #selector(showSaveImageResult(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }

    @objc
    private func showSaveImageResult(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeMutableRawPointer) {
        // do something if error occurred
    }

    private func compositeFrameIntoImage(image: UIImage) -> UIImage {
        guard let frameImage = photoFrameImageView.image else {
            return image
        }

        return compositeFrameIntoImage(frameImage, image: image) ?? image
    }

    private func compositeFrameIntoImage(_ frameImage: UIImage, image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContext(image.size)

        let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        image.draw(in: rect)
        frameImage.draw(in: rect)

        let compositedImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return compositedImage
    }
}
