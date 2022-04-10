//
//  File.swift
//  
//
//  Created by Ben Spratling on 4/10/22.
//

import Foundation
import SwiftPatterns


extension AppLinks {
	
	public func matchedAppIds(_ url :URL)->[String] {
		return details.filter { detail in
			return detail.matches(url: url, topLevelDefaults: defaults, substitutions:substitutionVariables)
		}
		.map(\.appIDs)
		.flatMap({ $0 })
	}
}

extension AppLinkDetail {
	
	public func matches(url:URL, topLevelDefaults:AppLinksDefaults?, substitutions:[String:[String]]? = nil)->Bool {
		let defaults = AppLinksDefaults(caseSensitive: defaults?.caseSensitive ?? topLevelDefaults?.caseSensitive
										, percentEncoded: defaults?.percentEncoded ?? topLevelDefaults?.percentEncoded)
		for component in components {
			switch component.matches(url: url, topLevelDefaults: defaults, substitutions: substitutions) {
			case nil:
				//we did not match the component, move to the next one
				continue
				
			case .some(true):
				//we matched a component
				return true
				
			case .some(false):
				//we matched an excluded component
				return false
			}
		}
		return false
	}
	
}


extension AppLinkComponent {
	
	///true means matches, false means matches & excluded, nil means doesn't match
	public func matches(url:URL, topLevelDefaults:AppLinksDefaults?, substitutions:[String:[String]]? = nil)->Bool? {
		let rules = MatchRules(caseSensitive: topLevelDefaults?.caseSensitive ?? true
							   ,percentEncoded: topLevelDefaults?.percentEncoded ?? true
							   ,substitutions: substitutions ?? [:])
		
		if let path = self.path {
			var urlPath = url.path.withoutPrefix("/") ?? url.path
			if url.hasDirectoryPath, !url.path.hasSuffix("/") {
				urlPath += "/"
			}
			let matchPath = path.withoutPrefix("/") ?? path
			if !matchPath.matchesWildCards(urlPath, rules:rules) {
				return nil
			}
		}
		if let requiredQueryItems = self.query {
			if let urlItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
				let allQueryItems:[String:QueryMatching]
				switch requiredQueryItems {
				case .string(let string):
					allQueryItems = [string:.present]
				case .dictionary(let pairs):
					allQueryItems = pairs.mapValues({ QueryMatching.value($0) })
				}
				
				for requiredQueryItem in allQueryItems {
					guard let foundValue = urlItems.first(where:{ $0.name == requiredQueryItem.key }) else { return nil }
					switch requiredQueryItem.value {
					case .present:
						continue
					case .value(let matchString):
						guard let foundValueString = foundValue.value else { return nil }
						if !matchString.matchesWildCards(foundValueString, rules:rules) {
							return nil
						}
					}
				}
			}
			else if case .dictionary(let allQueryItems) = requiredQueryItems
						,allQueryItems.count > 0 {
				//if there are no query items in the url, but we require some, we fail the match
				return nil
			}
			else if case .string(_) = requiredQueryItems {
				return nil
			}
		}
		if let fragment = self.fragment {
			if !fragment.matchesWildCards(url.fragment ?? "", rules:rules) {
				return nil
			}
		}
		return exclude == true ? false : true
	}
}


extension String {
	
	///interprets self as being one of apple's custom wildcard matching strings, and check if literal matches it
	func matchesWildCards(_ literal:String, rules:MatchRules = MatchRules())->Bool {
		let options:NSRegularExpression.Options = rules.caseSensitive ? [] : [.caseInsensitive]
		guard let regex = try? NSRegularExpression(appleWildcard: self, options: options, substitutions: rules.substitutions) else {
			return false
		}
		return regex.firstMatch(in: literal, range:NSRange(location: 0, length: literal.utf16.count)) != nil
	}
	
}


public enum QueryMatching {
	case present
	case value(String)
}


public struct MatchRules {
	public var caseSensitive:Bool
	public var percentEncoded:Bool
	public var substitutions:[String:[String]]
	
	public init(caseSensitive:Bool = true, percentEncoded:Bool = true, substitutions:[String:[String]] = [:]) {
		self.caseSensitive = caseSensitive
		self.percentEncoded = percentEncoded
		self.substitutions = substitutions
	}
}


extension NSRegularExpression {
	
	convenience init(appleWildcard:String, options:Options, substitutions:[String:[String]])throws {
		try self.init(pattern: appleWildcard.regularExpressionFromAppleWildCard(substitutions: substitutions), options: options)
	}
	
}


extension String {
	
	func regularExpressionFromAppleWildCard(substitutions:[String:[String]])->String {
		var pattern = self
		//escape most regex meta characters, except those we need to recognize substitution variables
		pattern.escapeCharacters(from:CharacterSet.regexPreSubstitutionEscapeSet)
		//replace ? as one any char
		pattern = pattern.replacingOccurrences(of: "?", with: ".")
		//detect replace $(......)
		let standardReplacements:[String:String] = [
			"alpha":"[a-zA-Z]",
			"upper":"[A-Z]",
			"lower":"[a-z]",
			"alnum":"[a-zA-Z0-9]",
			"digit":"[0-9]",
			"xdigit":"[0-9z-fA-F]",
		]
		for (key, value) in standardReplacements {
			pattern = pattern.replacingOccurrences(of: "$(\(key))", with: value)
		}
		//TODO: any ( not preceeded by a $ should be replaced by \(, and the matching ) should be considered
		for (key, replacements) in substitutions {
			pattern = pattern.replacingOccurrences(of: "$(\(key))"
												   ,with: "(?:" + replacements.joined(separator: "|") + ")")
		}
		if pattern.range(of: "$(region)") != nil {
			pattern = pattern.replacingOccurrences(of: "$(region)"
												   ,with: "(?:" + Locale.isoRegionCodes.joined(separator: "|") + ")")
		}
		if pattern.range(of: "$(lang)") != nil {
			pattern = pattern.replacingOccurrences(of: "$(lang)"
												   ,with: "(?:" + Locale.isoLanguageCodes.joined(separator: "|") + ")")
		}
		//escape everything that might be a meta character except * or ?
		pattern.escapeCharacters(from:CharacterSet.regexPostSubstitutionEscapeSet)
		//replace ?* as one or more chars
		pattern = pattern.replacingOccurrences(of: "?*", with: ".+")
		//replace * as zero or more chars
		pattern = pattern.replacingOccurrences(of: "*", with: ".*")
		//insert anchors
		pattern = "^" + pattern + "$"
		return pattern
	}
	
	mutating func escapeCharacters(from set:CharacterSet) {
		var targetIndex = endIndex
		while targetIndex > startIndex {
			guard let range = rangeOfCharacter(from: set, options: [.backwards], range: startIndex..<targetIndex) else { break }
			let foundSubString = String(self[range])
			replaceSubrange(range, with: "\\"+foundSubString)
			targetIndex = range.lowerBound
		}
	}
	
}


extension CharacterSet {
	//without ? or * because those have special meaning
	static let regexPreSubstitutionEscapeSet:CharacterSet = CharacterSet(charactersIn: "\\[]{}+|^./")
	static let regexPostSubstitutionEscapeSet:CharacterSet = CharacterSet(charactersIn: "$")
	
}
