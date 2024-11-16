import UIKit

class SipCredentialsViewController: UIViewController {
        
    @IBOutlet weak var tableView: UITableView!
    
    init() {
        super.init(nibName: "SipCredentialsViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Additional setup if needed
    }
}

extension SipCredentialsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    
}
