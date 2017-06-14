//
//  DatabaseController.swift
//  transport-canary
//
//  Created by Adelita Schule on 6/5/17.
//
//

import Foundation
import PostgreSQL

class DatabaseController
{
    static let sharedInstance = DatabaseController()
    let postGresConnection = PGConnection()
    let dbInfo = "host=localhost dbname=canarydb"
    let defaultQuery = "select serverName,success,testDate from testresult"
    
    init()
    {
        
        
        //Check if table exists and is not empty (count)
        queryDB(statement: "SELECT COUNT(*) FROM servers")
        
        //If not, create and populate our server table.
    }
    
    func connectToDB() ->Bool
    {
        let status = postGresConnection.connectdb(dbInfo)
        defer
        {
            postGresConnection.finish()
        }
        
        if status == .ok
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    func queryDB(statement: String)
    {
        let status = postGresConnection.connectdb(dbInfo)
        defer
        {
            postGresConnection.finish()
        }
        if status == .bad
        {
            return
        }
        
        let result = postGresConnection.exec(statement: statement)
        
        processQueryResponse(result: result)
    }
    
    func insertRecord(serverName: String, success: Bool, testDate: Date) -> Bool
    {
        //Filler, need to research the best way to handle the dates.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
        //"yyyy-MM-dd HH:mm:ss-TZ"
        dateFormatter.timeZone = TimeZone.init(abbreviation: "UTC")
        
        let testDateString = dateFormatter.string(from: testDate)
        
        let status = postGresConnection.connectdb(dbInfo)
        defer
        {
            postGresConnection.finish()
        }
        if status == .bad
        {
            print("Bad Connection Status")
            return false
        }
        
        let result = postGresConnection.exec(statement: "insert into testresult (serverName, success, testDate) values($1, $2, $3)", params: [serverName, success, testDateString])
        
        if result.status() == .commandOK
        {
            result.clear()
            return true
        }
        else
        {
            print("DB Insert Error Message: \(result.errorMessage())")
            result.clear()
            return false
        }
        
    }
    
    func processQueryResponse(result: PGResult)
    {
        let numberOfRows = result.numTuples()
        for x in 0..<numberOfRows
        {
            print("DB Query results:")
            print("Record \(x)")
            
            if let serverName = result.getFieldString(tupleIndex: x, fieldIndex: 0)
            {
                print("Server Name - \(serverName)")
            }
            
            if let success = result.getFieldBool(tupleIndex: x, fieldIndex: 1)
            {
                print("Success? - \(success)")
            }
            
            if let testDate = result.getFieldString(tupleIndex: x, fieldIndex: 2)
            {
                print("Test Date - \(testDate)")
            } 
        }
        
        result.clear()
        postGresConnection.close()
    }
    
    func populateServersTable()
    {
        insertServerInfo(<#T##serverName: String##String#>)
    }
    
    func insertServerInfo(_ serverName: String)
    {
        
    }
    
    
}
