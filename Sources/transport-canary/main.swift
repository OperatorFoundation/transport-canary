import PerfectLib
import Foundation

var first = true
let configs = Dir("Resources/config")
let keys = Dir("Resources/keys")

do
{
    //Kills all openVPN connections on the system before begining the test loop.
    OpenVPNController.sharedInstance.killAllOpenVPN()
    //ShapeshifterController.sharedInstance.killAllShShifter()
    
    var failedTests = [TestResult]()
    var serversNotTested = [String]()
  try configs.forEachEntry(closure:
  {
    config in
    
//    if first
//    {
//        first = false
//    }
//    else
//    {
//        return
//    }
    
    let tester = ConnectionTester.init(configFileName: config)
    if let testResult = tester.runTest()
    {
        print("Ran a test: ")
        
        let addRecordSuccess = DatabaseController.sharedInstance.insertRecord(serverName: testResult.serverName, success: testResult.success, testDate: Date())
        
        print("Added to database = \(addRecordSuccess)")
        
        if testResult.success == false
        {
            failedTests.append(testResult)
        }
    }
    else
    {
        print("We failed (to run the test properly)!!")
        serversNotTested.append(config)
    }
    
  })
    
    if serversNotTested.isEmpty
    {
        print("⭐️All available servers have been tested.⭐️")
    }
    else
    {
        print("👿The following servers could not be tested👿:\n\(serversNotTested.joined(separator: "\n👉"))")
    }
    
    if failedTests.isEmpty
    {
        print("💫All tests have succeeded!💫")
    }
    else
    {
        print("☠️The following servers failed the test☠️:")
        for test in failedTests
        {
            print("👉 \(test.serverName)")
        }
    }
    
    DatabaseController.sharedInstance.queryDB()
    
    
}
catch
{
  print(error)
}





