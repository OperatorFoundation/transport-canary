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
        //Keys
        
        //Config File
        let configPath = configDirectoryPath + "/\(configFileName)"
        
        /// OpenVPN
        OpenVPNController.sharedInstance.startOpenVPN(openVPNFilePath: openVPNExecutablePath, configFilePath: configPath)
        
        ///ShapeShifter
        
        ///Connection Test
        
        ///Generate Test Result
        
        let result = TestResult.init(serverName: serverName, success: true)
        return result

    }

}

class ConnectionTest
{
    
}
