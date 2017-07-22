//
//  OoniNewReportResponse.swift
//  transport-canary
//
//  Created by Adelita Schule on 7/20/17.
//
//

import Foundation

class OoniNewReportResponse: CustomStringConvertible
{
    var backendVersion: String?
    let backendVersionKey = "backend_version"
    //`string` containing the version of the backend
    
    var reportID: String
    let reportIDKey = "report_id"
    //`string` report identifier of the format detailed below.
    
    var helperAddress: String?
    let helperAddressKey = "test_helper_address"
    //(conditional) `string` the address of a test helper that the client requested.
    
    var supportedFormats: [String]?
    let supportedFormatsKey = "supported_formats"
    //`list` of strings detailing what are the supported formats for submitted reports. Can either be "json" or "yaml".
    
    init?(responseDictionary: Dictionary <String, Any>)
    {
        guard let idString = responseDictionary[reportIDKey] as? String
        else
        {
            return nil
        }
        
        reportID = idString
        backendVersion = responseDictionary[backendVersionKey] as? String
        helperAddress = responseDictionary[helperAddressKey] as? String
        supportedFormats = responseDictionary[supportedFormatsKey] as? [String]
    }
}
