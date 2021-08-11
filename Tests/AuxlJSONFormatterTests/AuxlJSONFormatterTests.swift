//
//  JSONFormatterTests.swift
//  JSONFormatterTests
//
//  Created by Joost Verrijt on 04/08/2021.
//

import XCTest
import AuxlJSONFormatter


class AuxlJSONFormatterTests: XCTestCase {
    
    /**
     */
    func jsonIsValid(json: String) -> Bool {
        if let data = json.data(using: .utf8), let _ = try? JSONSerialization.jsonObject(with: data, options: []) {
            return true
        }
        return false
    }
    
    
    func testUsage() throws {
        let json = """
            {
                "A": "B",
                "X": "Y",
                "arr": [
                    1, 2, 3
                ],
                "obj": {
                    
            
                }
            }
            """
        
        // Format with default settings
        if let formattedJson = try? AuxlJSONFormatter.format(source: json) {
            print(formattedJson)
        }
        
        // Format with tabs
        let options = JSONFormatterOptions(useTabs: true)
        if let formattedWithTabs = try? AuxlJSONFormatter.format(source: json, options: options) {
            print(formattedWithTabs)
        }
    }
    
    /**
     Tests the tokenizer
     */
    func testSimpleTokenizer() {
        let json = """
            {
                "KA": "VA",
                "KB": "Value for Key B",
                "KC": {
                    "KCA": "VCA",
                    "KCB": "VCB"
                },
                "KD": [
                    1, 2, 3, "test", 66
                ]
            }
            """
        
        let formatter = AuxlJSONFormatter()
        
        guard let root = try? formatter.tokenize(json) else {
            XCTFail("Could not tokenize input")
            return
        }
        
        let topObject = root.fields[0]
        
        XCTAssert(topObject.fields.count == 4, "Input should contain 4 top-level fields")
        
        // Retrieve the value for this token in the source string
        let vb = topObject.fields[1].fields[0].raw(json)
        XCTAssertEqual(vb, "Value for Key B")
        
        let kc = topObject.fields[2]
        let kcObject = kc.fields[0]
        
        if let output = try? AuxlJSONFormatter.format(source: json) {
          print(output)
        }
        
        XCTAssert(kcObject.type == .object && kcObject.fields.count == 2, "Field at index 2 is an object and should have 2 members")
    }
    
    /**
     Test json with some unicode
     */
    func testUnicodeJson() throws {
        
        let jsonString = """
            { \"field_a\": \"value_a😘\", \"field-ccc\": \"value🚀-ccc💪\", \"field_b\": { \"sub_field_a\": \"sub_value_a\" }, \"xxxx\": \"feefe\", \"arr\": [\"A\", \"B\"], \"prim\":1234, \"bool\": false }
        """
        
        let output = try AuxlJSONFormatter.format(source: jsonString)
        
        // Parse it into a json object
        guard jsonIsValid(json: output) else {
            XCTFail()
            return
        }
        
        // Formatted output
        print("\(output)")
    }
    
    /**
     */
    func testStrictModeJson() {
        
        // Below JSON has error introduced near "VCA" and omits delimiters
        // With JSMN_STRICT undefined, this will not produce valid JSON but will result in a presentable string
        let json = """
            {
                "KA": "VA"
                "KB": "Value for Key B"
                "KC": {
                    "KCA": "VCA,
                    "KCB": "VCB",
                    "XXX" : "YYY"
                },
                "KD": [
                    1, 2, 3
                ]
            }
            """
        
        let json2 = """
            {
                "test": "test",
                "test": "test2
                "arr": []
            }
            
            """
        
        XCTAssertFalse(jsonIsValid(json: json))
        XCTAssertThrowsError(try AuxlJSONFormatter.format(source: json2))
    }
    
    /**
     Test an example with various types
     */
    func testGeneratedJson() throws {
        let jsonUrl = Bundle.module.url(forResource: "test", withExtension: "json")
        let json = try String(contentsOf: jsonUrl!)
        
        let output = try AuxlJSONFormatter.format(source: json)
        
        XCTAssertNotNil(output)
        XCTAssertTrue(jsonIsValid(json: output))
        
        print("\(output)")
    }
    
    
    
    func testFormatStrict() {
        
        // Should fail but doesn't
        let json = """
            {
                "fefe": "fefefe",
                "xxxx": "yyyy"
                "should": "fail"
            }
        """
        
        
        if let format = try? AuxlJSONFormatter.format(source: json) {
            print(format)
            XCTFail("This JSON should have failed")
        }
        
    }
}
