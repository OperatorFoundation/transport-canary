//
//  SyncSocket.swift
//  transport-canary
//
//  Created by Brandon Wiley on 7/5/17.
//
//

import Foundation

enum SyncSocketError: Error
{
    case asciiToDataFailed
    case dataToAsciiFailed
}

struct SyncSocket
{
    static func connect(host: String, port: Int) -> URLSessionStreamTask?
    {
        let session = URLSession(configuration: .default)
        let task = session.streamTask(withHostName: host, port: port)
        task.resume()
        return task
    }
}

extension URLSessionStreamTask
{
    func send(data: Data) -> Error?
    {
        var resultError: Error?
        
        let queue = OperationQueue()
        let op = BlockOperation(block:
        {
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            self.write(data, timeout: 10, completionHandler:
            {
                (maybeError) in
                
                resultError = maybeError
                dispatchGroup.leave()
            })
            
            dispatchGroup.wait()
        })
        
        queue.addOperations([op], waitUntilFinished: true)
        
        return resultError
    }
    
    func recvData() -> (Data?, Bool, Error?)
    {
        var resultData: Data?
        var resultEof: Bool = false
        var resultError: Error?
        
        let queue = OperationQueue()
        let op = BlockOperation(block:
        {
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()

            self.readData(ofMinLength: 1, maxLength: 4096, timeout: 10, completionHandler:
            {
                (maybeData, endOF, maybeError) in
                
                resultData=maybeData
                resultEof=endOF
                resultError=maybeError
                
                dispatchGroup.leave()
            })
            
            dispatchGroup.wait()
        })
        
        queue.addOperations([op], waitUntilFinished: true)
        
        return (resultData, resultEof, resultError)
    }
    
    func send(_ requestString: String) -> Error?
    {
        if let requestData = requestString.data(using: .ascii)
        {
            return self.send(data: requestData)
        }
        else
        {
            return SyncSocketError.asciiToDataFailed
        }
    }
    
    func recv() -> (String?, Bool, Error?)
    {
        let (maybeData, eof, maybeError) = self.recvData()
        
        if maybeError != nil
        {
            return (nil, eof, maybeError)
        }
        else if let data = maybeData
        {
            if let s = String(bytes: data, encoding: .ascii)
            {
                return (s, eof, nil)
            }
            else
            {
                return (nil, eof, SyncSocketError.dataToAsciiFailed)
            }
        }
        else
        {
            return (nil, eof, nil)
        }
    }
    
    func close()
    {
        self.closeRead()
        self.closeWrite()
    }
    
    func readUntil(_ delim: String, _ maybeRest: String?) -> (String?, Bool, Error?, String?)
    {
        var buffer: String
        
        if let rest = maybeRest
        {
            buffer = rest
        }
        else
        {
            buffer = ""
        }
        
        var maybeString: String?
        var eof: Bool = false
        var maybeError: Error?

        var prefix: String?
        
        while prefix == nil && !eof
        {
            (maybeString, eof, maybeError) = self.recv()
            
            if maybeError != nil
            {
                return (nil, eof, maybeError, nil)
            }
            else if let s = maybeString
            {
                buffer.append(s)
                
                (prefix, buffer) = buffer.slice(delim)
            }
            else
            {
                return (nil, eof, nil, buffer)
            }
        }
        
        if prefix == nil
        {
            return (prefix, eof, nil, buffer)
        }
        else
        {
            // Must be an EOF
            return (nil, eof, nil, buffer)
        }
    }
}

extension String
{
    func slice(_ delim: String) -> (String?, String)
    {
        // Make a mutable copy
        var buffer = self
        var prefix: String?
        
        if buffer.contains(delim)
        {
            // Get the prefix
            let arrayOfLines = buffer.components(separatedBy: delim)
            var firstLine = arrayOfLines[0]
            
            // Make a copy
            prefix = firstLine
            
            // Remove the prefix and delimiter from the buffer
            firstLine.append(delim)
            if let range = buffer.range(of: firstLine)
            {
                buffer.removeSubrange(range)
            }
            
            print("FirstLine: \(firstLine)")
            print("buffer: \(buffer)")
            
            return (prefix, buffer)
        }
        else
        {
            return (nil, buffer)
        }
    }
}
