import UIKit

protocol SipCredentialsViewControllerDelegate: AnyObject {
    func onSipCredentialSelected(credential: SipCredential?)
}

class SipCredentialsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var credentialsList: [SipCredential] = []
    private var selectedCredential: SipCredential?
    private var isSelectedCredentialChanged = false

    weak var delegate: SipCredentialsViewControllerDelegate?

    
    init() {
        super.init(nibName: "SipCredentialsViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        loadCredentials()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isSelectedCredentialChanged {
            selectedCredential = SipCredentialsManager.shared.getSelectedCredential()
            delegate?.onSipCredentialSelected(credential: selectedCredential)
        }
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        // Register cell and header view
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SipCredentialCell")
        tableView.register(UISipCredentialHeaderView.self, forHeaderFooterViewReuseIdentifier: "UISipCredentialHeaderView")
        
        // Set up dynamic row height
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    private func loadCredentials() {
        credentialsList = SipCredentialsManager.shared.getCredentials()
        selectedCredential = SipCredentialsManager.shared.getSelectedCredential()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension SipCredentialsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if credentialsList.isEmpty {
            tableView.setEmptyMessage("No SIP credentials available. Credentials will appear here after using them to connect.")
        } else {
            tableView.restore()
        }
        
        return credentialsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "SipCredentialCell")
        
        guard indexPath.row < credentialsList.count else {
            return cell
        }
        
        let credential = credentialsList[indexPath.row]
        
        cell.textLabel?.text = "\(credential.username)"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        cell.selectionStyle = .none
        
        if credential.username == selectedCredential?.username {
            cell.backgroundColor = UIColor(red: 0/255, green: 192/255, blue: 139/255, alpha: 1)
            cell.textLabel?.textColor = .white
            cell.detailTextLabel?.textColor = .white
        } else {
            cell.backgroundColor = .white
            cell.textLabel?.textColor = .black
            cell.detailTextLabel?.textColor = .darkGray
        }
        
        return cell
    }

    
    // MARK: - Header View for Section
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "UISipCredentialHeaderView") as! UISipCredentialHeaderView
        let environment = UserDefaults.standard.getEnvironment().toString()
        headerView.configure(title: "SIP Credentials", subtitle: "\(environment)")
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
}

// MARK: - UITableViewDelegate
extension SipCredentialsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard indexPath.row < credentialsList.count else {
            print("Invalid index")
            return
        }
        let selectedCredential = credentialsList[indexPath.row]
        print("Selected User: \(selectedCredential.username)")
        SipCredentialsManager.shared.saveSelectedCredential(selectedCredential)
        isSelectedCredentialChanged = true
        self.dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        // Create Delete Action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completionHandler) in
            
            guard let self = self else { return }
            let deletedCredential = self.credentialsList[indexPath.row]
            
            // Remove the credential from the list
            self.credentialsList.remove(at: indexPath.row)
            
            // Update UserDefaults using the manager
            SipCredentialsManager.shared.removeCredential(username: deletedCredential.username)
            
            if self.selectedCredential?.username == deletedCredential.username {
                isSelectedCredentialChanged = true
            }
            // Delete the row with animation
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            // Indicate action completed
            completionHandler(true)
        }
        
        deleteAction.backgroundColor = .systemRed
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true
        
        return configuration
    }
}

// MARK: - Extension for UITableView Empty Message
extension UITableView {

    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = .gray
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        
        let containerView = UIView()
        containerView.addSubview(messageLabel)
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30),
            messageLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        self.backgroundView = containerView
        self.layoutIfNeeded()

    }
    
    func restore() {
        self.backgroundView = nil
    }
}
