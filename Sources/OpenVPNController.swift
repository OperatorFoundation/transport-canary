//
//  OpenVPNController.swift
//  transport-canary
//
//  Created by Adelita Schule on 6/1/17.
//
//

import PerfectLib

class OpenVPNController
{
    let currentServerIP = ""
    let ptServerPort = ""
    
    func shapeShifterDispatcherArguments() -> [String]?
    {
        //    if let stateDirectory = createTransportStateDirectory(), let obfs4Options = getObfs4Options()
        //    {
        //List of arguments for Process/Task
        var processArguments: [String] = []
        
        //TransparentTCP is our proxy mode.
        processArguments.append("-transparent")
        
        //Puts Dispatcher in client mode.
        processArguments.append("-client")
        
        //IP and Port for our PT Server
        processArguments.append("-target")
        processArguments.append("\(currentServerIP):\(ptServerPort)")
        
        //Here is our list of transports (more than one would launch multiple proxies)
        processArguments.append("-transports")
        processArguments.append("obfs4")
        
        /// -bindaddr string
        //Specify the bind address for transparent server
        processArguments.append("-bindaddr")
        processArguments.append("obfs4-127.0.0.1:1234")
        
        //Paramaters needed by the specific transport being used (obfs4)
        processArguments.append("-options")
        //processArguments.append(obfs4Options)
        
        //Creates a directory if it doesn't already exist for transports to save needed files
        processArguments.append("-state")
        //processArguments.append(stateDirectory)
        
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
        //    }
        //    else
        //    {
        //        return nil
        //    }
        
    }   
}
