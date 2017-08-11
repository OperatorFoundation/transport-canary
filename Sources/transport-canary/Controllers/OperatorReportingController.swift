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
        let formatter = ISO8601DateFormatter()
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
        let formatter = ISO8601DateFormatter()
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
        
        //1 Day Results
        let dayTableHeader = "### This Day\n"
        let tableFields = "| Server   | Transport  | Success Rate  | Failure Rate  |\n| :------------- | :------------- | :------------- | :------------- |\n"
        
        //Populate the day table.
        
        //Placeholder
        var dayTableValues = "| serverValue| transportValue | successRateValue | failureRateValue |\n"
        
        //Actual Data
        if !dayTableRows.isEmpty
        {
            dayTableValues = dayTableRows
        }
        
        //7 Day Results
        let weekTableHeader = "\n### Last 7 Days\n"
        //| Server   | Transport  | Success Rate  | Failure Rate  |
        //| :------------- | :------------- | :------------- | :------------- |
        let weekTableRow = "| serverValue| transportValue | successRateValue | failureRateValue |\n"
        
        //30 Day results
        let monthTableHeader = "\n### Last 30 Days\n"
        //| Server   | Transport  | Success Rate  | Failure Rate  |
        //| :------------- | :------------- | :------------- | :------------- |
        let monthTableRow = "| serverValue| transportValue | successRateValue | failureRateValue |\n"
        
        //Put it all together and what do you get? m;)
        return reportHeader + reportDate + dayTableHeader + tableFields + dayTableValues + weekTableHeader + tableFields + weekTableRow + monthTableHeader + tableFields + monthTableRow
    }
    
    func addDayRow(testResult: TestResult)
    {
        var successRate = "0%"
        var failureRate = "0%"
        
        switch testResult.success
        {
            case false:
                failureRate = "100%"
            case true:
                successRate = "%100"
        }
        
        //Put a flag on it 🕊
        let country = Country(code: testResult.probeCC)
        let flag = country.emojiFlag
        
        let newRow = "| \(flag) \(testResult.serverName)| \(testResult.transport) | \(successRate) | \(failureRate) |\n"
        
        dayTableRows.append(newRow)
    }
}
