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
    
    func runTest(forTransport transport: String) -> TestResult?
    {        
        //Config File
        let configPath = configDirectoryPath + "/\(configFileName)"
        var result: TestResult?
        /// OpenVPN
        if OpenVPNController.sharedInstance != nil
        {
            let connectedToOVPN = OpenVPNController.sharedInstance!.startOpenVPN(openVPNFilePath: self.openVPNExecutablePath, configFilePath: configPath)
            
            if connectedToOVPN
            {
                ///ShapeShifter
                ShapeshifterController.sharedInstance.launchShapeshifterClient(forTransport: transport)
                
                sleep(1)
                
                if let ipString = String(data: OpenVPNController.sharedInstance!.lastIP, encoding: String.Encoding.utf8)
                {
                    //Probe ASN is a required field for Ooni reporting.
                    if let (probeASN, probeCC) = getProbeInfo(ipString: ipString) as? (String, String)
                    {
                        ///Connection Test
                        let connectionTest = ConnectionTest()
                        let success = connectionTest.run()
                        
                        ///Generate Test Result
                        result = TestResult.init(serverName: serverName, testDate: Date(), transport: transport, success: success, probeASN: probeASN, probeCC: probeCC)
                    }
                    else
                    {
                        print("FAILED TO RUN TEST:")
                        print("Unable to get probe ASN")
                    }
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
        
        ///Cleanup
        print("🛁 🛁 🛁 🛁  Cleanup! 🛁 🛁 🛁 🛁")
        OpenVPNController.sharedInstance!.stopOpenVPN()
        ShapeshifterController.sharedInstance.stopShapeshifterClient()
        OpenVPNController.sharedInstance!.fixTheInternet()
        
        sleep(5)
        
        return result
    }
    
    func getProbeInfo(ipString: String) -> (probeASN: String?, probeCC: String?)
    {
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
        
        if let responseString = String(data: responseData, encoding: String.Encoding.ascii)
        {
            let (_, row2) = responseString.slice("\n")
            let fieldsArray: Array = row2.components(separatedBy: "|")
            
            //probeASN
            let rawASN = fieldsArray[0].replacingOccurrences(of: " ", with: "")
            let asn = "AS\(rawASN)"
            
            //probeCC
            let probeCC = fieldsArray[3].replacingOccurrences(of: " ", with: "")
            return (asn, probeCC)
        }
        else
        {
            return (nil, nil)
        }
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
                    print("💕 🐥 It works! 🐥 💕")
                    return true
                }
                else
                {
                    print("We connected but the data did not match. 🖤")
                    return false
                }
                
            }
            catch
            {
                print("We could not connect. 💔")
                return false
            }
        }
        else
        {
            return false
        }
        
    }
}
