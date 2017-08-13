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
            var successfulTests = [TestResult]()
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
    
    func reportToOoni(testResult: TestResult)
    {
        //Create a new report:
        let newReport = OoniNewReportRequest(testResult: testResult)
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
