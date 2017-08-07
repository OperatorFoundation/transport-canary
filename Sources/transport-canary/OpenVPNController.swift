//
//  OpenVPNController.swift
//  transport-canary
//
//  Created by Adelita Schule on 6/1/17.
//
//

import PerfectLib
import Foundation

class OpenVPNController
{
    static let sharedInstance = OpenVPNController()
    static var connectTask:Process!
    static let findIPURL = URL(string: "https://api.ipify.org/?format=text")!
    
    let authFilePath = "Resources/auth.up"
    let certFilePath = "Resources/keys/ca.crt"
    let keyFilePath = "Resources/keys/Wdc.key"
    let fixInternetPath = "Resources/fixInternet.sh"
    let verbosity = 6
    let originalIP: Data
    
    var lastIP: Data
    
    //Sockety Goodness Needed for connecting to management server
    //Allows us to monitor the state of our connection through OpenVPN
    
    let session = URLSession(configuration: .default)
    let hostIPString = "127.0.0.1"
    let port = 13374
    var maybeSyncSocket: SyncSocket? = nil
    var socketRunning = false
    var status = String()
    
    init?()
    {
        if let fetchedIP = OpenVPNController.getCurrentIP()
        {
            originalIP = fetchedIP
            lastIP = fetchedIP
        }
        else
        {
            return nil
        }
    }
    
    static func getCurrentIP() -> Data?
    {
        do
        {
            let currentIP = try Data(contentsOf: findIPURL, options: Data.ReadingOptions.uncached)
            
            return currentIP
        }
        catch
        {
            print("Unable to get ip address from website.")
            return nil
        }
    }
    
    func fixTheInternet()
    {
        let fixTask = Process()
        fixTask.launchPath = fixInternetPath
        fixTask.launch()
        print("Attempted to fix the internet!")
        fixTask.waitUntilExit()
    }
    
    func startOpenVPN(openVPNFilePath: String, configFilePath: String) -> Bool
    {
        //writeToLog(logDirectory: appDirectory, content: "******* STARTOPENVPN CALLED *******")
        print("******* STARTOPENVPN CALLED *******")
        
        //Arguments
        let openVpnArguments = connectToOpenVPNArguments(configFilePath: configFilePath)
        
        print("OpenVPN Arguments:\n\(openVpnArguments)")

        runOpenVpnScript(openVPNFilePath, logDirectory: configFilePath, arguments: openVpnArguments)
        sleep(2)
        
        let connected = connectToManagement() && self.areWeConnected()
//        if !connected
//        {
//            self.stopOpenVPN()
//        }
        
        return connected
    }
    
    func stopOpenVPN()
    {
        print("******* STOP OpenVpn CALLED *******")
        disconnectFromManagement()
        //Disconnect OpenVPN
        if OpenVPNController.connectTask != nil
        {
            OpenVPNController.connectTask!.terminate()
            //OpenVPNController.connectTask!.waitUntilExit()
        }
        
        killAll(processToKill: "openvpn")
        
    }
    
    func areWeConnected() -> Bool
    {
        if let currentIP = OpenVPNController.getCurrentIP()
        {
            let oIPString = String(data: originalIP, encoding: String.Encoding.utf8)
            let lIPString = String(data: lastIP, encoding: String.Encoding.utf8)
            let cIPString = String(data: currentIP, encoding: String.Encoding.utf8)
            print("👉 Original IP: \(oIPString!)")
            print("👉 Last IP: \(lIPString!)")
            print("👉 Current IP: \(cIPString!)")
            
            if currentIP != originalIP && currentIP != lastIP
            {
                lastIP = currentIP
                return true
            }
            
            lastIP = currentIP
        }
        else
        {
            print("Unable to fetch current IP.")
        }
        
        return false
    }
    
    private func connectToOpenVPNArguments(configFilePath: String) -> [String]
    {
        //List of arguments for Process/Task
        var processArguments: [String] = []
        
//        //Specify the log file path
//        processArguments.append("--log")
//        processArguments.append("openVPNLog.txt")
        
        //Verbosity of Output
        processArguments.append("--verb")
        processArguments.append(String(verbosity))
        
        //Config File to use
        processArguments.append("--config")
        processArguments.append(configFilePath)
        
        //Set management options
        processArguments.append("--management")
        processArguments.append("127.0.0.1")
        processArguments.append("13374")
        processArguments.append("--management-query-passwords")
        
        //Username and Password
        processArguments.append("--auth-user-pass")
        processArguments.append(authFilePath)

        
        return processArguments
    }
    
    private func runOpenVpnScript(_ path: String, logDirectory: String, arguments: [String])
    {
        let outputPipe = Pipe()
        //Creates a new Process and assigns it to the connectTask property.
        OpenVPNController.connectTask = Process()
        
        OpenVPNController.connectTask.standardOutput = outputPipe
        //Mon Jun 26 16:07:55 2017 Initialization Sequence Completed
        
        //The launchPath is the path to the executable to run.
        OpenVPNController.connectTask.launchPath = path
        //Arguments will pass the arguments to the executable, as though typed directly into terminal.
        OpenVPNController.connectTask.arguments = arguments
        
        print("OpenVPN Arguments2:\n\(arguments)")
        print("Launch path: \(path)")
        
        //Go ahead and launch the process/task
        //OpenVPNController.connectTask.launch()
        
        do
        {
            try OpenVPNController.connectTask.launch()
        }
        catch
        {
            print("Error launching openvpn: \(error.localizedDescription)")
        }
    }
    
    func connectToManagement() -> Bool
    {
        print("Attempting to connect to management server.")
        maybeSyncSocket = SyncSocket.connect(host: hostIPString, port: port)
        guard let syncSocket = maybeSyncSocket else
        {
            return false
        }
        
        let requestString = "state\nstate on\n"
        let maybeSendError = syncSocket.send(requestString)
        if let sendError = maybeSendError
        {
            print("Error requesting state from management server: \(sendError.localizedDescription)")
        }

        var isConnected = false
        
        var maybePrefix: String?
        var eof: Bool = false
        var maybeReadError: Error?
        var maybeRest: String?

        var retryCount: Int = 0
        
        while !isConnected && !eof
        {
            //\r\n
            (maybePrefix, eof, maybeReadError, maybeRest) = syncSocket.readUntil(">STATE:", maybeRest)
            
            guard maybeReadError == nil else
            {
                print("Error reading state from management server: \(maybeReadError!.localizedDescription)")
                return false
            }
            
            if let prefix = maybePrefix
            {
                let (_, maybeRemainingString) = prefix.slice(",")
                //print("MAYBEREMAININGSTRING: \(maybeRemainingString)")
                let (maybeStatusString, _) = maybeRemainingString.slice(",")
                //print("MAYBESTATUSSTRING: \(String(describing: maybeStatusString))")
                
                
                
                if let statusString = maybeStatusString
                {
                    if statusString == "CONNECTED"
                    {
                        isConnected = true
                    }
                    else if statusString == "RECONNECTING"
                    {
                        isConnected = false
                        if retryCount > 3
                        {
                            print("Giving up on connecting to OpenVPN, received RECONNECTING status in prefix.")
                            return isConnected
                            
                        }
                        else
                        {
                            retryCount += 1
                        }
                        
                    }
                }
            }
            
            if let buffer = maybeRest
            {
                let (_, maybeRemainingString) = buffer.slice(",")
                //print("buffer -> MAYBEREMAININGSTRING: \(maybeRemainingString)")
                let (maybeStatusString, _) = maybeRemainingString.slice(",")
                //print("buffer -> MAYBESTATUSSTRING: \(String(describing: maybeStatusString))")
                
                if let statusString = maybeStatusString
                {
                    if statusString == "CONNECTED"
                    {
                        isConnected = true
                    }
                    else if statusString == "RECONNECTING"
                    {
                        isConnected = false
                        
                        if retryCount > 3
                        {
                            print("Giving up on connecting to OpenVPN, received RECONNECTING status in buffer.")
                            return isConnected
                            
                        }
                        else
                        {
                            retryCount += 1
                        }
                    }
                }
            }
        }

        return isConnected
    }
    
    func disconnectFromManagement()
    {
        if let task = maybeSyncSocket
        {
            task.close()
        }
    }

}
