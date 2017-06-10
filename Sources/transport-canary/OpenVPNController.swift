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
    var verbosity = 6
    
    let authFilePath = "Resources/auth.up"
    let certFilePath = "Resources/keys/ca.crt"
    let keyFilePath = "Resources/keys/Wdc.key"
    
    init()
    {
        //
    }
    
    func killAllOpenVPN()
    {
        print("******* ☠️KILLALL CALLED☠️ *******")
        
        let killTask = Process()
        
        //The launchPath is the path to the executable to run.
        killTask.launchPath = "/usr/bin/killall"
        //Arguments will pass the arguments to the executable, as though typed directly into terminal.
        killTask.arguments = ["openvpn"]
        
        //Go ahead and launch the process/task
        killTask.launch()
        
        killTask.waitUntilExit()
        sleep(2)
    }
    
    func startOpenVPN(openVPNFilePath: String, configFilePath: String)
    {
        //writeToLog(logDirectory: appDirectory, content: "******* STARTOPENVPN CALLED *******")
        print("******* STARTOPENVPN CALLED *******")
        //Arguments
        let openVpnArguments = connectToOpenVPNArguments(configFilePath: configFilePath)
        //print("👀 Start OpenVPN Args:\n \(openVpnArguments.joined(separator: "\n")) 👀")
        
        _ = runOpenVpnScript(openVPNFilePath, logDirectory: configFilePath, arguments: openVpnArguments)
        
        sleep(3)
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
        
        killAllOpenVPN()
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
        //writeToLog(logDirectory: appDirectory, content: "Run OpenVpn Script")
        
        //Creates a new Process and assigns it to the connectTask property.
        OpenVPNController.connectTask = Process()
        //The launchPath is the path to the executable to run.
        OpenVPNController.connectTask.launchPath = path
        //Arguments will pass the arguments to the executable, as though typed directly into terminal.
        OpenVPNController.connectTask.arguments = arguments
        
        //Go ahead and launch the process/task
        OpenVPNController.connectTask.launch()
        
        //This may be a lie :(
        return true
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
