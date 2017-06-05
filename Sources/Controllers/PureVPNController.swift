//
//  PureVPNController.swift
//  transport-canary
//
//  Created by Adelita Schule on 6/5/17.
//
//

import Foundation

class PureVPNController
{
    func getPureVPNCredentials() -> (username: String, password: String)
    {
        //auth.json
        let authPath = "Resources/auth.json"
        
        do
        {
            let authData = try Data(contentsOf: URL(fileURLWithPath: authPath, isDirectory: false))
            
            //JSON
            do
            {
                let authJSON = try JSONSerialization.jsonObject(with: authData, options: .allowFragments)
                
                if let authDict = authJSON as? Dictionary <String, Any>, let username = authDict["username"] as? String
                {
                    print("Our username is: \(username)")
                }
                else
                {
                    print("Failed to parse auth json.")
                }
            }
            catch
            {
                print("Failed to get auth json.")
            }
            
        }
        catch
        {
            print("Failed to get auth data.")
        }
        
        return("", "")
    }
    
    //PerfectLib
    //    let aFile = File(authPath)
    //
    //    do
    //    {
    //        let aString = try aFile.readString()
    //
    //        do
    //        {
    //            let aDict = try aString.jsonDecode() as? [String: Any]
    //            var uName = ""
    //
    //            for (key, value) in aDict!
    //            {
    //                switch key
    //                {
    //                case "":
    //                    uName = value as! String
    //                default:
    //                    break
    //                }
    //            }
    //
    //            print("Username from json file using perfectlib: \(uName)")
    //        }
    //        catch
    //        {
    //            print("Failed to parse auth json.")
    //        }
    //    }
    //    catch
    //    {
    //        print("Failed to get auth json.")
    //    }
}
