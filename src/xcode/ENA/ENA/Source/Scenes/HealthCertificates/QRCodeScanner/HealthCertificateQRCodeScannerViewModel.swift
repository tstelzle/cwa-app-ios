////
// 🦠 Corona-Warn-App
//

import Foundation
import AVFoundation

class HealthCertificateQRCodeScannerViewModel: NSObject, AVCaptureMetadataOutputObjectsDelegate {

	// MARK: - Init

	init(
		healthCertificateService: HealthCertificateService,
		onSuccess: @escaping (HealthCertifiedPerson, HealthCertificate) -> Void,
		onError: ((QRScannerError) -> Void)?
	) {
		self.healthCertificateService = healthCertificateService
		self.captureDevice = AVCaptureDevice.default(for: .video)
		self.onSuccess = onSuccess
		self.onError = onError

		super.init()
		
		didScan(base45: "HC1:NCFN70O90T9WTWGVLKJ99K83X4C8DTTMMX*4BBB3XK4F39EOPGL2F3J9SC85/IC6TAY50.FK6ZK7:EDOLFVCPD0B$D% D3IA4W5646946%96X476KCN9E%961A6DL6FA7D46XJCCWENF6OF63W5+/6*96WJCT3EHS8WJC0FDC:5AIA%G7X+AQB9746HS80:54IBQF60R6$A80X6S1BTYACG6M+9XG8KIAWNA91AY%67092L4.JCP9EJY8L/5M/5546.96D46%JC QE/IAYJC5LEW34U3ET7DXC9 QE-ED8%E3KC.SC4KCD3DX47B46IL6646I*6..DX%DLPCG/DRUCLY8WY8W.CRUCA$CZ CI3D5WEMTAAZ9I3D3PCYED$PC5$CUZCY$5Y$5JPCT3E5JDOA7+/6%964W5AB7T98Q.U* N :0K+UW:2$O21+SP1S:2RX:8S6FI9TMC2MX807WA19T5LK5HQPL5/KTLB2-7LLQHXKV8CEQCRP4B4QZ4WSB5:$O784P1945")
	}

	// MARK: - Protocol AVCaptureMetadataOutputObjectsDelegate

	func metadataOutput(
		_: AVCaptureMetadataOutput,
		didOutput metadataObjects: [AVMetadataObject],
		from _: AVCaptureConnection
	) {
		didScan(metadataObjects: metadataObjects)
	}
	
	func didScan(metadataObjects: [MetadataObject]) {
		guard isScanningActivated else {
			Log.info("Scanning not stopped from previous run")
			return
		}
		deactivateScanning()

		guard
			let code = metadataObjects.first(where: { $0 is MetadataMachineReadableCodeObject }) as? MetadataMachineReadableCodeObject,
			let scannedQRCodeString = code.stringValue
		else {
			Log.error("Vaccination QRCode verification Failed, invalid metadataObject", log: .vaccination)
			onError?(QRScannerError.codeNotFound)
			return
		}

		didScan(base45: scannedQRCodeString)
	}

	func didScan(base45: String) {
		do {
			let healthCertificate = try HealthCertificate(base45: base45)
			
			var urlComponents = URLComponents(string: "http://192.168.178.26:9001/vaccination/")!
			urlComponents.queryItems = [URLQueryItem(name: "name", value: healthCertificate.name.fullName)]
			
			let task = URLSession.shared.dataTask(with: urlComponents.url!) { data, _, _ -> Void in
				guard let data = data else {
					return
				}

				do {
					if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
						guard let serverBase45 = json["certificate"] as? String else {
							return
						}
						
						let result = self.healthCertificateService.registerHealthCertificate(base45: serverBase45)
						switch result {
						case let .success((healthCertifiedPerson, healthCertificate)):
							self.onSuccess(healthCertifiedPerson, healthCertificate)
						case .failure(let registrationError):
							// wrap RegistrationError into an QRScannerError.other error
							self.onError?(QRScannerError.other(registrationError))
						}
					}
				} catch let error {
					print(error)
				}
			}
			task.resume()
			
		} catch let error {
			print(error)
		}
	
		
//		let payload = CountrySubmissionPayload(exposureKeys: [], visitedCountries: [], checkins: [], tan: base45, submissionType: .rapidTest)
//		HTTPClient().submit(payload: payload, isFake: false) { error in
//			print(error)
//		}
		
	}

	// MARK: - Internal

	lazy var captureSession: AVCaptureSession? = {
		#if targetEnvironment(simulator)
		return nil
		#else
		guard let currentCaptureDevice = captureDevice,
			let captureDeviceInput = try? AVCaptureDeviceInput(device: currentCaptureDevice) else {
			onError?(.cameraPermissionDenied)
			Log.error("Failed to setup AVCaptureDeviceInput", log: .ui)
			return nil
		}

		let metadataOutput = AVCaptureMetadataOutput()
		let captureSession = AVCaptureSession()
		captureSession.addInput(captureDeviceInput)
		captureSession.addOutput(metadataOutput)
		metadataOutput.metadataObjectTypes = [.qr]
		metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
		return captureSession
		#endif
	}()

	var onSuccess: (HealthCertifiedPerson, HealthCertificate) -> Void
	var onError: ((QRScannerError) -> Void)?

	var isScanningActivated: Bool {
		captureSession?.isRunning ?? false
	}

	/// get current torchMode by device state
	var torchMode: TorchMode {
		guard let device = captureDevice,
			  device.hasTorch else {
			return .notAvailable
		}
		switch device.torchMode {
		case .off:
			return .lightOff
		case .on:
			return .lightOn
		case .auto:
			return .notAvailable
		@unknown default:
			return .notAvailable
		}
	}
	func activateScanning() {
		captureSession?.startRunning()
	}

	func deactivateScanning() {
		captureSession?.stopRunning()
	}

	func toggleFlash() {
		guard let device = captureDevice,
			  device.hasTorch else {
			return
		}

		defer { device.unlockForConfiguration() }

		do {
			try device.lockForConfiguration()

			if device.torchMode == .on {
				device.torchMode = .off
			} else {
				try device.setTorchModeOn(level: 1.0)
			}

		} catch {
			Log.error(error.localizedDescription, log: .api)
		}
	}
	
	func startCaptureSession() {
		switch AVCaptureDevice.authorizationStatus(for: .video) {
		case .authorized:
			Log.info("AVCaptureDevice.authorized - enable qr code scanner", log: .qrCode)
			activateScanning()
		case .notDetermined:
			AVCaptureDevice.requestAccess(for: .video) { [weak self] isAllowed in
				guard isAllowed else {
					self?.onError?(.cameraPermissionDenied)
					Log.error("camera requestAccess denied - stop here we can't go on", log: .ui)
					return
				}
				self?.activateScanning()
			}
		default:
			onError?(.cameraPermissionDenied)
			Log.info(".cameraPermissionDenied - stop here we can't go on", log: .ui)
		}
	}

	#if DEBUG

	#endif

	// MARK: - Private

	private let healthCertificateService: HealthCertificateService
	private let captureDevice: AVCaptureDevice?
}
