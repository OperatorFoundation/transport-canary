//
//  OoniNewReportRequest.swift
//  transport-canary
//
//  Created by Adelita Schule on 6/29/17.
//
//

import Foundation

class OoniNewReportRequest: CustomStringConvertible
{
    let softwareNameKey = "software_name"
    let softwareVersionKey = "software_version"
    let probeASNKey = "probe_asn"
    let probeCCKey = "probe_cc"
    let testNameKey = "test_name"
    let testVersionKey = "test_version"
    let dateFormatVersionKey = "data_format_version"
    let testStartTimeKey = "test_start_time"
    let inputHashesKey = "input_hashes"
    let testHelperKey = "test_helper"
    let probeIPKey = "probe_ip"
    let formatKey = "format"
    
    var requestDictionary: Dictionary <String, Any>
    {
        get
        {
            return createRequestDictionary()
        }
    }
    
    var softwareName: String = "TransportCanary"
    //`string` the name of the software that is creating a report (ex. "ooni-probe")
    
    var format: String = "json"
    //`string` that must be either "json" or "yaml" to identify the format of the content.
    
    var dateFormatVersion: String = "json"
    //`string` that must be either "json" or "yaml" to identify the format of the content.
    
    var softwareVersion: String = "0.0.10-beta"
    /*{
        get
        {
            if let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            {
                return bundleVersion
            }
            else
            {
                return "unknown"
            }
        }
    }*/
    //`string` the version of the software creating the report (ex. "0.0.10-beta")
    
    var probeASN: String
    //`string` the Authonomous System Number of the network the test is related to prefixed by "AS" (ex. "AS1234")
    
    var probeCC: String
    //`string` the two-letter country code of the probe as defined in ISO3166-1 alpha-2 or ZZ when undefined (ex. "IT")
    
    var testName: String
    //`string` the name of the test performing the network measurement. In the case of ooni-probe this is the test filename without the ".py" extension.
    
    var testVersion: String
    //`string` the version of the test peforming the network measurement.
    
    var testStartTime: String
    //`string` timestamp in UTC of when the test was started using the format "%Y-%m-%d %H:%M:%S"
    
    var inputHashes: String?
    //(optional) `list` of hex encoded sha256sum of the contents of the inputs we are using for this test. This field is required if the collector backend only accepts certain inputs (that is it has a collector policy). For more information on policies see section 2.3.
    
    var testHelper: String?
    //(optional) `string` the name of the required test_helper for this test.
    
    var probeIP: String?
    //(optional) `string` the IP Address of the ooniprobe client. When the test requires a test_helper the probe should inform oonib of it's IP address. We need to know this since we are not sure if the probe is accessing the report collector via Tor or not.
    
    init?(testResult: TestResult)
    {
        if testResult.probeASN != nil
        {
            self.probeASN = testResult.probeASN!
            self.testName = "test_transport_canary-\(testResult.transport)"
            self.testVersion = "0.1"
            self.probeCC = testResult.probeCC
            
            //Submit date as string in format requested by Ooni
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "Y-m-d H:M:S"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            let ooniDateString = dateFormatter.string(from: testResult.testDate)
            self.testStartTime = ooniDateString
            
            ///These are optional values that we are not currently using
            self.inputHashes = nil
            self.testHelper = nil
            self.probeIP = nil
            
            print("📝 📝 📝  Created a new report request for Ooni reporting: 📝 📝 📝")
            print(self)
        }
        else
        {
            print("Unable to generate an Ooni report as the probe ASN was unavailable.")
            return nil
        }
        
    }
    
    func createRequestDictionary() -> Dictionary <String, Any>
    {
        let reqDictionary = [softwareNameKey: softwareName,
                             softwareVersionKey: softwareVersion,
                             probeASNKey: probeASN,
                             probeCCKey: probeCC,
                             testNameKey: testName,
                             testVersionKey: testVersion,
                             dateFormatVersionKey: dateFormatVersion,
                             testStartTimeKey: testStartTime,
                             formatKey: format
                             ]
        
        return reqDictionary
    }
}
