//
//  JSONFormatter.swift
//  JSONFormatter
//
//  Created by Joost Verrijt on 04/08/2021.
//

import Foundation

import jsmn

public struct JSONFormatterOptions {
    
    public init(useTabs: Bool = false, spaceWidth: Int = 4) {
        self.useTabs = useTabs
        self.spaceWidth = spaceWidth
    }
    
    var useTabs: Bool = false
    var spaceWidth: Int = 4
}

enum JSONFormatterError: Error {
    case InvalidJSON(errorLocation: NSRange)
    case OutOfMemory
}

open class AuxlJSONFormatter {
    
    var options: JSONFormatterOptions = JSONFormatterOptions()
    
    public init() { }
    
    /**
     - Parameters: JSON formatter options
     */
    public init(_ options: JSONFormatterOptions) {
        self.options = options
    }

    /**
     */
    public func tokenize(_ string: String) throws -> JSONToken {
        
        var parser = jsmn_parser()
    
        var tokenCount: Int = 100
        var tokens = UnsafeMutablePointer<jsmntok_t>.allocate(capacity: tokenCount)
        
        jsmn_init(&parser)
        
        let cString = string.cString(using: .utf8) ?? [CChar]()
        
        var tc = jsmn_parse(&parser, cString, strlen(cString), tokens, UInt32(tokenCount))
        
        while tc == JSMN_ERROR_NOMEM.rawValue {
            tokenCount = tokenCount * 2

            guard let newPtr = realloc(tokens, MemoryLayout<jsmntok_t>.size * tokenCount) else {
                // Could not reallocate
                tokens.deallocate()
                throw JSONFormatterError.OutOfMemory
            }
            
            tokens = newPtr.bindMemory(to: jsmntok_t.self, capacity: tokenCount)
            tc = jsmn_parse(&parser, cString, strlen(cString), tokens, UInt32(tokenCount))
        }
        
        if tc < 0 {
            tokens.deallocate()
            throw JSONFormatterError.InvalidJSON(errorLocation: NSMakeRange(NSNotFound, 0))
        }
        
        var root = JSONToken(0, string.utf8.count, .root)
        
        do {
            defer {
                tokens.deallocate()
            }
            
            let _ = try parse(tokens, Int(tc), &root)
        
        } catch {
            throw error
        }
        
        return root
    }
    
    /**
     Parse the jsmn token result into an intermediary JSON hierarchy
     */
    private func parse(_ buffer: UnsafeMutablePointer<jsmntok_t>,
                       _ count: Int,
                       _ container: inout JSONToken) throws -> Int {
        
        if count == 0 {
            return 0
        }
        
        let token = buffer.pointee
        
        if token.type == JSMN_PRIMITIVE {
            container.fields.append(JSONToken(token.start, token.end, .primitive))
            return 1
        } else if token.type == JSMN_STRING {
            container.fields.append(JSONToken(token.start, token.end, .string))
            return 1
        } else if token.type == JSMN_OBJECT {
            var j = 0
            
            var object = JSONToken(token.start, token.end, .object)
            
            for _ in 0..<token.size {
                
                let keyPtr = buffer + 1 + j
                var keyContainer = JSONToken(keyPtr.pointee.start, keyPtr.pointee.end, .key)
                
                if keyPtr.pointee.size > 1 {
                    // Illegal, a key can't have multiple values
                    throw JSONFormatterError.InvalidJSON(
                        errorLocation:
                            NSMakeRange(Int(keyPtr.pointee.start), Int(keyPtr.pointee.end) - Int(keyPtr.pointee.start)))
                }
                
                j += 1
                
                if keyPtr.pointee.size > 0 {
                    let np = buffer + 1 + j
                    j += try parse(np, count - j, &keyContainer)
                }
                
                object.fields.append(keyContainer)
            }
            
            container.fields.append(object)
            
            return j + 1
            
        } else if token.type == JSMN_ARRAY {
            
            var j = 0
            
            var array = JSONToken(token.start, token.end, .array)
            
            for _ in 0..<token.size {
                let np = buffer + 1 + j
                j += try parse(np, count - 1, &array)
            }
            
            container.fields.append(array)
            
            return j + 1
        }
        
        return 0
    }
    
    /**
     */
    public static func format(source: String,
                options: JSONFormatterOptions = JSONFormatterOptions()) throws -> String {
        
        let formatter = AuxlJSONFormatter(options)
        
        let token = try formatter.tokenize(source)
        
        return token.dump(source, options)
    }
    
    /**
     */
    public static func format(token: JSONToken,
                       source: String,
                       options: JSONFormatterOptions = JSONFormatterOptions()) -> String? {
        
        return token.dump(source, options)
    }
    
}
