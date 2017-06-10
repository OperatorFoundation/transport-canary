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
    var serverName: String
    var configFileName: String
    
    init(configFileName: String)
    {
        self.configFileName = configFileName
        self.serverName = configFileName.replacingOccurrences(of: "-tcp.ovpn", with: "")
    }
    
    func runTest() -> TestResult?
    {        
        //Config File
        let configPath = configDirectoryPath + "/\(configFileName)"
        
        /// OpenVPN
        OpenVPNController.sharedInstance.startOpenVPN(openVPNFilePath: openVPNExecutablePath, configFilePath: configPath)
        
        ///ShapeShifter
        ShapeshifterController.sharedInstance.launchShapeshifterClient()
        
        sleep(1)
        
        ///Connection Test
        let connectionTest = ConnectionTest()
        let success = connectionTest.run()
        
        ///Generate Test Result
        
        let result = TestResult.init(serverName: serverName, success: success)
        
        ///Cleanup
        ShapeshifterController.sharedInstance.stopShapeshifterClient()
        OpenVPNController.sharedInstance.stopOpenVPN()
        
        return result
    }

}

class ConnectionTest
{
    let testWebAddress = "http://127.0.0.1:1234/"
    let canaryString = "Yeah!\n"

    init()
    {
        //
    }
    
    //Check the contents of the web page and see if it is what we expected.
    func run() -> Bool
    {
        //Control Data
        let controlData = canaryString.data(using: String.Encoding.utf8)
        
        //Fetch a web page
        if let url = URL(string: testWebAddress)
        {
            do
            {
                //Returned Data
                let observedData = try Data(contentsOf: url, options: .uncached)
                
                if observedData == controlData
                {
                    print("💕🐥It works!🐥💕")
//                    let observedString = String(data: observedData, encoding: String.Encoding.utf8)
//                    print("Observed Data: \(observedString!)")
//                    
//                    let controlString = String(data: controlData!, encoding: String.Encoding.utf8)
//                    print("Control Data: \(controlString!)")
                    
                    return true
                }
                else
                {
                    print("We connected but the data did not match.🖤")
                    return false
                }
                
            }
            catch
            {
                print("We could not connect.💔")
                return false
            }
        }
        else
        {
            return false
        }
        
    }
}
