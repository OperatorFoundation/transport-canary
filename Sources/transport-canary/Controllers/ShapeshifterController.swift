//
//  ShapeshifterController.swift
//  transport-canary
//
//  Created by Adelita Schule on 6/5/17.
//
//

import Foundation

class ShapeshifterController
{
    private var launchTask: Process?
    let ptServerPort = "1234"
    let serverIPFilePath = "Resources/serverIP"
    let obfs4OptionsPath = "Resources/obfs4.json"
    let stateDirectoryPath = "TransportState"
    static let sharedInstance = ShapeshifterController()
    
    func launchShapeshifterClient()
    {
        if let arguments = shapeshifterArguments()
        {
            //print("👀 LaunchShapeShifterDispatcher Args:\n \(arguments.joined(separator: "\n")) 👀")
            
            if launchTask == nil
            {
                //Creates a new Process and assigns it to the launchTask property.
                launchTask = Process()
            }
            else
            {
                launchTask!.terminate()
                launchTask = Process()
            }
            
            //The launchPath is the path to the executable to run.
            launchTask!.launchPath = "Resources/shapeshifter-dispatcher"
            launchTask!.arguments = arguments
            launchTask!.launch()
        }
        else
        {
            print("Could not create/find the transport state directory path, which is required.")
        }
    }
    
    func stopShapeshifterClient()
    {
        if launchTask != nil
        {
            launchTask?.terminate()
            launchTask?.waitUntilExit()
            launchTask = nil
        }
    }
    
    func killAllShShifter()
    {
        print("******* ☠️KILLALL ShShifters CALLED☠️ *******")
        
        let killTask = Process()
        
        //The launchPath is the path to the executable to run.
        killTask.launchPath = "/usr/bin/killall"
        //Arguments will pass the arguments to the executable, as though typed directly into terminal.
        killTask.arguments = ["shapeshifter-dispatcher"]
        
        //Go ahead and launch the process/task
        killTask.launch()
        
        killTask.waitUntilExit()
    }
    
    func shapeshifterArguments() -> [String]?
    {
        if let stateDirectory = createTransportStateDirectory(), let obfs4Options = getObfs4Options()
        {
            do
            {
                let serverIP = try String(contentsOfFile: serverIPFilePath, encoding: String.Encoding.ascii)
                
                //List of arguments for Process/Task
                var processArguments: [String] = []
                
                //TransparentTCP is our proxy mode.
                processArguments.append("-transparent")
                
                //Puts Dispatcher in client mode.
                processArguments.append("-client")
                
                //IP and Port for our PT Server
                processArguments.append("-target")
                processArguments.append("\(serverIP):\(ptServerPort)")
                
                //Here is our list of transports (more than one would launch multiple proxies)
                processArguments.append("-transports")
                processArguments.append("obfs4")
                
                /// -bindaddr string
                //Specify the bind address for transparent server
                processArguments.append("-bindaddr")
                processArguments.append("obfs4-127.0.0.1:1234")
                
                //Paramaters needed by the specific transport being used (obfs4)
                processArguments.append("-options")
                processArguments.append(obfs4Options)
                
                //Creates a directory if it doesn't already exist for transports to save needed files
                processArguments.append("-state")
                processArguments.append(stateDirectory)
                
                /// -logLevel string
                //Log level (ERROR/WARN/INFO/DEBUG) (default "ERROR")
                processArguments.append("-logLevel")
                processArguments.append("DEBUG")
                
                //Log to TOR_PT_STATE_LOCATION/dispatcher.log
                processArguments.append("-enableLogging")
                
                /// -ptversion string
                //Specify the Pluggable Transport protocol version to use
                //We are using Pluggable Transports version 2.0
                processArguments.append("-ptversion")
                processArguments.append("2")
                
                //TODO Listen on a port for OpenVPN Client
                
                return processArguments
            }
            catch
            {
                print("Unable to locate the server IP.")
                return nil
            }
            
        }
        else
        {
            return nil
        }
        
    }
    
    func getObfs4Options() -> String?
    {
        do
        {
            let obfs4OptionsData = try Data(contentsOf: URL(fileURLWithPath: obfs4OptionsPath, isDirectory: false), options: .uncached)
            let obfs4Options = String(data: obfs4OptionsData, encoding: String.Encoding.ascii)
            return obfs4Options
        }
        catch
        {
            print("⁉️ Unable to locate the needed obfs4 options ⁉️.")
            return nil
        }
    }
    
    func createTransportStateDirectory() ->String?
    {
        do
        {
            try FileManager.default.createDirectory(atPath: stateDirectoryPath, withIntermediateDirectories: true, attributes: nil)
            return stateDirectoryPath
        }
        catch let queueDirError
        {
            print(queueDirError)
            return nil
        }
     }
    
}
