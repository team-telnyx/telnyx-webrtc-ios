import UIKit

class SipCredentialsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var credentialsList: [SipCredential] = []
    
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
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SipCredentialCell")
    }
    
    private func loadCredentials() {
        // Fetch credentials for the current environment
        credentialsList = SipCredentialsManager.shared.getCredentials()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension SipCredentialsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return credentialsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SipCredentialCell", for: indexPath)
        let credential = credentialsList[indexPath.row]
        
        // Configure the cell
        cell.textLabel?.text = "User: \(credential.username)"
        cell.detailTextLabel?.text = "Password: \(credential.password)"
        cell.selectionStyle = .none
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SipCredentialsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCredential = credentialsList[indexPath.row]
        print("Selected User: \(selectedCredential.username)")
    }
}
