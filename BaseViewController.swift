import UIKit

protocol BaseViewControllerDelegate: AnyObject {
    func setPlayerRate(with value: Float?)
}

class BaseViewController: UIViewController {

    weak var delegate: BaseViewControllerDelegate?
    
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
}
