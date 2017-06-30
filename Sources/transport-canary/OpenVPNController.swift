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
    
    func killAllOpenVPN()
    {
        print("******* ☠️ KILLALL CALLED ☠️ *******")
        
        let killTask = Process()
        
        //The launchPath is the path to the executable to run.
        killTask.launchPath = "/usr/bin/killall"
        //Arguments will pass the arguments to the executable, as though typed directly into terminal.
        killTask.arguments = ["openvpn"]
        
        //Go ahead and launch the process/task
        killTask.launch()
        killTask.waitUntilExit()
        sleep(2)
        
        //Do it again, ovpn doesn't want to die.

        let killAgain = Process()
        killAgain.launchPath = "/usr/bin/killall"
        killAgain.arguments = ["-9", "openvpn"]
        killAgain.launch()
        killAgain.waitUntilExit()
        sleep(2)
        
        //fixTheInternet()
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
        //print("👀 Start OpenVPN Args:\n \(openVpnArguments.joined(separator: "\n")) 👀")

        sleep(2)
        
        let connected = runOpenVpnScript(openVPNFilePath, logDirectory: configFilePath, arguments: openVpnArguments)
        
        if connected == false
        {
            stopOpenVPN()
        }
        
        return connected
    }
    
    func stopOpenVPN()
    {
        //writeToLog(logDirectory: appDirectory, content: "******* STOP OpenVpn CALLED *******")
        print("******* STOP OpenVpn CALLED *******")
        
        //Disconnect OpenVPN
        if OpenVPNController.connectTask != nil
        {
            OpenVPNController.connectTask!.terminate()
            OpenVPNController.connectTask!.waitUntilExit()
        }
        
        self.killAllOpenVPN()
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
    
    private func runOpenVpnScript(_ path: String, logDirectory: String, arguments: [String]) -> Bool
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
        
        //Go ahead and launch the process/task
        OpenVPNController.connectTask.launch()
        
        sleep(13)
        
        return areWeConnected()
    }
    
//    func writeToLog(logDirectory: String, content: String)
//    {
//        let timeStamp = Date()
//        let contentString = "\n\(timeStamp):\n\(content)\n"
//        let logFilePath = logDirectory + "transport-canary-Log.txt"
//        
//        if let fileHandle = FileHandle(forWritingAtPath: logFilePath)
//        {
//            //append to file
//            fileHandle.seekToEndOfFile()
//            fileHandle.write(contentString.data(using: String.Encoding.utf8)!)
//        }
//        else
//        {
//            //create new file
//            do
//            {
//                try contentString.write(toFile: logFilePath, atomically: true, encoding: String.Encoding.utf8)
//            }
//            catch
//            {
//                print("Error writing to file \(logFilePath)")
//            }
//        }
//    }
}
