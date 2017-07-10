//
//  BatchTestController.swift
//  transport-canary
//
//  Created by Adelita Schule on 6/23/17.
//
//

import Foundation

class BatchTestController
{
    static let sharedInstance = BatchTestController()
    
    func runAllTests(forTransport transport: String)
    {
        //AdversaryLabController.sharedInstance.launchAdversaryLab(forTransport: transport)
        
        do
        {
            //Kills all openVPN connections on the system before begining the test loop.
            if OpenVPNController.sharedInstance != nil
            {
               killAll(processToKill: "openvpn")
            }
            
            var failedTests = [TestResult]()
            var serversNotTested = [String]()
            
            try configs.forEachEntry(closure:
            {
                config in
                
//                if first
//                {
//                    first = false
//                }
//                else
//                {
//                    return
//                }
                
                let tester = ConnectionTester.init(configFileName: config)
                if let testResult = tester.runTest(forTransport: transport)
                {
                    let addRecordSuccess = DatabaseController.sharedInstance.insertTestResult(serverName: testResult.serverName, success: testResult.success, testDate: Date(), transport: transport)
                    
                    print("Added to database = \(addRecordSuccess)")
                    
                    if testResult.success == false
                    {
                        failedTests.append(testResult)
                    }
                }
                else
                {
                    //print("We failed (to run the test properly)!!")
                    serversNotTested.append(config)
                }
                
            })
            
            if serversNotTested.isEmpty
            {
                print("⭐️All available servers have been tested.⭐️")
            }
            else
            {
                print("👿The following servers could not be tested👿:\n\(serversNotTested.joined(separator: "\n👉"))")
            }
            
            if failedTests.isEmpty
            {
                print("💫All tests have succeeded!💫")
            }
            else
            {
                print("☠️The following servers failed the test☠️:")
                for test in failedTests
                {
                    print("👉 \(test.serverName) for \(test.transport)")
                }
            }
            
            DatabaseController.sharedInstance.queryForServerInfo()
        }
        catch
        {
            print(error)
        }
    }
}
