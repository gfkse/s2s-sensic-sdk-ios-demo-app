import UIKit

protocol BaseViewControllerDelegate: AnyObject {
    func setPlayerRate(with value: Float?)
}
protocol BaseViewControllerDelegateDate: AnyObject {
    func setDate(with dateString: String)
}

class BaseViewController: UIViewController {
    private var datePicker: UIDatePicker?
    private var dateString = ""
    weak var delegate: BaseViewControllerDelegate?
    weak var dateDelegate: BaseViewControllerDelegateDate?
    
    var optIn: Bool {
        get {
            let defaults = UserDefaults.standard
            return defaults.bool(forKey: "optin")
        }
    }
    
    lazy var gradient: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.type = .axial
        gradient.colors = [
            UIColor.black.cgColor,
            UIColor.white.cgColor
        ]
        gradient.locations = [0.5, 1]
        return gradient
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBarGradient()
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at:0)
        
        let crashBarButtonItem = UIBarButtonItem(title: "Crash", style: .done, target: self, action: #selector(crashButtonTapped))
        self.navigationItem.rightBarButtonItem = crashBarButtonItem
        self.navigationItem.rightBarButtonItem?.tintColor = .red
    }
    
    @objc func crashButtonTapped() {
        fatalError("Crashing Demo app Test")
    }
    
    //MARK: NavigationBar
    
    private func setNavigationBarGradient() {
        if let navigationBar = self.navigationController?.navigationBar {
            let gradient = CAGradientLayer()
            var bounds = navigationBar.bounds
            bounds.size.height += UIApplication.shared.statusBarFrame.size.height
            gradient.frame = bounds
            gradient.colors = [UIColor.orange.cgColor, UIColor.red.cgColor]
            gradient.startPoint = CGPoint(x: 0, y: 0)
            gradient.endPoint = CGPoint(x: 1, y: 0)
            
            if let image = getImageFrom(gradientLayer: gradient) {
                navigationBar.setBackgroundImage(image, for: UIBarMetrics.default)
            }
        }
    }
    
    private func getImageFrom(gradientLayer:CAGradientLayer) -> UIImage? {
        var gradientImage:UIImage?
        UIGraphicsBeginImageContext(gradientLayer.frame.size)
        if let context = UIGraphicsGetCurrentContext() {
            gradientLayer.render(in: context)
            gradientImage = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: UIEdgeInsets.zero, resizingMode: .stretch)
        }
        UIGraphicsEndImageContext()
        
        return gradientImage
    }
    
    func setNavigationBarTitle(title: String) {
        self.title = title
    }
    
    func showChangeSpeedAlert() {
        let alert = UIAlertController(title: "Speed", message: nil, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "0.5x", style: UIAlertAction.Style.default, handler: changePlaybackSpeed))
        alert.addAction(UIAlertAction(title: "1.0x", style: UIAlertAction.Style.default, handler: changePlaybackSpeed))
        alert.addAction(UIAlertAction(title: "1.5x", style: UIAlertAction.Style.default, handler: changePlaybackSpeed))
        alert.addAction(UIAlertAction(title: "2.0x", style: UIAlertAction.Style.default, handler: changePlaybackSpeed))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc private func changePlaybackSpeed(alert: UIAlertAction) {
        guard let input =  alert.title?.dropLast() else {
            return
        }
        
        delegate?.setPlayerRate(with: Float(input))
    }
    func createToolBar() -> UIToolbar {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(donePressed))
        toolBar.setItems([doneButton], animated: true)
        
        return toolBar
    }
    
    func createDatePicker(for textField: UITextField) {
        datePicker = UIDatePicker()
        if #available(iOS 13.4, *) {
            datePicker?.preferredDatePickerStyle = .wheels
        } else {
            // Fallback on earlier versions
        }
        
        textField.attributedPlaceholder = NSAttributedString(
            string: "Select Date for Time Shift",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white]
        )
        textField.inputView = datePicker
        textField.inputAccessoryView = createToolBar()
    }
    
    @objc func donePressed() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateString = dateFormatter.string(from: datePicker?.date ?? Date())
        dateString = dateString + "+0100"
        dateDelegate?.setDate(with: dateString)
        self.view.endEditing(true)
    }
    
    func getStreamStart() -> String {
        return dateString
    }
}
