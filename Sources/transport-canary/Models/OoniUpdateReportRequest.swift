//
//  OoniUpdateReportRequest.swift
//  transport-canary
//
//  Created by Adelita Schule on 7/10/17.
//
//

import Foundation

class OoniUpdateReportRequest
{
    let contentKey = "content"
    let formatKey = "format"
    

    //var content: Dictionary <String, Any>
    //`string` or `document` content to be added to the report. This can be one or more
    //report entries in the format specified in df-000-base.md
    //When in format YAML this is the content of the report to be added as a
    //string serialised in YAML, when in JSON it's the actual JSON document of the report entry.
    
    var format: String = "json"
    //`string` that must be either "json" or "yaml" to identify the format of the content.
    
    var requestDictionary: Dictionary <String, Any>

    
    init(success: Bool)
    {
        var testStatus: String
        
        if success
        {
            testStatus = "successful"
        }
        else
        {
            testStatus = "failed"
        }
        let reqDictionary: Dictionary <String, Any> = [contentKey: testStatus,
                                                       formatKey: format]
        
        requestDictionary = reqDictionary
    }
    
}
