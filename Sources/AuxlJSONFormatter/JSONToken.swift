//
//  JSONToken.swift
//  JSONFormatter
//
//  Created by Joost Verrijt on 08/08/2021.
//

import Foundation

public enum JSONTokenType {
    case root, object, array, key, string, primitive
}

public struct JSONToken {
    
    public var type: JSONTokenType
    public var range: NSRange
    
    public var fields = [JSONToken]()
    
    /**
     */
    init(_ start: Int32, _ end: Int32, _ type: JSONTokenType) {
        self.init(Int(start), Int(end), type)
    }
    
    /**
     */
    init(_ start: Int, _ end: Int, _ type: JSONTokenType) {
        self.range = NSMakeRange(start, end - start)
        self.type = type
    }
    
    /**
     Convert this token and its fields into a formatted string
     */
    func dump(_ source: String,
              _ options: JSONFormatterOptions = JSONFormatterOptions(),
              _ indent: Int = 0,
              _ parent: JSONToken? = nil) -> String {
        
        var buffer = String()
        var index = 0
        
        for field in fields {
            if field.type == .key {
                let sub = field.raw(source)
                
                buffer += "\(self.indent(indent, options))\"\(sub)\": "
                buffer += field.dump(source, options, indent)
                
                if index != fields.count - 1 {
                   buffer += ",\n"
               }
            } else if field.type == .string || field.type == .primitive {
                let sub = field.raw(source)

                if parent?.type == .array {
                    buffer += self.indent(indent, options)
                }
                
                if field.type == .primitive {
                    buffer += sub
                } else {
                    buffer += "\"\(sub)\""
                }
                
                if index != fields.count - 1 {
                   buffer += ",\n"
               }
            } else if field.type == .object {
                
                if parent?.type == .array {
                    buffer += self.indent(indent, options)
                }
                
                buffer += "{\n"
                buffer += field.dump(source, options, indent + 1)
                buffer += "\n\(self.indent(indent, options))}"
                
                if index != fields.count - 1 {
                   buffer += ",\n"
               }
            } else if field.type == .array {
                buffer += "[\n"
                buffer += field.dump(source, options, indent + 1, field)
                buffer += "\n\(self.indent(indent, options))]"
            }
            
            index += 1
        }
   
        return buffer
    }
    
    /**
     Returns the raw utf8 string
     */
    public func raw(_ source: String) -> String {
        let startIdx = source.utf8.index(source.utf8.startIndex, offsetBy:range.location)
        let endIdx = source.utf8.index(source.utf8.startIndex, offsetBy: NSMaxRange(range))
        
        let sub = String(source[startIdx..<endIdx])
        
        return sub
    }
    
    /**
     */
    func indent(_ indent: Int, _ options: JSONFormatterOptions) -> String {
        let char = options.useTabs ? "\t" : " "
        let indent = options.useTabs ? indent : indent * options.spaceWidth
        
        return String(repeating: char, count: indent)
    }
}
