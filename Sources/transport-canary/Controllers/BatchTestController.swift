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
    
//    func runAllTests(forTransport transport: String)
//    {
//        //AdversaryLabController.sharedInstance.launchAdversaryLab(forTransport: transport)
//        
//        //Kills all openVPN connections on the system before begining the test loop.
//        if OpenVPNController.sharedInstance != nil
//        {
//            killAll(processToKill: "openvpn")
//        }
//        
//        //Run this with a tester that has a nil config file
//        //We want to know if our transport server is working before getting oVPN involved and running a whole batch of tests.
//        let controlTester = ConnectionTester.init(configFileName: nil)
//        controlTester.runTest(forTransport: transport)
//        {
//            (maybeResult) in
//            
//            if let controlTestResult = maybeResult
//            {
//                //Only proceed if the control test was successful.
//                if controlTestResult.success
//                {
//                    do
//                    {
//                        try configs.forEachEntry(closure:
//                        {
//                            config in
//                            
//                            //                if first
//                            //                {
//                            //                    first = false
//                            //                }
//                            //                else
//                            //                {
//                            //                    return
//                            //                }
//                            
//                            let tester = ConnectionTester.init(configFileName: config)
//                            tester.runTest(forTransport: transport, completion:
//                            {
//                                (maybeTestResult) in
//                                
//                                if let testResult = maybeTestResult
//                                {
//                                    let addRecordSuccess = DatabaseController.sharedInstance.insert(testResult: testResult)
//                                    
//                                    print("Added to database = \(addRecordSuccess)")
//                                    
//                                    //Ooni Reporting
//                                    self.reportToOoni(testResult: testResult)
//                                    
//                                    
//                                    if testResult.success
//                                    {
//                                        print("⭐️Test succeeded for \(testResult.serverName) using \(testResult.transport)⭐️")
//                                    }
//                                    else if testResult.success == false
//                                    {
//                                        print("👉 \(testResult.serverName) ")
//                                        print("☠️ Failed the test for \(testResult.transport) ☠️")
//                                        
//                                    }
//                                }
//                                else
//                                {
//                                    print("👿The following server could not be tested👿:\n\(config))")
//                                }
//                            })
//                        })
//                        
//                        DatabaseController.sharedInstance.queryForServerInfo()
//                    }
//                    catch
//                    {
//                        print(error)
//                    }
//                }
//                else
//                {
//                    print("Will not test for \(transport) as there was a problem running the test locally.")
//                }
//            }
//        }
//        
//    }
    
    func runAllTests(forTransport transport: String)
    {
        //Kills all openVPN connections on the system before begining the test loop.
        if OpenVPNController.sharedInstance != nil
        {
            killAll(processToKill: "openvpn")
        }
        
        var failedTests = [TestResult]()
        var successfulTests = [TestResult]()
        var serversNotTested = [String]()
        
        //Run this with a tester that has a nil config file
        //We want to know if our transport server is working before getting oVPN involved and running a whole batch of tests.
        let controlTester = ConnectionTester.init(configFileName: nil)
        if let controlTestResult = controlTester.runTest(forTransport: transport)
        {
//            //Only proceed if the control test was successful.
//            if controlTestResult.success
//            {
                AdversaryLabController.sharedInstance.launchAdversaryLab(forTransport: transport)
            
                do
                {
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
                            let addRecordSuccess = DatabaseController.sharedInstance.insert(testResult: testResult)
                            
                            print("Added to database = \(addRecordSuccess)")
                            
                            //Ooni Reporting
                            reportToOoni(testResult: testResult)
                            
                            
                            if testResult.success
                            {
                                successfulTests.append(testResult)
                            }
                            else if testResult.success == false
                            {
                                failedTests.append(testResult)
                            }
                        }
                        else
                        {
                            serversNotTested.append(config)
                        }
                        
                    })
                    
                    if serversNotTested.isEmpty
                    {
                        print("⭐️  All available servers have been tested. ⭐️")
                    }
                    else
                    {
                        print("👿  The following servers could not be tested 👿  :\n\(serversNotTested.joined(separator: "\n👉"))")
                    }
                    
                    if failedTests.isEmpty
                    {
                        print("💫  All tests have succeeded! 💫")
                    }
                    else
                    {
                        print("☠️  The following servers failed the test ☠️  :")
                        for test in failedTests
                        {
                            print("👉  \(test.serverName) for \(test.transport)")
                        }
                    }
                    
                    DatabaseController.sharedInstance.queryForServerInfo()
                }
                catch
                {
                    print(error)
                }
            
                AdversaryLabController.sharedInstance.stopAdversaryLab()
//            }
//            else
//            {
//                print("Will not test for \(transport) as there was a problem running the test locally.")
//            }
        }
    }
    
    func reportToOoni(testResult: TestResult)
    {
        //Create a new report:
        if let newReport = OoniNewReportRequest(testResult: testResult)
        {
            OoniReportingController.sharedInstance.createOoniReport(requestDictionary: newReport.requestDictionary, completionHandler:
            {
                (maybeResponse) in
                
                if let newReportResponse = maybeResponse
                {
                    //Add our new report ID to the database record.
                    let addedReportID = DatabaseController.sharedInstance.insert(ooniReportID: newReportResponse.reportID, serverName: testResult.serverName)
                    
                    if addedReportID
                    {
                        print("😎 😎 😎  Updated test result record with a new Ooni report ID. 😎 😎 😎")
                    }
                    else
                    {
                        print("Tried to add a report ID and failed")
                    }
                    
                    //Update the report with the result of the test:
                    let updateReportRequest = OoniUpdateReportRequest(success: testResult.success)
                    
                    OoniReportingController.sharedInstance.updateOoniReport(reportID: newReportResponse.reportID, requestDictionary: updateReportRequest.requestDictionary, completionHandler:
                    {
                        (maybeResponseDictionary) in
                        
                        if let responseDictionary = maybeResponseDictionary
                        {
                            if let status = responseDictionary["status"] as? String
                            {
                                if status == "success"
                                {
                                    print("Updated Ooni response with test status!")
                                    
                                    //Close the report:
                                    OoniReportingController.sharedInstance.closeOoniReport(reportID: newReportResponse.reportID, completionHandler:
                                    {
                                        (maybeCloseResponseDictionary) in
                                        
                                        if let closeResponseDictionary = maybeCloseResponseDictionary
                                        {
                                            //TODO: Update DB
                                            print("Close Ooni Report response: \(closeResponseDictionary)")
                                            var closed = false
                                            
                                            let addedReportStatusToDB = DatabaseController.sharedInstance.insert(reportClosedStatus: closed, serverName: testResult.serverName)
                                            
                                            if addedReportStatusToDB
                                            {
                                                print("Saved report status to the database!")
                                            }
                                            else
                                            {
                                                print("Unable to save report status to the database.")
                                            }
                                        }
                                    })
                                }
                                else
                                {
                                    print("Unable to update Ooni response with test status. Request status = \(status)")
                                }
                            }
                        }
                    })
                }
            })
        }
    }
    
    
}
