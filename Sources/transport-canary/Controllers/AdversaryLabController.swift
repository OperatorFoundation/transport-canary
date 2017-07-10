//
//  AdversaryLabController.swift
//  transport-canary
//
//  Created by Adelita Schule on 6/22/17.
//
//

import Foundation
///sudo bin/client-cli capture obfs4 allow 1234

class AdversaryLabController
{
    static let sharedInstance = AdversaryLabController()
    private var clientLaunchTask: Process?
    private var serverLaunchTask: Process?
    
    func launchAdversaryLab(forTransport transport: String)
    {
        let arguments = ["capture", transport, "allow", "1234"]
        if clientLaunchTask == nil
        {
            //Creates a new Process and assigns it to the launchTask property.
            clientLaunchTask = Process()
        }
        else
        {
            clientLaunchTask!.terminate()
            clientLaunchTask = Process()
        }
        
        //The launchPath is the path to the executable to run.
        clientLaunchTask!.launchPath = "Resources/client-cli"
        clientLaunchTask!.arguments = arguments
        clientLaunchTask!.launch()
    }
    
    func stopAdversaryLab()
    {
        if clientLaunchTask != nil
        {
            clientLaunchTask?.terminate()
            clientLaunchTask?.waitUntilExit()
            clientLaunchTask = nil
        }
        
        killAll(processToKill: "client-cli")
    }
    
    func launchAdversaryLabServer()
    {
        if serverLaunchTask == nil
        {
            //Creates a new Process and assigns it to the launchTask property.
            serverLaunchTask = Process()
        }
        else
        {
            serverLaunchTask!.terminate()
            serverLaunchTask = Process()
        }
        
        //The launchPath is the path to the executable to run.
        serverLaunchTask!.launchPath = "Resources/AdversaryLab"
        serverLaunchTask!.launch()
        print("Launched Adversary Lab Server. 👀")
    }
    
    func stopAdversaryLabServer()
    {
        if serverLaunchTask != nil
        {
            serverLaunchTask?.terminate()
            serverLaunchTask?.waitUntilExit()
            serverLaunchTask = nil
            print("Stopped Adversary Lab Server. 👀")
        }
        
        killAll(processToKill: "AdversaryLab")
    }

}
