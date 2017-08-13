//
//  TestResult.swift
//  transport-canary
//
//  Created by Adelita Schule on 6/5/17.
//
//

import Foundation

struct TestResult
{
    ///The name of the server we ran the test on. Derived from the config file name.
    var serverName: String
    
    ///The date the test was run.
    var testDate: Date
    
    ///The transport that was tested.
    var transport: String
    
    //Whether or not the test succeeded.
    var success = false
    
    ///The server's ASN based on whois query.
    var probeASN: String
    
    ///The country code for the server.
    var probeCC: String
}

