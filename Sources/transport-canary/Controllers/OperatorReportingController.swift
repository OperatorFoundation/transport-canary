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

class OperatorReportingController
{
    static let sharedInstance = OperatorReportingController()
    /*
     void MyCreatePDFFile (CGRect pageRect, const char *filename)// 1
     {
     CGContextRef pdfContext;
     CFStringRef path;
     CFURLRef url;
     CFDataRef boxData = NULL;
     CFMutableDictionaryRef myDictionary = NULL;
     CFMutableDictionaryRef pageDictionary = NULL;
     
     path = CFStringCreateWithCString (NULL, filename, // 2
     kCFStringEncodingUTF8);
     url = CFURLCreateWithFileSystemPath (NULL, path, // 3
     kCFURLPOSIXPathStyle, 0);
     CFRelease (path);
     myDictionary = CFDictionaryCreateMutable(NULL, 0,
     &kCFTypeDictionaryKeyCallBacks,
     &kCFTypeDictionaryValueCallBacks); // 4
     CFDictionarySetValue(myDictionary, kCGPDFContextTitle, CFSTR("My PDF File"));
     CFDictionarySetValue(myDictionary, kCGPDFContextCreator, CFSTR("My Name"));
     pdfContext = CGPDFContextCreateWithURL (url, &pageRect, myDictionary); // 5
     CFRelease(myDictionary);
     CFRelease(url);
     pageDictionary = CFDictionaryCreateMutable(NULL, 0,
     &kCFTypeDictionaryKeyCallBacks,
     &kCFTypeDictionaryValueCallBacks); // 6
     boxData = CFDataCreate(NULL,(const UInt8 *)&pageRect, sizeof (CGRect));
     CFDictionarySetValue(pageDictionary, kCGPDFContextMediaBox, boxData);
     CGPDFContextBeginPage (pdfContext, pageDictionary); // 7
     myDrawContent (pdfContext);// 8
     CGPDFContextEndPage (pdfContext);// 9
     CGContextRelease (pdfContext);// 10
     CFRelease(pageDictionary); // 11
     CFRelease(boxData);
     }
     */
    func createReportPDF(text: String) -> ()
    {
        let document = PDFDocument()
    }
    
    func getReportPDFFileName() -> String
    {
        return "Canary Status Report"
    }
    
    func createReportTextFile()
    {
        let fileManager = FileManager.default
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let path = paths[0] + "/OperatorReports/" + getReportTextFileName()
        
        //Check If Folder Exists
        if !fileManager.fileExists(atPath: path)
        {
            do
            {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            }
            catch
            {
                print("Failed to create path \(path)")
                print(error.localizedDescription)
            }
        }
        
        let report = "Report we're going to write."
        
        do
        {
            try report.write(toFile: path, atomically: true, encoding: String.Encoding.ascii)
        }
        catch
        {
            print("Failed to write report to \(path)")
            print(error.localizedDescription)
        }
    }
    
    func getReportTextFileName() -> String
    {
        return "CanaryStatusReport.txt"
    }
}
