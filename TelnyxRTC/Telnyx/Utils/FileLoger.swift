//
//  FileLoger.swift
//  TelnyxRTC
//
//  Created by Isaac Akakpo on 07/03/2024.
//

import Foundation

public class FileLogger {
    public static let shared = FileLogger()
    
    static var isCallFromPush = false
    
    private var logFileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("appLog2.txt")
    }
    
    public func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
        let logMessage = "\(timestamp): \(message)\n\n\n\n"
        appendTextToFile(text: logMessage, fileURL: logFileURL)
    }
    
    private func appendTextToFile(text: String, fileURL: URL) {
        if(!FileLogger.isCallFromPush){
            return
        }
        do {
            // If the file does not exist, create it
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                try text.write(to: fileURL, atomically: true, encoding: .utf8)
            } else {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle.seekToEndOfFile()
                if let data = text.data(using: .utf8) {
                    fileHandle.write(data)
                }
                
                fileHandle.closeFile()
            }
        } catch {
            Logger.log.e(message: "FileLogger :: Error writing to log file: \(error)")
        }
    }
    
    func emptyFile() {
        do {
            // Check if the file exists at the specified URL
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                // Try to delete the file
                try FileManager.default.removeItem(at: logFileURL)
                Logger.log.i(message: "Log file successfully deleted.")
            } else {
                Logger.log.i(message: "Log file does not exist.")
            }
        } catch {
            // Handle any errors that may occur during file deletion
            Logger.log.e(message: "Failed to delete log file: \(error.localizedDescription)")
        }
    }
    
    func checkIfLogFileNotEmpty() -> Bool {
            let fileManager = FileManager.default
            let filePath = logFileURL.path
            
            // Check if file exists
            if fileManager.fileExists(atPath: filePath) {
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: filePath)
                    
                    // Check if file size is greater than zero
                    if let fileSize = attributes[.size] as? NSNumber, fileSize.intValue > 0 {
                        return true // File is not empty
                    } else {
                        return false // File is empty
                    }
                } catch {
                    Logger.log.e(message: "FileLogger :: Error checking log file size:  \(error)")
                    return false
                }
            } else {
                return false // File does not exist
            }
    }
    
    func sendLogFile() {
        let url = URL(string: "https://file_logger_endpoint")! // Change to your server's URL
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        Logger.log.i(message: "FileLogger :: Sending file to ")

        let logFileURL = FileLogger.shared.logFileURL
        guard let logData = try? Data(contentsOf: logFileURL) else {
            Logger.log.e(message: "Failed to read log file")
            return
        }

        /*
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"logFile\"; filename=\"\(logFileURL.lastPathComponent + timestamp).txt\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: text/plain\r\n\r\n".data(using: .utf8)!)
        body.append(logData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
    
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Logger.log.e(message:"FileLogger :: Error sending log file: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                Logger.log.i(message:"FileLogger:: Log file successfully uploaded \(String(describing: response))")

            } else {
                Logger.log.e(message:"FileLogger:: Error From Server \(String(describing: response))")
            }
        }.resume()
         */
    }

}

