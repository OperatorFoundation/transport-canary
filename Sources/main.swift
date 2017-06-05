import PerfectLib
import Foundation

let configs = Dir("Resources/config")
let keys = Dir("Resources/keys")

do
{
  try configs.forEachEntry(closure:
  {
    config in

    let serverName = config.replacingOccurrences(of: "-tcp.ovpn", with: "")
    print(config)
    print(serverName)
  })
}
catch
{
  print(error)
}


//Keys
do
{
    try keys.forEachEntry(closure:
    {
        (filename) in
        print("Found 🔑 file \(filename)")
    })
}
catch
{
    print(error)
}




