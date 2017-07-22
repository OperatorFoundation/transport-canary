//
//  OoniReportingController.swift
//  transport-canary
//
//  Created by Adelita Schule on 6/27/17.
//
//

import Foundation

class OoniReportingController
{
    static let sharedInstance = OoniReportingController()
    
    let ooniURLString = "https://b.collector.ooni.io/"
    let session = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask? = nil
    
    let PUT = "PUT"
    let POST = "POST"
    
    //MARK: Create Report
    
    func createOoniReport(requestDictionary: Dictionary <String, Any>, completionHandler: @escaping (OoniNewReportResponse?) -> Void)
    {
        //RequestDictionary should be gotten via OoniNewReportRequest requestDictioanry property.
        let reportURLString = "\(ooniURLString)report"
        print("📤  Sending New Report Request to: \(reportURLString)")
        print("📦  Request body: \(requestDictionary)")
        guard let url = URL(string: reportURLString)
        else
        {
            print("Failed to create Ooni report: Unable to resolve string to URL: \(reportURLString)")
            completionHandler(nil)
            return
        }
        
        performRequest(requestURL: url, method: POST, body: requestDictionary)
        {
            (maybeResponse) in
            
            if let responseDictionary = maybeResponse as? Dictionary <String, Any>
            {
                if let reportResponse = OoniNewReportResponse(responseDictionary: responseDictionary)
                {
                    completionHandler(reportResponse)
                }
                else if let errorMessage = responseDictionary["error"]
                {
                    print("Unable to create new Ooni report, received error message:\(errorMessage)")
                }
                else
                {
                    print("Unable to create new Ooni report, unable to parse response dictionary into OoniNewReportResponse")
                }
            }
            else
            {
                print("Unable to create new Ooni report, expected a dictionary in response, but response was nil, or was in an unrecognized format.")
                completionHandler(nil)
            }
        }
    }
    
    func updateOoniReport(reportID: String, requestDictionary: Dictionary <String, Any>, completionHandler: @escaping (Dictionary<String, Any>?) -> Void)
    {
        let reportURLString = "\(ooniURLString)report/\(reportID)"
        print("📤  Sending Update Report Request to: \(reportURLString)")
        print("📦  Request body: \(requestDictionary)")
        guard let url = URL(string: reportURLString)
        else
        {
            print("Failed to update Ooni report: Unable to resolve string to URL: \(reportURLString)")
            completionHandler(nil)
            return
        }
        
        performRequest(requestURL: url, method: POST, body: requestDictionary)
        {
            (maybeResponse) in
            
            if let responseDictionary = maybeResponse as? Dictionary <String, Any>
            {
                completionHandler(responseDictionary)
            }
            else
            {
                print("Unable to update an Ooni report, expected a dictionary in response, but response was nil, or was in an unrecognized format.")
                completionHandler(nil)
            }
        }
    }
    
    func closeOoniReport(reportID: String, completionHandler: @escaping (Dictionary<String, Any>?) -> Void)
    {
        let reportURLString = "\(ooniURLString)report/\(reportID)/close"
        print("📤  Sending Close Report Request to: \(reportURLString)")
        guard let url = URL(string: reportURLString)
            else
        {
            print("Failed to close Ooni report: Unable to resolve string to URL: \(reportURLString)")
            completionHandler(nil)
            return
        }
        
        performRequest(requestURL: url, method: POST, body: nil)
        {
            (maybeResponse) in
            
            if let responseDictionary = maybeResponse as? Dictionary <String, Any>
            {
                completionHandler(responseDictionary)
            }
            else
            {
                print("Unable to update an Ooni report, expected a dictionary in response, but response was nil, or was in an unrecognized format.")
                completionHandler(nil)
            }
        }
    }
    
    //MARK: Generic Request
    func performRequest(requestURL: URL, method: String, body: Any?, completionHandler: @escaping (Any?) -> Void)
    {
        //Cancel the data task if it already exists, so we can reuse the data task object for the new query.
        dataTask?.cancel()
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if body != nil
        {
            if JSONSerialization.isValidJSONObject(body!)
            {
                request.httpBody = try?JSONSerialization.data(withJSONObject: body!, options: [])
            }
            else
            {
                print("Attempted to form an HTTP request without a valid JSON Serializable object")
            }
        }

        dataTask = session.dataTask(with: request, completionHandler:
        {
            (maybeData, maybeURLResponse, maybeError) in
            
            if let error = maybeError
            {
                print("Error with http data task: \(error.localizedDescription)")
            }
            
            if let urlResponse = maybeURLResponse as? HTTPURLResponse
            {
                if urlResponse.statusCode != 200
                {
                    print("Received an http response other than 200: \(urlResponse.statusCode)")
                }
            }
            
            if let responseData = maybeData
            {
                self.handleServerResponse(responseData: responseData, completionHandler: completionHandler)
            }
        })
        
        //All tasks start in a suspended state by default; calling resume() starts the data task
        dataTask?.resume()
    }
    
    func handleServerResponse(responseData: Data, completionHandler: (Any?) -> Void)
    {
        do
        {
            let responseJSON = try JSONSerialization.jsonObject(with: responseData, options: [])
            
            if let responseDictionary = responseJSON as? [String: Any]
            {
                print("We received a response dictionary from the server:")
                print("\(responseDictionary.description)")
                completionHandler(responseDictionary)
            }
            else if let responseArray = responseJSON as? [Any]
            {
                print("We received a response Array from the server:")
                print("\(responseArray.description)")
                completionHandler(responseArray)
            }
            else
            {
                print("We received a JSON response from the server that is not an array or a dictionary.")
                completionHandler(nil)
            }
        }
        catch
        {
            print("Response from server was not a valid JSON object.")
            completionHandler(nil)
        }
    }
}
