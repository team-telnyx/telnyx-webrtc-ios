//
//  Params.swift
//  TelnyxRTC
//
//  Created by Isaac Akakpo on 19/10/2023.
//

import Foundation


struct CustomHeaderData:Codable{
    let jsonrpc:String
    let method:String
    let params:Params
}

struct Params: Codable {
    let dialogParams: DialogParams
}

struct DialogParams: Codable {
    let custom_headers: [XHeader]
}

struct XHeader: Codable {
    let name: String
    let value: String
}

func appendCustomHeaders(customHeaders:[String:String]) -> [Any] {
    var xHeaders = [Any]()
    customHeaders.keys.forEach { key in
        var header = [String:String]()
        header["name"] = key
        header["value"] = customHeaders[key]
        xHeaders.append(header)
    }
    return xHeaders
}
