//
//  AppSiteAssociationParsingTests.swift
//  
//
//  Created by Ben Spratling on 4/10/22.
//

import Foundation
import XCTest
@testable import SwiftAASAValidator



class AppSiteAssociationParsingTests : XCTestCase {
	
	func testParsingDetails() {
	let json = """
{
  "appIDs": [ "ABCDE12345.com.example.app", "ABCDE12345.com.example.app2" ],
  "components": [
	{
	  "/": "/buy/*",
	  "#": "my_great_product_123",
	  "comment": "Matches any URL whose path starts with /buy/ and fragment equals my_great_product_123, ignoring case"
	}
  ],
  "defaults": { "caseSensitive": false }
}
""".data(using: .utf8)!
		
		let details = try! JSONDecoder().decode(AppLinkDetail.self, from: json)
		XCTAssertEqual(details.appIDs, [ "ABCDE12345.com.example.app", "ABCDE12345.com.example.app2" ])
		XCTAssertEqual(details.defaults?.isCaseSensitive, false)
		XCTAssertEqual(details.components.count, 1)
		let component = details.components[0]
		XCTAssertEqual(component.path, "/buy/*")
		XCTAssertEqual(component.fragment, "my_great_product_123")
		
		
	}
	
	func testParsingQueryDict() {
		let json = """
{ "productID": "12345" }
""".data(using: .utf8)!
		
		let query = try! JSONDecoder().decode(AppLinkQuery.self, from: json)
		XCTAssertEqual(query, AppLinkQuery.dictionary(["productID":"12345"]))
		
		let json1 = """
"def"
""".data(using: .utf8)!
		let query1 = try! JSONDecoder().decode(AppLinkQuery.self, from: json1)
		XCTAssertEqual(query1, AppLinkQuery.string("def"))
	}
	
	
	func testParsingSubstitutionVriables() {
		let json = """
{
  "applinks": {
	"substitutionVariables": {
	  "food": [ "burrito", "pizza", "sushi", "samosa" ]
	},
	"details": [{
	  "appIDs": [ "ABCDEFG1234.com.example.app" ],
	  "components": [
		{ "/" : "/$(lang)_$(region)/$(food)/" }
	  ]
	}]
  }
}
""".data(using: .utf8)!
		
		let association = try! JSONDecoder().decode(AppleAppSiteAssociation.self, from: json)
		guard let appLinks = association.applinks else {
			XCTFail("did not deserialize applinks")
			return
		}
		XCTAssertEqual(appLinks.substitutionVariables, ["food": [ "burrito", "pizza", "sushi", "samosa" ]] )
		let url = URL(string: "https://www.example.com/en_CA/pizza/")!
		let testAppId = "ABCDEFG1234.com.example.app"
		XCTAssertEqual(appLinks.matchedAppIds(url).contains(testAppId), true)
		XCTAssertEqual(appLinks.matchedAppIds(URL(string: "https://www.example.com/en-CA/sorbet/")!).contains(testAppId), false)
	}
	
	
	func testSampleFile() {
		let json = """
{
  "applinks": {
	  "details": [
		   {
			 "appIDs": [ "ABCDE12345.com.example.app", "ABCDE12345.com.example.app2" ],
			 "components": [
			   {
				  "#": "no_universal_links",
				  "exclude": true,
				  "comment": "Matches any URL whose fragment equals no_universal_links and instructs the system not to open it as a universal link"
			   },
			   {
				  "/": "/buy/*",
				  "comment": "Matches any URL whose path starts with /buy/"
			   },
			   {
				  "/": "/help/website/*",
				  "exclude": true,
				  "comment": "Matches any URL whose path starts with /help/website/ and instructs the system not to open it as a universal link"
			   },
			   {
				  "/": "/help/*",
				  "?": { "articleNumber": "????" },
				  "comment": "Matches any URL whose path starts with /help/ and which has a query item with name 'articleNumber' and a value of exactly 4 characters"
			   }
			 ]
		   }
	   ]
   },
   "webcredentials": {
	  "apps": [ "ABCDE12345.com.example.app" ]
   },

	"appclips": {
		"apps": ["ABCED12345.com.example.MyApp.Clip"]
	}
}
""".data(using: .utf8)!
		let association = try! JSONDecoder().decode(AppleAppSiteAssociation.self, from: json)
		guard let appLinks = association.applinks else {
			XCTFail("did not deserialize applinks")
			return
		}
		let appId = "ABCDE12345.com.example.app"
		XCTAssertEqual(appLinks.matchedAppIds(URL(string: "https://www.example.com/buy/")!).contains(appId), true)
		XCTAssertEqual(appLinks.matchedAppIds(URL(string: "https://www.example.com/buy/sample")!).contains(appId), true)
		XCTAssertEqual(appLinks.matchedAppIds(URL(string: "https://www.example.com/buy/sample#no_universal_links")!).contains(appId), false)
		XCTAssertEqual(appLinks.matchedAppIds(URL(string: "https://www.example.com/help/website/index.html")!).contains(appId), false)
		XCTAssertEqual(appLinks.matchedAppIds(URL(string: "https://www.example.com/help/how_to_convert.html?articleNumber=0A5e")!).contains(appId), true)
		XCTAssertEqual(appLinks.matchedAppIds(URL(string: "https://www.example.com/help/how_to_convert.html?articleNumber=15")!).contains(appId), false)
		XCTAssertEqual(appLinks.matchedAppIds(URL(string: "https://www.example.com/help/how_to_convert.html?articleNumber=15678")!).contains(appId), false)
		
	}
	
}
