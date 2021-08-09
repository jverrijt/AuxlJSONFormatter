# AuxlJSONFormatter

JSON string formatter / pretty printer for swift. Wraps [jsmn](https://github.com/zserge/jsmn): a minimalistic JSON parser in C.

Can provide an alternative to Swift's `JSONSerialization.data` in cases where the order of the fields in the formatted output need to match the order of the input.

Usage
-----

This library is provided as Swift package.

To format a string:

```swift
// Format with default settings
if let formattedJson = try? AuxlJSONFormatter.format(source: json) {
    print(formattedJson)
}

// Format with tabs
let options = JSONFormatterOptions(useTabs: true)
if let formattedWithTabs = try? AuxlJSONFormatter.format(source: json, options: options) {
    print(formattedWithTabs)
}
```
It includes a simple tokenizer that can be used to query the json structure:

```swift
let json = """
    {
        "KA": "VA",
        "KB": "Value for Key B",
        "KC": {
            "KCA": "VCA",
            "KCB": "VCB"
        },
        "KD": [
            1, 2, 3
        ]
    }
    """

let formatter = AuxlJSONFormatter()

if let root = try? formatter.tokenize(json) {
    // Top-level object
    let object = root.fields[0]
    
    let value = object.fields[1].fields[0]
    
    // Prints "Value for Key B"
    print(value.raw(json))
}
```

