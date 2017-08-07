//
//  PrintableExtension.swift
//  transport-canary
//
//  Created by Adelita Schule on 7/20/17.
//
//

import Foundation

//This extension prints your class properties in a nice way for more lovely debugging
//Thanks to the helpful post from Yogev Sitton
//https://medium.com/@YogevSitton/use-auto-describing-objects-with-customstringconvertible-49528b55f446

extension CustomStringConvertible
{
    var description: String
    {
        var description = "****** \(type(of: self)) ******\n"
        let selfMirror = Mirror(reflecting: self)
        
        for child in selfMirror.children
        {
            if let propertyName = child.label
            {
                description += "\(propertyName): \(child.value)\n"
            }
        }
        
        return description
    }
}
