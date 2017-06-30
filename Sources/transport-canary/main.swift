import PerfectLib
import Foundation

var first = true
let configs = Dir("Resources/config")
let keys = Dir("Resources/keys")
var obfs4 = "obfs4"
var meek = "meek"

signal(SIGINT)
{
    (theSignal) in
    
    print("Force exited the testing!! 😮")
    
    //Cleanup
    ShapeshifterController.sharedInstance.stopShapeshifterClient()
    OpenVPNController.sharedInstance!.stopOpenVPN()
    OpenVPNController.sharedInstance!.fixTheInternet()
    
    exit(0)
}

OpenVPNController.sharedInstance!.fixTheInternet()
BatchTestController.sharedInstance.runAllTests(forTransport: obfs4)
BatchTestController.sharedInstance.runAllTests(forTransport: meek)
