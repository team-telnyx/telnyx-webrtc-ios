import Foundation

let url = URL(string: "wss://rtc.telnyx.com")!
print("Full URL: \(url)")
print("Host: \(url.host ?? "nil")")
print("Scheme: \(url.scheme ?? "nil")")
print("AbsoluteString: \(url.absoluteString)")

// Test what happens with region prefix
let regionPrefix = "eu."
let newURLString = "wss://\(regionPrefix)\(url.host ?? "")"
print("New URL with region: \(newURLString)")
