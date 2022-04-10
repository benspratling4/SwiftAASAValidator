//
//  ComponentMatchingTests.swift
//  
//
//  Created by Ben Spratling on 4/10/22.
//

import XCTest
import SwiftAASAValidator

class ComponentMatchingTests: XCTestCase {
	
	func testFragmentMatching() {
		//does match
		let url0 = URL(string: "https://www.example.com#test0")!
		let component0 = AppLinkComponent(fragment: "test0")
		XCTAssertEqual(component0.matches(url: url0, topLevelDefaults: nil), true)
		
		//doesn't match
		let url1 = URL(string: "https://www.example.com#test0")!
		let component1 = AppLinkComponent(fragment: "test1")
		XCTAssertEqual(component1.matches(url: url1, topLevelDefaults: nil), nil)
		
		//does match and is excluded
		let url2 = URL(string: "https://www.example.com#test0")!
		let component2 = AppLinkComponent(fragment: "test0", exclude: true)
		XCTAssertEqual(component2.matches(url: url2, topLevelDefaults: nil), false)
		
		//doesn't match so is not excluded
		let url3 = URL(string: "https://www.example.com#test0")!
		let component3 = AppLinkComponent(fragment: "test1", exclude: true)
		XCTAssertEqual(component3.matches(url: url3, topLevelDefaults: nil), nil)
		
	}
	
	func testComponentMatching() {
		let json = """
{
  "/": "abc",
  "?": "def",
  "#": "*"
}
""".data(using: .utf8)!
		
		let component = try! JSONDecoder().decode(AppLinkComponent.self, from: json)
		let url0 = URL(string: "https://www.example.com/abc?def")!
		XCTAssertEqual(component.matches(url: url0, topLevelDefaults: nil), true)
		
		let url2 = URL(string: "https://www.example.com?def")!
		XCTAssertEqual(component.matches(url: url2, topLevelDefaults: nil), nil)
		
		let url1 = URL(string: "https://www.example.com/abc")!
		XCTAssertEqual(component.matches(url: url1, topLevelDefaults: nil), nil)
	}
	
	
	func testFragmentCaseSensitivity() {
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
		let appId = "ABCDE12345.com.example.app"
		XCTAssertEqual(details.matches(url: URL(string: "https://www.example.com/buy/sample.html#my_great_product_123")!, topLevelDefaults: nil), true)
		XCTAssertEqual(details.matches(url: URL(string: "https://www.example.com/buy/sample.html#My_Great_Product_123")!, topLevelDefaults: nil), true)
		
	}
	
}
