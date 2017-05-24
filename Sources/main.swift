import PerfectLib

let configs = Dir("Resources/config")

do
{
  try configs.forEachEntry(closure: {
    config in

    print(config)
  })
}
catch
{
  print(error)
}
