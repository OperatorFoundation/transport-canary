import PerfectLib
import Foundation

var first = true
let configs = Dir("Resources/config")
let keys = Dir("Resources/keys")
var obfs4 = "obfs4"
var meek = "meek"
var shadowsocks = "shadowsocks"

signal(SIGINT)
{
    (theSignal) in
    
    print("Force exited the testing!! 😮")
    
    //Cleanup
    ShapeshifterController.sharedInstance.stopShapeshifterClient()
    OpenVPNController.sharedInstance!.stopOpenVPN()
    OpenVPNController.sharedInstance!.fixTheInternet()
    AdversaryLabController.sharedInstance.stopAdversaryLabServer()
    exit(0)
}

//Stop any possible processes that may be left over from a previous run
OpenVPNController.sharedInstance?.stopOpenVPN()
AdversaryLabController.sharedInstance.stopAdversaryLabServer()
AdversaryLabController.sharedInstance.stopAdversaryLab()

//Open VPN eats the internet
OpenVPNController.sharedInstance!.fixTheInternet()

//Now we are running the things. Hooray!
AdversaryLabController.sharedInstance.launchAdversaryLabServer()

//BatchTestController.sharedInstance.runAllTests(forTransport: obfs4)

BatchTestController.sharedInstance.runAllTests(forTransport: meek)

AdversaryLabController.sharedInstance.stopAdversaryLabServer()
