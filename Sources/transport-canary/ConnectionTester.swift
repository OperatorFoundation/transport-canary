//
//  ConnectionTester.swift
//  transport-canary
//
//  Created by Adelita Schule on 6/5/17.
//
//

import Foundation

class ConnectionTester
{
    let configDirectoryPath = "Resources/config"
    let openVPNExecutablePath = "Resources/openvpn"
    var serverName: String = "Local Test"
    var configFileName: String?
    
    init(configFileName: String?)
    {
        if let configFileName = configFileName
        {
            self.configFileName = configFileName
            self.serverName = configFileName.replacingOccurrences(of: "-tcp.ovpn", with: "")
            if let country = DatabaseController.sharedInstance.queryForServerCountry(serverName: self.serverName)
            {
                let flag = country.emojiFlag
                print("\(flag) \(flag) \(flag) \(flag)  Testing \(self.serverName) \(flag) \(flag) \(flag) \(flag)")
            }
            else
            {
                print("💥💥💥💥💥💥  Testing \(self.serverName) 💥💥💥💥💥")
                print("IS YOUR DATABASE RUNNING???")
            }
        }
    }
    
//    func runTest(forTransport transport: String) -> (_ maybeTestResult: TestResult?) -> Void)
//    {
//        var result: TestResult?
//        
//        //If no config file run this without launching or cleaning up openvpn
//        if configFileName != nil
//        {
//            //Config File
//            let configPath = configDirectoryPath + "/\(configFileName!)"
//            
//            /// OpenVPN
//            if OpenVPNController.sharedInstance != nil
//            {
//                let connectedToOVPN = OpenVPNController.sharedInstance!.startOpenVPN(openVPNFilePath: self.openVPNExecutablePath, configFilePath: configPath)
//                
//                if connectedToOVPN
//                {
//                    ///ShapeShifter
//                    ShapeshifterController.sharedInstance.launchShapeshifterClient(forTransport: transport)
//                    
//                    sleep(1)
//                    
//                    var probeASN: String?
//                    var probeCC = ""
//                    
//                    if let ipString = String(data: OpenVPNController.sharedInstance!.lastIP, encoding: String.Encoding.utf8)
//                    {
//                        //Probe ASN is a required field for Ooni reporting.
//                        if let (asn, cc) = getProbeInfo(ipString: ipString, severName: serverName) as? (String, String)
//                        {
//                            probeASN = asn
//                            probeCC = cc
//                        }
//                        else
//                        {
//                            print("Unable to get probe ASN")
//                            
//                            ///Generate Test Result
//                            if let country = DatabaseController.sharedInstance.queryForServerCountry(serverName: self.serverName)
//                            {
//                                probeCC = country.code
//                            }
//                            else
//                            {
//                                print("FAILED TO GET COUNTRY CODE, IS THE DATABASE RUNNING?")
//                            }
//                        }
//                        
//                        ///Connection Test
//                        let connectionTest = ConnectionTest()
//                        connectionTest.run(completion:
//                        {
//                            (success) in
//                            
//                            result = TestResult.init(serverName: self.serverName, testDate: Date(), transport: transport, success: success, probeASN: probeASN, probeCC: probeCC)
//                            
//                            ///Cleanup
//                            print("🛁  🛁  🛁  🛁  Cleanup! 🛁  🛁  🛁  🛁")
//                            OpenVPNController.sharedInstance!.stopOpenVPN()
//                            ShapeshifterController.sharedInstance.stopShapeshifterClient()
//                            OpenVPNController.sharedInstance!.fixTheInternet()
//                            
//                            sleep(2)
//                            
//                            completion(result)
//                        })
//                    }
//                    else
//                    {
//                        print("FAILED TO RUN TEST:")
//                        print("Unable to get probe ASN - unable to resolve server IP")
//                        completion(result)
//                    }
//                }
//                else
//                {
//                    print("Failed to connect to openVPN")
//                    completion(result)
//                }
//            }
//        }
//        else
//        {
//            //This is a test to verify that the given transport server is running, open vpn servers are not used here
//            
//            ///ShapeShifter
//            ShapeshifterController.sharedInstance.launchShapeshifterClient(forTransport: transport)
//            
//            ///Connection Test
//            let connectionTest = ConnectionTest()
//            
//            connectionTest.run(completion:
//            {
//                (success) in
//                
//                result = TestResult.init(serverName: self.serverName, testDate: Date(), transport: transport, success: success, probeASN: "--", probeCC: "--")
//                
//                ///Cleanup
//                print("🛁  🛁  🛁  🛁  Cleanup! 🛁  🛁  🛁  🛁")
//                OpenVPNController.sharedInstance!.stopOpenVPN()
//                ShapeshifterController.sharedInstance.stopShapeshifterClient()
//                OpenVPNController.sharedInstance!.fixTheInternet()
//                
//                sleep(2)
//                
//                completion(result)
//            })
//        }
//    }
    
    func runTest(forTransport transport: String) -> TestResult?
    {
        var result: TestResult?
        
        //If no config file run this without launching or cleaning up openvpn
        if configFileName != nil
        {
            print("Testing an openVPN server.")
            //Config File
            let configPath = configDirectoryPath + "/\(configFileName!)"
            
            /// OpenVPN
            if OpenVPNController.sharedInstance != nil
            {
                let connectedToOVPN = OpenVPNController.sharedInstance!.startOpenVPN(openVPNFilePath: self.openVPNExecutablePath, configFilePath: configPath)
                
                if connectedToOVPN
                {
                    ///ShapeShifter
                    ShapeshifterController.sharedInstance.launchShapeshifterClient(forTransport: transport)
                    
                    sleep(1)
                    
                    var probeASN: String?
                    var probeCC = ""
                    
                    if let ipString = String(data: OpenVPNController.sharedInstance!.lastIP, encoding: String.Encoding.utf8)
                    {
                        //Probe ASN is a required field for Ooni reporting.
                        if let (asn, cc) = getProbeInfo(ipString: ipString, severName: serverName) as? (String, String)
                        {
                            probeASN = asn
                            probeCC = cc
                        }
                        else
                        {
                            print("Unable to get probe ASN")
                            
                            ///Generate Test Result
                            if let country = DatabaseController.sharedInstance.queryForServerCountry(serverName: self.serverName)
                            {
                                probeCC = country.code
                            }
                            else
                            {
                                print("FAILED TO GET COUNTRY CODE, IS THE DATABASE RUNNING?")
                            }
                        }
                        
                        ///Connection Test
                        let connectionTest = ConnectionTest()
                        let success = connectionTest.run()
                        
                        print("Attempted to run a connection test. Successful -> \(success)")
                        
                        result = TestResult.init(serverName: serverName, testDate: Date(), transport: transport, success: success, probeASN: probeASN, probeCC: probeCC)
                    }
                    else
                    {
                        print("FAILED TO RUN TEST:")
                        print("Unable to get probe ASN - unable to resolve server IP")
                    }
                }
                else
                {
                    print("Failed to connect to openVPN")
                }
            }
        }
        else
        {
            //This is a test to verify that the given transport server is running, open vpn servers are not used here
            print("Testing the local machine to see if \(transport) is behaving...")
            ///ShapeShifter
            ShapeshifterController.sharedInstance.launchShapeshifterClient(forTransport: transport)
            
            ///Connection Test
            let connectionTest = ConnectionTest()
            let success = connectionTest.run()
            
            result = TestResult.init(serverName: serverName, testDate: Date(), transport: transport, success: success, probeASN: "--", probeCC: "--")
        }

        ///Cleanup
        print("🛁  🛁  🛁  🛁  Cleanup! 🛁  🛁  🛁  🛁")
        OpenVPNController.sharedInstance!.stopOpenVPN()
        ShapeshifterController.sharedInstance.stopShapeshifterClient()
        OpenVPNController.sharedInstance!.fixTheInternet()
        
        sleep(5)
        
        return result
    }
    
    func getProbeInfo(ipString: String, severName: String) -> (probeASN: String?, probeCC: String?)
    {
        //Probe ASN is Fetched via whois command
        let pipe = Pipe()
        let task = Process()
        task.standardOutput = pipe
        task.launchPath = "/usr/bin/whois"
        
        var taskArguments: [String] = []
        taskArguments.append("-h")
        taskArguments.append("whois.cymru.com")
        taskArguments.append(" -v \(ipString)")
        
        task.arguments = taskArguments
        
        task.launch()
        task.waitUntilExit()
        
        let responseData = pipe.fileHandleForReading.readDataToEndOfFile()
        
        guard let responseString = String(data: responseData, encoding: String.Encoding.ascii)
            else
        {
            return (nil, nil)
        }
        
        let (_, row2) = responseString.slice("\n")
        let fieldsArray: Array = row2.components(separatedBy: "|")
        let rawASN = fieldsArray[0].replacingOccurrences(of: " ", with: "")
        let asn = "AS\(rawASN)"
        
        //Country code comes from our servers table.
        guard let country = DatabaseController.sharedInstance.queryForServerCountry(serverName: serverName)
            else
        {
            return (nil, nil)
        }
        
        return (asn, country.code)
    }

}

class ConnectionTest
{
    let testWebAddress = "http://127.0.0.1:1234/"
    let canaryString = "Yeah!\n"
    
    func run() -> Bool
    {
        var success = false
        
        //Control Data
        let controlData = canaryString.data(using: String.Encoding.utf8)
        
        if let url = URL(string: testWebAddress)
        {
            var taskData: Data?
            var taskResponse: URLResponse?
            var taskError: Error?
            
            let queue = OperationQueue()
            let op = BlockOperation(block:
            {
                print("Attempting to connect to test site...")
                
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()

                let testTask = URLSession.shared.dataTask(with: url, completionHandler:
                {
                    (maybeData, maybeResponse, maybeError) in
                    
                    taskData = maybeData
                    taskResponse = maybeResponse
                    taskError = maybeError
                    
                    dispatchGroup.leave()
                })
                
                testTask.resume()
                
                dispatchGroup.wait()
            })
            
            queue.addOperations([op], waitUntilFinished: true)
            
            if let observedData = taskData
            {
                if observedData == controlData
                {
                    print("💕 🐥 It works! 🐥 💕")
                    success = true
                }
                else
                {
                    print("🖤  We connected but the data did not match. 🖤")
                    
                    if let observedString = String(data: observedData, encoding: String.Encoding.ascii)
                    {
                        print("Here's what we got back instead: \(observedString)")
                    }
                    
                    success = true
                }
            }
            else
            {
                print("Unable to connect to test web address.")
            }
            
            if let urlResponse = taskResponse
            {
                print("Received a url response from our test web address: \(urlResponse)")
            }
            
            if let error = taskError
            {
                print("Received an error while trying to connect to our test web address: \(error)")
            }
            
            return success
        }
        else
        {
            print("Could not resolve string to url: \(testWebAddress)")
            return success
        }
    }
    
    //Check the contents of the web page and see if it is what we expected.
//    func run() -> Bool
//    {
//        //Control Data
//        let controlData = canaryString.data(using: String.Encoding.utf8)
//        
//        //Fetch a web page
//        if let url = URL(string: testWebAddress)
//        {
//            
//            do
//            {
//                //Returned Data
//                let observedData = try Data(contentsOf: url, options: .uncached)
//                
//                
//                if observedData == controlData
//                {
//                    print("💕 🐥 It works! 🐥 💕")
//                    return true
//                }
//                else
//                {
//                    print("🖤  We connected but the data did not match. 🖤")
//                    
//                    if let observedString = String(data: observedData, encoding: String.Encoding.ascii)
//                    {
//                        print("Here's what we got back instead: \(observedString)")
//                    }
//                   
//                    return false
//                }
//                
//            }
//            catch
//            {
//                print("💔  We could not connect to \(testWebAddress): \(error.localizedDescription). 💔")
//                return false
//            }
//        }
//        else
//        {
//            return false
//        }
//    }

}
