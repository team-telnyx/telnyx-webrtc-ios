import Foundation

// MARK: - Dictionary
extension Dictionary {

    var telnyx_webrtc_json: String {
        let invalidJson = "Not a valid JSON"
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? invalidJson
        } catch {
            return invalidJson
        }
    }
    
    func printJson() {
        Logger.log.i(message: "\(telnyx_webrtc_json)")
    }
}
