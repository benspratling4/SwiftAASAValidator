//
//  AppleAppSiteAssociation.swift
//  
//
//  Created by Ben Spratling on 4/10/22.
//

import Foundation


///deserialized version of the file served at `apple-app-site-association`
public struct AppleAppSiteAssociation : Codable {
	
	public var applinks:AppLinks?
	
	public var webcredentials:WebCredentials?
	
	public var appclips:AppClips?
	
	public init(applinks:AppLinks? = nil, webcredentials:WebCredentials? = nil, appclips:AppClips? = nil) {
		self.applinks = applinks
		self.webcredentials = webcredentials
		self.appclips = appclips
	}
	
}



public struct AppLinks : Codable {
	public var details:[AppLinkDetail]
	public var defaults:AppLinksDefaults?
	
	public init(details:[AppLinkDetail]
				,defaults:AppLinksDefaults? = nil
				,substitutionVariables:[String:[String]]? = nil
	) {
		self.details = details
		self.defaults = defaults
		self.substitutionVariables = substitutionVariables
	}
	
	public var substitutionVariables:[String:[String]]?
	
}


public struct AppLinksDefaults : Codable {
	
	public init(caseSensitive:Bool? = true, percentEncoded:Bool? = true) {
		self.caseSensitive = caseSensitive
		self.percentEncoded = percentEncoded
	}
	
	public var caseSensitive:Bool?
	public var percentEncoded:Bool?
	
	public var isCaseSensitive:Bool {
		return caseSensitive ?? true
	}
	
	public var isPercentEncoded:Bool {
		return percentEncoded ?? true
	}
}


public struct AppLinkDetail : Codable {
	public var appIDs:[String]
	public var components:[AppLinkComponent]
	public var defaults:AppLinksDefaults?
	
	
	public init(appIDs:[String], components:[AppLinkComponent], defaults:AppLinksDefaults?) {
		self.appIDs = appIDs
		self.components = components
		self.defaults = defaults
	}
}


public struct AppLinkComponent : Codable {
	
	public var path:String?
	public var fragment:String?
	public var query:AppLinkQuery?
	public var exclude:Bool?
	public var comment:String?
	public var caseSensitive:Bool?
	public var percentEncoded:Bool?
	
	
	public init(path:String? = nil
				,fragment:String? = nil
				,query:AppLinkQuery? = nil
				,exclude:Bool? = nil
				,comment:String? = nil
				,caseSensitive:Bool? = nil
				,percentEncoded:Bool? = nil) {
		self.path = path
		self.fragment = fragment
		self.query = query
		self.exclude = exclude
		self.comment = comment
		self.caseSensitive = caseSensitive
		self.percentEncoded = percentEncoded
	}
	
	
	public enum CodingKeys : String, CodingKey {
		case path = "/"
		case fragment = "#"
		case query = "?"
		case exclude, comment, caseSensitive, percentEncoded
	}
	
}


public enum AppLinkQuery : Codable, Equatable {
	case string(String)
	case dictionary([String:String])
	
	//MARK: - Decodable
	public init(from decoder: Decoder) throws {
		if let string = try? String.init(from:decoder)  {
			self = .string(string)
		}
		else if let dict = try? [String:String].init(from: decoder) {
			self = .dictionary(dict)
		}
		else {
			throw AppLinkQueryDecodeError.unrecognizedFormat
		}
	}
	
	//MARK: - Encodable
	public func encode(to encoder: Encoder) throws {
		switch self {
		case .string(let stringValue):
			try stringValue.encode(to: encoder)
			
		case .dictionary(let dict):
			try dict.encode(to: encoder)
		}
	}
}


public enum AppLinkQueryDecodeError : Error {
	case unrecognizedFormat
}


public struct WebCredentials : Codable {
	public var apps:[String]
	
	public init(apps:[String]) {
		self.apps = apps
	}
}



public struct AppClips : Codable {
	public var apps:[String]
	
	public init(appclips:[String]) {
		self.apps = appclips
	}
}
