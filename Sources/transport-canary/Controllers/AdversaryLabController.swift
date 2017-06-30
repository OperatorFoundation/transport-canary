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
    private var launchTask: Process?
    
    func launchAdversaryLab(forTransport transport: String)
    {
        let arguments = ["capture", transport, "allow", "1234"]
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
        launchTask!.launchPath = "Resources/client-cli"
        launchTask!.arguments = arguments
        launchTask!.launch()
    }
    
    func stopAdversaryLab()
    {
        if launchTask != nil
        {
            launchTask?.terminate()
            launchTask?.waitUntilExit()
            launchTask = nil
        }
    }

}
