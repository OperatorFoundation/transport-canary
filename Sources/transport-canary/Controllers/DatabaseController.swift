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
    let dbInfo = "host=localhost dbname=canarydb user=canaryoperator password=canaryoperator"
    let defaultQuery = "select serverName,success,testDate from testresult"
    let serversTableName = "servers"
    let resultsTableName = "testresults"
    
    init()
    {
        //If the table doesn't exist, create it
        //TODO: This is a Meta-Command not a sql statement, currently it will always return 0 records
        if let tablesInDBResponse = queryDB(statement: "\\dt")
        {
            let numberOfRows = tablesInDBResponse.numTuples()
            var serversTableExists = false
            var testResultsTableExists = false
//            print("servers numFields: \(tablesInDBResponse.numFields())")
//            print("servers numTuples: \(tablesInDBResponse.numTuples())")
//            print("servers query status: \(tablesInDBResponse.status())")
//            print("servers query error: \(tablesInDBResponse.errorMessage())")
            for x in 0..<numberOfRows
            {
                if let serverName = tablesInDBResponse.getFieldString(tupleIndex: x, fieldIndex: 1)
                {
                    print("Server Name = \(serverName)")
                    
                    if serverName == serversTableName
                    {
                        serversTableExists = true
                        print("Servers table already exists. 💾")
                        continue
                    }
                    else if serverName == resultsTableName
                    {
                        testResultsTableExists = true
                        print("Testresults table already exists. 💾")
                        continue
                    }
                }
            }
            if serversTableExists
            {
                //Check for records
                if let recordsInServersResponse = queryDB(statement: "SELECT COUNT(*) FROM servers")
                {
                    let numberOfRows = recordsInServersResponse.numTuples()
                    var numberOfRecords: Int = 0
                    for x in 0..<numberOfRows
                    {
                        if let count = recordsInServersResponse.getFieldInt(tupleIndex: x, fieldIndex: 0)
                        {
                            numberOfRecords = count
                            print("Number of Records in servers table = \(numberOfRecords)")
                        }
                        
                    }
                    //If empty populate our server table.
                    if numberOfRecords < 1
                    {
                        populateServersTable()
                    }
                    
                    recordsInServersResponse.clear()
                    postGresConnection.close()
                }
            }
            else
            {
                //Create Servers Table
                if let createServerTableResponse = queryDB(statement: "CREATE TABLE servers (servername varchar(50), city varchar(50), state varchar(50), country varchar(50), countrycode varchar(50), servernumber smallint )")
                {
                    if createServerTableResponse.status() == .commandOK
                    {
                        print("Created Server Table")
                        populateServersTable()
                        
                        createServerTableResponse.clear()
                        postGresConnection.close()
                    }
                }
                else
                {
                    print("Error creating servers table.")
                }
            }
            
            if testResultsTableExists == false
            {
                //Create results Table
                
                if let createServerTableResponse = queryDB(statement: "CREATE TABLE testresults (servername varchar(50), testdate timestamptz, success bool, transport varchar(50) )")
                {
                    if createServerTableResponse.status() == .commandOK
                    {
                        print("Created testresults Table")
                        populateServersTable()
                        
                        createServerTableResponse.clear()
                        postGresConnection.close()
                    }
                }
                else
                {
                    print("Error creating testresults table.")
                }
            }
            
            tablesInDBResponse.clear()
            postGresConnection.close()
            
        }
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
    func queryForServerInfo()
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
        
        let result = postGresConnection.exec(statement: "select servername,country,servernumber from servers")
        
        let numberOfRows = result.numTuples()
        print("There are \(numberOfRows) servers listed in the servers table.")
//        for x in 0..<numberOfRows
//        {
//            print("Servers:")
//            
//            if let serverName = result.getFieldString(tupleIndex: x, fieldIndex: 0)
//            {
//                //print("Name - \(serverName)")
//            }
//            
//            if let country = result.getFieldString(tupleIndex: x, fieldIndex: 1)
//            {
//                print("Country - \(country)")
//            }
//            
//            if let serverNumber = result.getFieldInt(tupleIndex: x, fieldIndex: 2)
//            {
//                print("Server Number - \(serverNumber)")
//            }
//        }
        
        result.clear()
        postGresConnection.close()
    }
    
    func queryForTestResultInfo()
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
        
        let result = postGresConnection.exec(statement: defaultQuery)
        
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
    
    func queryDB(statement: String) -> PGResult?
    {
        let status = postGresConnection.connectdb(dbInfo)
        defer
        {
            postGresConnection.finish()
        }
        if status == .bad
        {
            return nil
        }
        
        let result = postGresConnection.exec(statement: statement)
        
        return result
    }
    
    func insertTestResult(serverName: String, success: Bool, testDate: Date, transport: String) -> Bool
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
            print("Unable to Insert Test Result: Bad Connection Status")
            return false
        }
        
        let result = postGresConnection.exec(statement: "insert into testresults (serverName, success, testDate, transport) values ($1, $2, $3, $4)", params: [serverName, success, testDateString, transport])
        
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
    
    func insertServerInfo(_ serverName: String, _ serverNumber:Int, _ countryCode: String, _ country: String, _ city: String?,  _ state: String?) -> Bool
    {
        let status = postGresConnection.connectdb(dbInfo)
        defer
        {
            postGresConnection.finish()
        }
        if status == .bad
        {
            print("Unable to Insert Server Info: Bad Connection Status")
            return false
        }
        
        var result:PGResult
        
        if let city = city
        {
            if let state = state
            {
                result = postGresConnection.exec(statement: "insert into servers (serverName, serverNumber, countrycode, country, city, state) values($1, $2, $3, $4, $5, $6)", params: [serverName, serverNumber, countryCode, country, city, state])
            }
            else
            {
                result = postGresConnection.exec(statement: "insert into servers (serverName, serverNumber, countrycode, country, city) values($1, $2, $3, $4, $5)", params: [serverName, serverNumber, countryCode, country, city])
            }
        }
        else if let state = state
        {
            result = postGresConnection.exec(statement: "insert into servers (serverName, serverNumber, country, countrycode, state) values($1, $2, $3, $4, $5)", params: [serverName, serverNumber, countryCode, country, state])
        }
        else
        {
            result = postGresConnection.exec(statement: "insert into servers (serverName, serverNumber, countrycode, country) values($1, $2, $3, $4)", params: [serverName, serverNumber, countryCode, country])
        }
        
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
    
    func populateServersTable()
    {
        _ = insertServerInfo("Afghanistan", 1, "AF", "Afghanistan", nil, nil)
        _ = insertServerInfo("Alaska", 1, "US", "United States", nil, "Alaska")
        _ = insertServerInfo("Albania", 1, "AL", "Albania", nil, nil)
        _ = insertServerInfo("Algeria", 1, "DZ", "Algeria", nil, nil)
        _ = insertServerInfo("Angula", 1, "AO", "Angola", nil, nil)
        _ = insertServerInfo("Argentina", 1, "AR", "Argentina", nil, nil)
        _ = insertServerInfo("Arizona, Phoenix", 1, "US", "United States", "Phoenix", "Arizona")
        _ = insertServerInfo("Armenia", 1, "AM", "Armenia", nil, nil)
        _ = insertServerInfo("Aruba", 1, "AW", "Aruba", nil, nil)
        _ = insertServerInfo("Australia,Melbourne", 1, "AU", "Australia", "Melbourne", "Victoria")
        _ = insertServerInfo("Australia,Perth", 1, "AU", "Australia", "Perth", "Western Australia")
        _ = insertServerInfo("Australia,Sydney1", 1, "AU", "Australia", "Sydney", "New South Wales")
        _ = insertServerInfo("Australia,Sydney2", 2, "AU", "Australia", "Sydney", "New South Wales")
        _ = insertServerInfo("Australia,Sydney3", 3, "AU", "Australia", "Sydney", "New South Wales")
        _ = insertServerInfo("Austria", 1, "AT", "Austria", nil, nil)
        _ = insertServerInfo("Azerbaijan", 1, "AZ", "Azerbaijan", nil, nil)
        _ = insertServerInfo("Bahamas", 1, "BS", "Bahamas", nil, nil)
        _ = insertServerInfo("Bahrain", 1, "BH", "Bahrain", nil, nil)
        _ = insertServerInfo("Bangladesh", 1, "BD", "Bangladesh", nil, nil)
        _ = insertServerInfo("Barbados", 1, "BB", "Barbados", nil, nil)
        _ = insertServerInfo("Belgium", 1, "BE", "Belgium", nil, nil)
        _ = insertServerInfo("Belize", 1, "BZ", "Belize", nil, nil)
        _ = insertServerInfo("Bermuda", 1, "BM", "Bermuda", nil, nil)
        _ = insertServerInfo("Bolivia", 1, "BO", "Bolivia", nil, nil)
        _ = insertServerInfo("Bosnia", 1, "BA", "Bosnia", nil, nil)
        _ = insertServerInfo("Brazil", 1, "BR", "Brazil", nil, nil)
        _ = insertServerInfo("Brunei", 1, "BN", "Brunei", nil, nil)
        _ = insertServerInfo("Bulgaria", 1, "BG", "Bulgaria", nil, nil)
        _ = insertServerInfo("Cambodia", 1, "KH", "Cambodia", nil, nil)
        _ = insertServerInfo("Cape Verde", 1, "CV", "Cape Verde", nil, nil)
        _ = insertServerInfo("Cayman Islands", 1, "KY", "Cayman Islands", nil, nil)
        _ = insertServerInfo("Chicago", 1, "US", "United States", "Chicago", "Illinois")
        _ = insertServerInfo("Chile", 1, "CL", "Chile", nil, nil)
        _ = insertServerInfo("China,GUANGDONG1", 1, "CN", "China", nil, "Guangdong")
        _ = insertServerInfo("China,GUANGDONG2", 2, "CN", "China", nil, "Guangdong")
        _ = insertServerInfo("Colombia", 1, "CO", "Colombia", nil, nil)
        _ = insertServerInfo("Costa Rica", 1, "CR", "Costa Rica", nil, nil)
        _ = insertServerInfo("Croatia", 1, "HR", "Croatia", nil, nil)
        _ = insertServerInfo("Cuba", 1, "CU", "Cuba", nil, nil)
        _ = insertServerInfo("Cyprus", 1, "CY", "Cyprus", nil, nil)
        _ = insertServerInfo("DC, Washington", 1, "US", "United States", "Washington, D.C.", nil)
        _ = insertServerInfo("Denmark", 1, "DK", "Denmark", nil, nil)
        _ = insertServerInfo("Dominica", 1, "DM", "Dominica", nil, nil)
        _ = insertServerInfo("Dominican Repubilc", 1, "DO", "Dominican Republic", nil, nil)
        _ = insertServerInfo("Ecuador", 1, "EC", "Ecuador", nil, nil)
        _ = insertServerInfo("Egypt", 1, "EG", "Egypt", nil, nil)
        _ = insertServerInfo("El Salvador", 1, "SV","El Salvador", nil, nil)
        _ = insertServerInfo("Estonia", 1, "EE","Estonia", nil, nil)
        _ = insertServerInfo("Ethiopia", 1, "ET","Ethiopia", nil, nil)
        _ = insertServerInfo("Florida, Miami", 1, "US","United States", "Miami", "Florida")
        _ = insertServerInfo("France,Paris", 1, "FR","France", "Paris", "Île-de-France")
        _ = insertServerInfo("France,Roubaix", 1, "FR","France", "Roubaix", "Hauts-de-France")
        _ = insertServerInfo("Gautemala", 1, "GT","Guatemala", nil, nil)
        _ = insertServerInfo("Georgia", 1, "GE","Georgia", nil, nil)
        _ = insertServerInfo("Ghana", 1, "GH","Ghana", nil, nil)
        _ = insertServerInfo("Gosport", 1, "GB","England", "Gosport", "Hampshire")
        _ = insertServerInfo("Greece", 1, "GR","Greece", nil, nil)
        _ = insertServerInfo("Grenada", 1, "GD","Grenada", nil, nil)
        _ = insertServerInfo("Guyana", 1, "GY","Guyana", nil, nil)
        _ = insertServerInfo("Haiti", 1, "HT","Haiti", nil, nil)
        _ = insertServerInfo("Hessen", 1, "DE","Germany", nil, "Hessen")
        _ = insertServerInfo("Honduras", 1, "HN","Honduras", nil, nil)
        _ = insertServerInfo("Honkong", 1, "CN","China", "Hong Kong", nil)
        _ = insertServerInfo("Hungary", 1, "HU","Hungary", nil, nil)
        _ = insertServerInfo("India", 1, "IN","India", nil, nil)
        _ = insertServerInfo("Ireland", 1, "IE","Ireland", nil, nil)
        _ = insertServerInfo("Isle of man", 1, "IM","Isle of Man", nil, nil)
        _ = insertServerInfo("Italy,Milano1", 1, "IT","Italy", "Milan", "Lombard")
        _ = insertServerInfo("Italy,Milano2", 2, "IT", "Italy", "Milan", "Lombard")
        _ = insertServerInfo("Italy,Porcia", 1, "IT","Italy", "Porcia", "Friuli-Venezia Giulia")
        _ = insertServerInfo("Jamaica", 1, "JM","Jamaica", nil, nil)
        _ = insertServerInfo("Japan,Tokyo1", 1, "JP","Japan", "Tokyo", "Kantō")
        _ = insertServerInfo("Japan,Tokyo2", 2, "JP", "Japan", "Tokyo", "Kantō")
        _ = insertServerInfo("Japan,Tokyo3", 3, "JP", "Japan", "Tokyo", "Kantō")
        _ = insertServerInfo("Jordan", 1, "JO","Jordan", nil, nil)
        _ = insertServerInfo("Kazakhstan", 1, "KZ","Kazakhstan", nil, nil)
        _ = insertServerInfo("Kenya", 1, "KE","Kenya", nil, nil)
        _ = insertServerInfo("Korea,Seoul1", 1, "KR","South Korea", "Seoul", "Seoul National Capital Area")
        _ = insertServerInfo("Korea,Seoul2", 2, "KR", "South Korea", "Seoul", "Seoul National Capital Area")
        _ = insertServerInfo("Krygyzstan", 1, "KG","Krygyzstan", nil, nil)
        _ = insertServerInfo("Kuwait", 1, "KW","Kuwait", nil, nil)
        _ = insertServerInfo("LAOS", 1, "LA","Laos", nil, nil)
        _ = insertServerInfo("Lebanon", 1, "LB","Lebanon", nil, nil)
        _ = insertServerInfo("Leicester", 1, "GB","England", "Leicester", "Leicestershire")
        _ = insertServerInfo("Liechtenstein", 1, "LI","Liechtenstein", nil, nil)
        _ = insertServerInfo("Lithuania", 1, "LT","Lithuania", nil, nil)
        _ = insertServerInfo("London1", 1, "GB","England", "London", nil)
        _ = insertServerInfo("London2", 2, "GB", "England", "London", nil)
        _ = insertServerInfo("LosAngeles", 1, "US","United States", "Los Angeles", "California")
        _ = insertServerInfo("Luxembourg1", 1, "LU","Luxembourg", nil, nil)
        _ = insertServerInfo("Luxembourg2", 2, "LU", "Luxembourg", nil, nil)
        _ = insertServerInfo("Macau", 1, "CN","China", nil, "Macau")
        _ = insertServerInfo("Madagascar", 1, "MG","Madagascar", nil, nil)
        _ = insertServerInfo("Maidenhead", 1, "GB","England", "Maidenhead", "Berkshire")
        _ = insertServerInfo("Malaysia, kuala Lampur", 1, "MY","Malaysia", "Kuala Lumpur", "Selangor")
        _ = insertServerInfo("Malta", 1, "MT","Malta", nil, nil)
        _ = insertServerInfo("Manchester", 1, "GB","England", "Manchester", "Greater Manchester")
        _ = insertServerInfo("Mauritania", 1, "MR","Mauritania", nil, nil)
        _ = insertServerInfo("Mauritius", 1, "MU","Mauritius", nil, nil)
        _ = insertServerInfo("Mexico", 1, "MX","Mexico", nil, nil)
        _ = insertServerInfo("Moldova", 1, "MD","Moldova", nil, nil)
        _ = insertServerInfo("Monaco", 1, "MC","Monaco", nil, nil)
        _ = insertServerInfo("Mongolia", 1, "MN","Mongolia", nil, nil)
        _ = insertServerInfo("Montenegro", 1, "ME","Montenegro", nil, nil)
        _ = insertServerInfo("Montserrat", 1, "MS","Montserrat", nil, nil)
        _ = insertServerInfo("Morocco", 1, "MA","Morocco", nil, nil)
        _ = insertServerInfo("MUNCHEN", 1, "DE","Germany", "Munich", "Bavaria")
        _ = insertServerInfo("Myanmar", 1, "MM","Myanmar", nil, nil)
        _ = insertServerInfo("Netherlands1", 1, "NL","Netherlands", nil, nil)
        _ = insertServerInfo("Netherlands2", 2, "NL", "Netherlands", nil, nil)
        _ = insertServerInfo("New Jersey", 1, "US","United States", nil, "New Jersey")
        _ = insertServerInfo("New York", 1, "US","United States", "New York", "New York")
        _ = insertServerInfo("New Zealand,Auckland", 1, "NZ","New Zealand", "Auckland", nil)
        _ = insertServerInfo("New Zealand,Wellington", 1, "NZ","New Zealand", "Wellington", nil)
        _ = insertServerInfo("Nicaragua", 1, "NI","Nicaragua", nil, nil)
        _ = insertServerInfo("Niger", 1, "NE","Niger", nil, nil)
        _ = insertServerInfo("Nigeria", 1, "NG","Nigeria", nil, nil)
        _ = insertServerInfo("Norway", 1, "NO","Norway", nil, nil)
        _ = insertServerInfo("Nuremberg", 1, "DE","Germany", "Nuremberg", "Bavaria")
        _ = insertServerInfo("Ohio", 1, "US","United States", nil, "Ohio")
        _ = insertServerInfo("Oman", 1, "OM","Oman", nil, nil)
        _ = insertServerInfo("Pakistan", 1, "PK","Pakistan", nil, nil)
        _ = insertServerInfo("Panama", 1, "PA","Panama", nil, nil)
        _ = insertServerInfo("Papua New Guana", 1, "PG","Papua New Guinea", nil, nil)
        _ = insertServerInfo("Paraguay", 1, "PY","Paraguay", nil, nil)
        _ = insertServerInfo("Peru", 1, "PE","Peru", nil, nil)
        _ = insertServerInfo("Philippine", 1, "PH","Philippines", nil, nil)
        _ = insertServerInfo("Poland", 1, "PL","Poland", nil, nil)
        _ = insertServerInfo("Portugal", 1, "PT","Portugal", nil, nil)
        _ = insertServerInfo("Puerto Rico", 1, "PR","Puerto Rico", nil, nil)
        _ = insertServerInfo("Qatar", 1, "QA","Qatar", nil, nil)
        _ = insertServerInfo("Quebec", 1, "CA","Canada", nil, "Quebec")
        _ = insertServerInfo("Romania", 1, "RO","Romania", nil, nil)
        _ = insertServerInfo("Russia", 1, "RU","Russia", nil, nil)
        _ = insertServerInfo("Saint Lucia", 1, "LC","Saint Lucia", nil, nil)
        _ = insertServerInfo("San Francisco", 1, "US","United States", "San Francisco", "California")
        _ = insertServerInfo("Saudi Arabia", 1, "SA","Saudi Arabia", nil, nil)
        _ = insertServerInfo("Senegal", 1, "SN","Senegal", nil, nil)
        _ = insertServerInfo("Serbia", 1, "RS","Serbia", nil, nil)
        _ = insertServerInfo("Seychelles", 1, "SC","Seychelles", nil, nil)
        _ = insertServerInfo("Singapore", 1, "SG","Singapore", nil, nil)
        _ = insertServerInfo("Slovakia", 1, "SK","Slovakia", nil, nil)
        _ = insertServerInfo("Slovenia", 1, "SI","Slovenia", nil, nil)
        _ = insertServerInfo("South Africa", 1, "ZA","South Africa", nil, nil)
        _ = insertServerInfo("Spain", 1, "ES","Spain", nil, nil)
        _ = insertServerInfo("Sri Lanka", 1, "LK","Sri Lanka", nil, nil)
        _ = insertServerInfo("Suriname", 1, "SR","Suriname", nil, nil)
        _ = insertServerInfo("Sweden", 1, "SE","Sweden", nil, nil)
        _ = insertServerInfo("Switzerland", 1, "CH","Switzerland", nil, nil)
        _ = insertServerInfo("Syria", 1, "SY","Syria", nil, nil)
        _ = insertServerInfo("Taiwan,Taipei1", 1, "TW","Taiwan", "Taipei", nil)
        _ = insertServerInfo("Taiwan,Taipei2", 2, "TW", "Taiwan", "Taipei", nil)
        _ = insertServerInfo("Tajikistan", 1, "TJ","Tajikistan", nil, nil)
        _ = insertServerInfo("Tanzania", 1, "TZ","Tanzania", nil, nil)
        _ = insertServerInfo("Texas, Houstan", 1, "US","United States", "Houston", "Texas")
        _ = insertServerInfo("Thailand", 1, "TH","Thailand", nil, nil)
        _ = insertServerInfo("Trinidad and Tobago", 1, "TT","Trinidad and Tobago", nil, nil)
        _ = insertServerInfo("Tunisia", 1, "TN","Tunisia", nil, nil)
        _ = insertServerInfo("Turkey", 1, "TR","Turkey", nil, nil)
        _ = insertServerInfo("Turkmenistan", 1, "TM","Turkmenistan", nil, nil)
        _ = insertServerInfo("Turks and Caicos Island", 1, "TC","Turks and Caicos Islands", nil, nil)
        _ = insertServerInfo("UAE", 1, "AE","The United Arab Emirates", nil, nil)
        _ = insertServerInfo("Ukraine", 1, "UA","Ukraine", nil, nil)
        _ = insertServerInfo("Uzbekistan", 1, "UZ","Uzbekistan", nil, nil)
        _ = insertServerInfo("Vancouver", 1, "CA","Canada", "Vancouver", "British Columbia")
        _ = insertServerInfo("Venezuela", 1, "VE","Venezuela", nil, nil)
        _ = insertServerInfo("Vietnam", 1, "VN","Vietnam", nil, nil)
        _ = insertServerInfo("Virgin Islands (British)", 1, "VG","British Virgin Islands", nil, nil)
        _ = insertServerInfo("Virginia", 1, "US","United States", "Virginia", nil)
        _ = insertServerInfo("Washington, Seattle", 1, "US","United States", "Seattle", "Washington")
        _ = insertServerInfo("Yemen", 1, "YE","Yemen", nil, nil)
    }
    
}
