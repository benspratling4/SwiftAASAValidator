# SwiftAASAValidator
 Validate that `apple-app-site-association` files are set up correctly


The idea is you can use these functions in your test suite for doing automated tests on the validity of your apple-app-site-association file

## Fetching your `apple-app-site-association` files

To fetch the `apple-app-site-association` files, create a URL which is your domain, such as

```swift
let domainUrl:URL = URL(string:"https://www.example.com")!
``` 

and retrieve the two urls for the allowed locations like so:

```swift
let appleAppSiteAssociationURLs:[URL] = try! domainUrl.urlsForAppleAppSiteAssociation()
```

Then use the urls to fetch the files.  it shoudle exist at one of the two locations.


## Deserializing an `apple-app-site-association` file

Once you've fetched the Data of the `apple-app-site-association` file, deserialize it with a `JSONDecoder`, like so:

```swift
let appleAppSiteAssociation:AppleAppSiteAssociation = try! JSONDecoder().decode(AppleAppSiteAssociation.self, from: data)
``` 


## Testing matching URLs

Test which app ids can be linked for a given URL, using the `.matchedAppIds(...)` method.

```swift
let testUrl:URL = URL(string: "https://www.example.com/buy/")!
let testAppId:String = "ABCED1234.com.example.app"
XCTAssertEqual(appleAppSiteAssociation.applinks?.matchedAppIds(testUrl).contains(testAppId), true)
```

Each class within contains its own testing methods and its properties can be introspected.


## Unsupported features

`percentEncoded` is not handled correctly 

