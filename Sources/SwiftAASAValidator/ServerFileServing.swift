import Foundation

extension URL {
	
	///if self is a domain url, the locations of app site association files
	public func urlsForAppleAppSiteAssociation()throws->[URL] {
		return [
			try wellKnownAppleAppSiteAssociation(),
			try rootAppleAppSiteAssociation(),
		]
	}
	
	
	///if self is a domain url, this returns the preferred url for the apple app site association file
	public func wellKnownAppleAppSiteAssociation()throws->URL {
		guard self.scheme == "https" else {
			throw AppleAppSiteAssociationUrlError.schemeIsNotHTTPS
		}
		guard !(host ?? "").isEmpty else {
			throw AppleAppSiteAssociationUrlError.hostIsNotFullyQualifiedDomain
		}
		guard path == "/" || path.isEmpty else {
			throw AppleAppSiteAssociationUrlError.pathIsNotEmpty
		}
		return self
			.appendingPathComponent(".well-known")
			.appendingPathComponent("apple-app-site-association")
	}
	
	///if self is a domain url, this returns the backup url for the apple app site association file
	public func rootAppleAppSiteAssociation()throws->URL {
		guard self.scheme == "https" else {
			throw AppleAppSiteAssociationUrlError.schemeIsNotHTTPS
		}
		guard !(host ?? "").isEmpty else {
			throw AppleAppSiteAssociationUrlError.hostIsNotFullyQualifiedDomain
		}
		guard path == "/" || path.isEmpty else {
			throw AppleAppSiteAssociationUrlError.pathIsNotEmpty
		}
		return self
			.appendingPathComponent("apple-app-site-association")
	}
	
}


public enum AppleAppSiteAssociationUrlError : Error {
	case schemeIsNotHTTPS
	case hostIsNotFullyQualifiedDomain
	case pathIsNotEmpty
	
}

//TODO: write me - determine if a server has an apple-app-site-association file at one of the required paths, and return it if possible
