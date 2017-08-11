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
    
    var dayTableRows = ""
    
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
        let fileData = report.data(using: .ascii)
        
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
        let reportHeader = "## CanaryStatusReport\n\n"
        
        let reportDate = "\(now)\n\n"
        
        var countryTables = [String]()
        if let countries = DatabaseController.sharedInstance.queryForDistinctCountries()
        {
            print("Got a list of distinct countries, we're building a report y'all!")
            for thisCountry in countries
            {
                let countryTable = generateCountryTable(country: thisCountry)
                countryTables.append(countryTable)
            }
            
            return reportHeader + reportDate + countryTables.joined()
        }
        else
        {
            print("Tried to get a list of countries, but we failed.")
            
            return reportHeader + reportDate
        }
    }
    
    func generateCountryTable(country: Country) -> String
    {
        //Put a flag on it 🕊
        let tableHeader = "\n### \(country.emojiFlag) \(country.name) \(country.emojiFlag)\n"
        
        let tableFields = "| Transport   | Success Rate Today | Success Rate Last 7 Days  | Success Rate Last 30 Days  |/n| :------------- | :------------- | :------------- | :------------- |"
        let tableValues = "| transportName| successRate1Day | successRate7Days | successRate30Days |\n"
        
        //Put it all together and what do you get? m;)
        return tableHeader + tableFields + tableValues
    }
    
    func addDayRow(testResult: TestResult)
    {
        var successRate = "0%"
        
        switch testResult.success
        {
            case false:
                successRate = "0%"
            case true:
                successRate = "%100"
        }
        
        
        
        let newRow = "| \(testResult.serverName)| \(testResult.transport) | \(successRate) | nada |\n"
        
        dayTableRows.append(newRow)
    }
}
