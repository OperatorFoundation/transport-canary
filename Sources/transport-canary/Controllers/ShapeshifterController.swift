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
    let shsocksServerPort = "2345"
    let serverIPFilePath = "Resources/serverIP"
    let shSocksServerIPFilePath = "Resources/shSocksServerIP"
    let obfs4OptionsPath = "Resources/obfs4.json"
    let meekOptionsPath = "Resources/meek.json"
    let shSocksOptionsPath = "Resources/shadowsocks.json"
    let stateDirectoryPath = "TransportState"
    static let sharedInstance = ShapeshifterController()
    
    func launchShapeshifterClient(forTransport transport: String)
    {
        if let arguments = shapeshifterArguments(forTransport: transport)
        {
            print("👀 LaunchShapeShifterDispatcher Args:\n \(arguments))")
            
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
        print("******* ☠️ KILLALL ShShifters CALLED ☠️ *******")
        
        let killTask = Process()
        
        //The launchPath is the path to the executable to run.
        killTask.launchPath = "/usr/bin/killall"
        //Arguments will pass the arguments to the executable, as though typed directly into terminal.
        killTask.arguments = ["shapeshifter-dispatcher"]
        
        //Go ahead and launch the process/task
        killTask.launch()
        
        killTask.waitUntilExit()
    }
    
    func shapeshifterArguments(forTransport transport: String) -> [String]?
    {
        if let stateDirectory = createTransportStateDirectory()
        {
            var options: String?
            
            do
            {
                let serverIP = try String(contentsOfFile: serverIPFilePath, encoding: String.Encoding.ascii).replacingOccurrences(of: "\n", with: "")
                
                //List of arguments for Process/Task
                var processArguments: [String] = []
                
                //TransparentTCP is our proxy mode.
                processArguments.append("-transparent")
                
                //Puts Dispatcher in client mode.
                processArguments.append("-client")
                
                if transport == meek
                {
                    options = getMeekOptions()
                }
                else if transport == obfs4
                {
                    options = getObfs4Options()
                    
                    //IP and Port for our PT Server
                    processArguments.append("-target")
                    processArguments.append("\(serverIP):\(ptServerPort)")
                }
                else if transport == shadowsocks
                {
                    options = getShadowSocksOptions()
                    
                    //If shSocks use special port and IP
                    do
                    {
                        let shSocksServerIP = try String(contentsOfFile: shSocksServerIPFilePath, encoding: String.Encoding.ascii).replacingOccurrences(of: "\n", with: "")
                        processArguments.append("-target")
                        processArguments.append("\(shSocksServerIP):\(shsocksServerPort)")
                    }
                    catch
                    {
                        print("Could not run shadow socks test: Could not find server IP.")
                        return nil
                    }
                }
                
                if options == nil
                {
                    //Something's wrong, let's get out of here.
                    return nil
                }
                
                //Here is our list of transports (more than one would launch multiple proxies)
                processArguments.append("-transports")
                
                if transport == shadowsocks
                {
                    processArguments.append("shadow")
                }
                else
                {
                    processArguments.append(transport)
                }
                
                //This should use generic options based on selected transport
                //Paramaters needed by the specific transport being used
                processArguments.append("-options")
                processArguments.append(options!)
                
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
    
    func getMeekOptions() -> String?
    {
        do
        {
            let meekOptionsData = try Data(contentsOf: URL(fileURLWithPath: meekOptionsPath, isDirectory: false), options: .uncached)
            let rawOptions = String(data: meekOptionsData, encoding: String.Encoding.ascii)
            let meekOptions = rawOptions?.replacingOccurrences(of: "\n", with: "")
            return meekOptions
        }
        catch
        {
            print("⁉️ Unable to locate the needed meek options ⁉️.")
            return nil
        }
    }
    
    func getObfs4Options() -> String?
    {
        do
        {
            let obfs4OptionsData = try Data(contentsOf: URL(fileURLWithPath: obfs4OptionsPath, isDirectory: false), options: .uncached)
            let rawOptions = String(data: obfs4OptionsData, encoding: String.Encoding.ascii)
            let obfs4Options = rawOptions?.replacingOccurrences(of: "\n", with: "")
            return obfs4Options
        }
        catch
        {
            print("⁉️ Unable to locate the needed obfs4 options ⁉️.")
            return nil
        }
    }
    
    func getShadowSocksOptions() -> String?
    {
        do
        {
            let shSocksOptionsData = try Data(contentsOf: URL(fileURLWithPath: shSocksOptionsPath, isDirectory: false) , options: .uncached)
            let rawOptions = String(data: shSocksOptionsData, encoding: String.Encoding.ascii)
            let shSocksOptions = rawOptions?.replacingOccurrences(of: "\n", with: "")
            return shSocksOptions
        }
        catch
        {
            print("⁉️ Unable to locate the needed shadowsocks options ⁉️.")
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
