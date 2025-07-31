import UIKit
import AppTrackingTransparency

class MainViewController: BaseViewController {
    
    // MARK: - Outlets
    @IBOutlet private weak var idfaButton: UIButton!
    @IBOutlet private weak var optInSwitch: UISwitch!
    @IBOutlet private weak var tableView: UITableView!
    
    // MARK: - Properties
    private let demoSections = DemoScreensProvider.all
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        title = "S2S Demo App for iOS"
        
        let isOptedIn = UserDefaults.standard.bool(forKey: "optin")
        optInSwitch.isOn = isOptedIn
        
        if #available(iOS 14, *) {
            idfaButton.isHidden = ATTrackingManager.trackingAuthorizationStatus != .notDetermined
        } else {
            idfaButton.isHidden = true
        }
        
        tableView.layer.cornerRadius = 16
        tableView.layer.masksToBounds = true
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DemoCell")
    }
    
    // MARK: - Actions
    @IBAction private func didTapSwitchButton(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "optin")
        print("Opt-in status changed to: \(sender.isOn)")
    }
    
    @IBAction private func didTapIDFAButton(_ sender: UIButton) {
        guard #available(iOS 14, *) else {
            idfaButton.isHidden = true
            return
        }
        
        ATTrackingManager.requestTrackingAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.idfaButton.isHidden = true
                switch status {
                case .authorized:
                    print("Tracking authorized")
                case .denied:
                    print("Tracking denied")
                case .restricted:
                    print("Tracking restricted")
                case .notDetermined:
                    print("Tracking not determined")
                @unknown default:
                    print("Unknown tracking status")
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension MainViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return demoSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return demoSections[section].screens.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return demoSections[section].title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let screen = demoSections[indexPath.section].screens[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "DemoCell", for: indexPath)
        cell.textLabel?.text = screen.title
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.textColor = .white
        cell.backgroundColor = .clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let screen = demoSections[indexPath.section].screens[indexPath.row]
        let storyboard = UIStoryboard(name: screen.storyboard, bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: screen.viewControllerID)
        navigationController?.pushViewController(viewController, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = .orange // Set text color
            header.textLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        }
    }
}
