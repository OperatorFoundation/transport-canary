//
//  OperatorReportingController.swift
//  transport-canary
//
//  Created by Adelita Schule on 8/4/17.
//
//

import Foundation
import Cocoa
import Quartz

/**
 This class is for Operator Foundation Reporting
 */
class OperatorReportingController
{
    static let sharedInstance = OperatorReportingController()
    let formatter = ISO8601DateFormatter()
    
    var testResults7Days: [TestResult]?
    var testResults30Days: [TestResult]?
    var testResultsToday: [TestResult]?
    
    func createReportTextFile()
    {
        let fileManager = FileManager.default
        let paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .localDomainMask, true)
        guard !paths.isEmpty
            else
        {
            print("Unable to create a new report: the expected directory could not be found.")
            return
        }
        
        let folderPath = paths[0] + "/OperatorReports/"
        let fileName = getReportTextFileName()
        let fileExtension = ".md"
        let filePath =  folderPath + fileName + fileExtension
        
        let report = generateReportContent()
        //print(report)
        let fileData = report.data(using: .utf8)
        
        //If the file doesn't exist create it
        if !fileManager.fileExists(atPath: folderPath)
        {
            do
            {
                try fileManager.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
                print("Created a Folder!!! - \(folderPath)")
            }
            catch
            {
                print("Failed to create a folder \(folderPath)")
                print(error.localizedDescription)
            }
        }
        else
        {
            print("Folder already exists: \(folderPath)")
        }
        
        fileManager.createFile(atPath: filePath, contents: fileData, attributes: nil)
    }
    
    func getReportTextFileName() -> String
    {
        
        formatter.timeZone = TimeZone.current
        formatter.formatOptions = [.withFullDate,
                                   .withTime,
                                   .withDashSeparatorInDate]
        let now = formatter.string(from: Date())
        
        return "CanaryStatusReport\(now)"
    }
    
    func generateReportContent() -> String
    {
        //Get the data from our testresults table
        testResults7Days = DatabaseController.sharedInstance.queryForTestResults(numberOfDays: 7)
        testResults30Days = DatabaseController.sharedInstance.queryForTestResults(numberOfDays: 30)
        testResultsToday = DatabaseController.sharedInstance.queryForTestResults(numberOfDays: 1)
        
        //Today's date as string
        formatter.timeZone = TimeZone.current
        formatter.formatOptions = [.withFullDate,
                                   .withTime,
                                   .withTimeZone,
                                   .withDashSeparatorInDate,
                                   .withColonSeparatorInTime,
                                   .withSpaceBetweenDateAndTime,
                                   .withColonSeparatorInTimeZone]
        let now = formatter.string(from: Date())
        
        //Format with markdown because pretty.
        let reportHeader = "## Transport Canary Status Report\n\n"
        
        let reportDate = "\(now)\n\n"
        
        if let countries = DatabaseController.sharedInstance.queryForDistinctCountries()
        {
            var countryTables = [String]()
            var untestedCountries = [String]()
            
            for thisCountry in countries
            {
                if let countryTable = generateCountryTable(country: thisCountry)
                {
                    countryTables.append(countryTable)
                }
                else
                {
                    untestedCountries.append("\(thisCountry.emojiFlag) \(thisCountry.name) \(thisCountry.emojiFlag)")
                }
            }
            
            let countryTablesString = countryTables.joined()
            let untestedCountriesString = "\n### Untested:\n" + untestedCountries.joined(separator: ", ")
            return reportHeader + reportDate + countryTablesString + untestedCountriesString
        }
        else
        {
            print("Tried to get a list of countries, but we failed. We were unable to generate our report.")
            
            return reportHeader + reportDate
        }
    }
    
    ///This method generates a markdown table for a given country.
    ///If the country has no test results this method returns nil instead.
    func generateCountryTable(country: Country) -> String?
    {
        //Put a flag on it 🕊
        let tableHeader = "\n### \(country.emojiFlag) \(country.name) \(country.emojiFlag)\n"
        
        let tableFields = "| Transport   | Success Rate Today | Success Rate Last 7 Days  | Success Rate Last 30 Days  |\n| :------------- | :------------- | :------------- | :------------- |\n"
        
        var tableValues = ""
        
        //Sort results so that each set only contains results for this country.
        var last7DaysResults = [TestResult]()
        var last30DaysResults = [TestResult]()
        var todayResults = [TestResult]()
        
        if let results7ForCountry = testResults7Days?.filter({$0.probeCC == country.code})
        {
            last7DaysResults = results7ForCountry
        }
        if let results30ForCountry = testResults30Days?.filter({$0.probeCC == country.code})
        {
            last30DaysResults = results30ForCountry
        }
        if let resultsTodayForCountry = testResultsToday?.filter({$0.probeCC == country.code})
        {
            todayResults = resultsTodayForCountry
        }
        
        //If there are no test results for this country, add it to the list of untested countries.
        //Do not create a table for this country.
        if last7DaysResults.isEmpty && last30DaysResults.isEmpty && todayResults.isEmpty
        {
            return nil
        }
        else
        {
            //Create a row for each transport we test.
            for transport in allTransports
            {
                //Last 7 days for this transport.
                var successRate7Days = "--"
                var transportResults7Days = [TestResult]()
                for result in last7DaysResults
                {
                    if result.transport == transport
                    {
                        transportResults7Days.append(result)
                    }
                }
                
                if !transportResults7Days.isEmpty
                {
                    let numberOfTests = transportResults7Days.count
                    let successes = transportResults7Days.filter({$0.success})
                    if successes.isEmpty
                    {
                        successRate7Days = "0%"
                    }
                    else
                    {
                        let numberOfSuccesses = successes.count
                        successRate7Days = String(100/(numberOfTests/numberOfSuccesses)) + "%"
                    }
                }
                
                //Last 30 days for this transport.
                var successRate30Days = "--"
                var transportResults30Days = [TestResult]()
                for result in last30DaysResults
                {
                    if result.transport == transport
                    {
                        transportResults30Days.append(result)
                    }
                }
                
                if !transportResults30Days.isEmpty
                {
                    let numberOfTests = transportResults30Days.count
                    let successes = transportResults30Days.filter({$0.success})
                    if successes.isEmpty
                    {
                        successRate30Days = "0%"
                    }
                    else
                    {
                        let numberOfSuccesses = successes.count
                        successRate30Days = String(100/(numberOfTests/numberOfSuccesses)) + "%"
                    }
                }
                
                //Last day for this transport.
                var successRate1Day = "--"
                var transportResultsToday = [TestResult]()
                for result in todayResults
                {
                    if result.transport == transport
                    {
                        transportResultsToday.append(result)
                    }
                }
                
                if !transportResultsToday.isEmpty
                {
                    let numberOfTests = transportResultsToday.count
                    let successes = transportResultsToday.filter({$0.success})
                    if successes.isEmpty
                    {
                        successRate1Day = "0%"
                    }
                    else
                    {
                        let numberOfSuccesses = successes.count
                        successRate1Day = String(100/(numberOfTests/numberOfSuccesses)) + "%"
                    }
                }
                
                let rowValues = "| \(transport)| \(successRate1Day) | \(successRate7Days) | \(successRate30Days) |\n"
                
                tableValues += rowValues
            }
            
            //Put it all together and what do you get? m;)
            return tableHeader + tableFields + tableValues
        }
    }

}
