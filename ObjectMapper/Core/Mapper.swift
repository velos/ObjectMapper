//
//  Mapper.swift
//  ObjectMapper
//
//  Created by Tristan Himmelman on 2014-10-09.
//  Copyright (c) 2014 hearst. All rights reserved.
//

import Foundation

public protocol MapperProtocol {
    class func map(mapper: Mapper, object: Self)
    init()
}

enum MappingType {
    case fromJSON
    case toJSON
}

public typealias JSONDictionary = [String : AnyObject]
public typealias JSONArray = [JSONDictionary]


public class Mapper {
    var currentJSONDictionary: JSONDictionary = [:]
    var currentValue: AnyObject?
    var currentKey: String?
    var mappingType: MappingType = .fromJSON
    
    // MARK: Public methods
    
    public init(){
        
    }
    
    // Sets the current mapper value and key 
    public subscript(key: String) -> Mapper {
        get {
            // save key and value associated to it
            currentKey = key
            currentValue = valueFor(key)
            
            return self
        }
        set {}
    }
    
    // map a JSON string onto an existing object
    public func map<N: MapperProtocol>(JSON: String, to object: N) -> N! {
        var json = parseJSONString(JSON)
        if let json = json {

            mappingType = .fromJSON
            N.map(self, object: object)
            
            return object
        }
        return nil
    }

    // map a JSON string to an object of type <N: MapperProtocol>
    public func map<N: MapperProtocol>(JSONString: String, to type: N.Type) -> N? {
        if let mappedObjects: [N] = self.map(JSONString, to: type) {
            if let mappedObject = mappedObjects.first {
                return mappedObject
            }
        }
        return nil
    }

    // map a JSON string to an array of objects of type <N: MapperProtocol>
    public func map<N: MapperProtocol>(JSONString: String, to type: N.Type) -> [N]? {
        var parsedJSON = parseJSONString(JSONString)
        if let unmappedObjects = parsedJSON {
            var mappedObjects = [N]()
            for dict in unmappedObjects {
                let mappedObject: N = map(dict, to: type)
                mappedObjects.append(mappedObject)
            }
            return mappedObjects
        }
        return nil
    }

    // maps a JSON dictionary to an object that conforms to MapperProtocol
    public func map<N: MapperProtocol>(JSON: JSONDictionary, to type: N.Type) -> N! {
        mappingType = .fromJSON

        self.currentJSONDictionary = JSON
        
        var object = N()
        N.map(self, object: object)
        
        return object
    }
    
    // maps an Object to a JSON dictionary <String : AnyObject>
    public func toJSON<N: MapperProtocol>(object: N) -> JSONDictionary {
        mappingType = .toJSON
        
        self.currentJSONDictionary = JSONDictionary()
        N.map(self, object: object)
        
        return self.currentJSONDictionary
    }
    
    // maps an Object to a JSON string
    public func toJSONString<N: MapperProtocol>(object: N, prettyPrint: Bool) -> String! {
        let JSONDict = toJSON(object)
        
        var err: NSError?
        if NSJSONSerialization.isValidJSONObject(JSONDict) {
            var options = prettyPrint ? NSJSONWritingOptions.PrettyPrinted : NSJSONWritingOptions.allZeros
            var jsonData: NSData? = NSJSONSerialization.dataWithJSONObject(JSONDict, options: options, error: &err)
            if let error = err {
                println(error)
            }
            
            if let json = jsonData {
                return NSString(data: json, encoding: NSUTF8StringEncoding)
            }
        }
        return nil
    }
    
    // MARK: Private methods
    
    // fetch value from JSON dictionary
    private func valueFor<N>(key: String) -> N? {
        return (currentJSONDictionary[key] as? N)
    }

    // convert a JSON String into a Dictionary<String, AnyObject> using NSJSONSerialization
    private func parseJSONString(JSONString: String) -> JSONArray? {
        var data = JSONString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        if let data = data {
            var error: NSError?
            var parsedJSON: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &error)

            // array of objects
            if let parsedJSONArray = parsedJSON as? JSONArray {
                return parsedJSONArray
            }

            // single object
            if let parsedJSONDictionary = parsedJSON as? JSONDictionary {
                return [ parsedJSONDictionary ]
            }
        }

        return nil
    }
}
