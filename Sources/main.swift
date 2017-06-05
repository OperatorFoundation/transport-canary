import PerfectLib
import Foundation

let configs = Dir("Resources/config")
let keys = Dir("Resources/keys")

do
{
  try configs.forEachEntry(closure:
  {
    config in
    
    print(config)
  })
}
catch
{
  print(error)
}





