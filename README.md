# WKZombie
[![Twitter: @mkoehnke](https://img.shields.io/badge/contact-@mkoehnke-blue.svg?style=flat)](https://twitter.com/mkoehnke)
[![Version](https://img.shields.io/cocoapods/v/WKZombie.svg?style=flat)](http://cocoadocs.org/docsets/WKZombie)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SPM compatible](https://img.shields.io/badge/SPM-compatible-orange.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![License](https://img.shields.io/cocoapods/l/WKZombie.svg?style=flat)](http://cocoadocs.org/docsets/WKZombie)
[![Platform](https://img.shields.io/cocoapods/p/WKZombie.svg?style=flat)](http://cocoadocs.org/docsets/WKZombie)
[![Build Status](https://travis-ci.org/mkoehnke/WKZombie.svg?branch=master)](https://travis-ci.org/mkoehnke/WKZombie)

[<img align="left" src="https://raw.githubusercontent.com/mkoehnke/WKZombie/master/Resources/Documentation/Logo.png" hspace="30" width="140px">](#logo)

WKZombie is an **iOS/OSX web-browser without a graphical user interface**. It was developed as an experiment in order to familiarize myself with **using functional concepts** written in **Swift 4**.

It incorporates [WebKit](https://webkit.org) (WKWebView) for rendering and [hpple](https://github.com/topfunky/hpple) (libxml2) for parsing the HTML content. In addition, it can take snapshots and has rudimentary support for parsing/decoding [JSON elements](#json-elements). **Chaining asynchronous actions makes the code compact and easy to use.**

## Use Cases
There are many use cases for a Headless Browser. Some of them are:

* Collect data without an API
* Scraping websites
* Automating interaction of websites
* Manipulation of websites
* Running automated tests / snapshots
* etc.

## Example
The following example is supposed to demonstrate the WKZombie functionality. Let's assume that we want to **show all iOS Provisioning Profiles in the Apple Developer Portal**.

#### Manual Web-Browser Navigation

When using a common web-browser (e.g. Mobile Safari) on iOS, you would typically type in your credentials, sign in and navigate (via links) to the *Provisioning Profiles* section:

<img src="https://raw.githubusercontent.com/mkoehnke/WKZombie/master/Resources/Documentation/WKZombie-Web-Demo.gif" />

#### Automation with WKZombie

The same navigation process can be reproduced **automatically** within an iOS/OSX app linking WKZombie *Actions*. In addition, it is now possible to manipulate or display this data in a native way with *UITextfield*, *UIButton* and a *UITableView*.

<img src="https://raw.githubusercontent.com/mkoehnke/WKZombie/master/Resources/Documentation/WKZombie-Simulator-Demo.gif" />

**Take a look at the iOS/OSX demos in the `Example` directory to see how to use it.**

# Getting Started

## iOS / OSX

The best way to get started is to look at the sample project. Just run the following commands in your shell and you're good to go:

```bash
$ cd Example
$ pod install
$ open Example.xcworkspace
```

__Note:__ You will need CocoaPods 1.0 beta4 or higher.

## Command-Line

For a Command-Line demo, run the following commands inside the `WKZombie` root folder:

```ogdl
$ swift build -Xcc -I/usr/include/libxml2 -Xlinker -lxml2

$ .build/debug/Example <appleid> <password>
```


# Usage
A WKZombie instance equates to a web session. Top-level convenience methods like *WKZombie.open()* use a shared instance, which is configured with the default settings.

As such, the following three statements are equivalent:

```ruby
let action : Action<HTMLPage> = open(url)
```

```ruby
let action : Action<HTMLPage> = WKZombie.open(url)
```

```ruby
let browser = WKZombie.sharedInstance
let action : Action<HTMLPage> = browser.open(url)
```

Applications can also create their own WKZombie instance:

```ruby
self.browser = WKZombie(name: "Demo")
```

Be sure to keep `browser` in a stored property for the time of being used.

### a. Chaining Actions

Web page navigation is based on *Actions*, that can be executed **implicitly** when chaining actions using the [`>>>`](#operators) or [`>>*`](#operators) (for snapshots) operators. All chained actions pass their result to the next action. The [`===`](#operators) operator then starts the execution of the action chain.

The following snippet demonstrates how you would use WKZombie to **collect all Provisioning Profiles** from the Developer Portal and **take snapshots of every page**:

```ruby
    open(url)
>>* get(by: .id("accountname"))
>>> setAttribute("value", value: user)
>>* get(by: .id("accountpassword"))
>>> setAttribute("value", value: password)
>>* get(by: .name("form2"))
>>> submit
>>* get(by: .contains("href", "/account/"))
>>> click(then: .wait(2.5))
>>* getAll(by: .contains("class", "row-"))
=== myOutput
```

In order to output or process the collected data, one can either use a closure or implement a custom function taking the result as parameter:

```ruby
func myOutput(result: [HTMLTableColumn]?) {
  // handle result
}
```

or

```ruby
func myOutput(result: Result<[HTMLTableColumn]>) {
  switch result {
  case .success(let value): // handle success
  case .error(let error): // handle error
  }
}
```

### b. Manual Actions

*Actions* can also be started manually by calling the *start()* method:

```ruby
let action : Action<HTMLPage> = browser.open(url)

action.start { result in
    switch result {
    case .success(let page): // process page
    case .error(let error):  // handle error
    }
}
```

This is certainly the less complicated way, but you have to write a lot more code, which might become confusing when you want to execute *Actions* successively.  


## Basic Action Functions
There are currently a few *Actions* implemented, helping you visit and navigate within a website:

### Open a Website

The returned WKZombie Action will load and return a HTML or JSON page for the specified URL.

```ruby
func open<T : Page>(url: URL) -> Action<T>
```

Optionally, a *PostAction* can be passed. This is a special wait/validation action, that is performed after the page has finished loading. See [PostAction](#special-parameters) for more information.

```ruby
func open<T : Page>(then: PostAction) -> (url: URL) -> Action<T>
```

### Get the current Website

The returned WKZombie Action will retrieve the current page.

```ruby
func inspect<T: Page>() -> Action<T>
```

### Submit a Form

The returned WKZombie Action will submit the specified HTML form.

```ruby
func submit<T : Page>(form: HTMLForm) -> Action<T>
```

Optionally, a *PostAction* can be passed. See [PostAction](#special-parameters) for more information.

```ruby
func submit<T : Page>(then: PostAction) -> (form: HTMLForm) -> Action<T>
```

### Click a Link / Press a Button

The returned WKZombie Actions will simulate the interaction with a HTML link/button.

```ruby
func click<T: Page>(link : HTMLLink) -> Action<T>
func press<T: Page>(button : HTMLButton) -> Action<T>
```

Optionally, a *PostAction* can be passed. See [PostAction](#Special- Parameters) for more information.

```ruby
func click<T: Page>(then: PostAction) -> (link : HTMLLink) -> Action<T>
func press<T: Page>(then: PostAction) -> (button : HTMLButton) -> Action<T>
```

**Note: HTMLButton only works if the "onClick" HTML-Attribute is present. If you want to submit a HTML form, you should use [Submit](#submit-a-form) instead.**

### Find HTML Elements

The returned WKZombie Action will search the specified HTML page and return the first element matching the generic HTML element type and passed [SearchType](#special-parameters).

```ruby
func get<T: HTMLElement>(by: SearchType<T>) -> (page: HTMLPage) -> Action<T>
```

The returned WKZombie Action will search and return all elements matching.

```ruby
func getAll<T: HTMLElement>(by: SearchType<T>) -> (page: HTMLPage) -> Action<[T]>
```


### Set an Attribute

The returned WKZombie Action will set or update an existing attribute/value pair on the specified HTMLElement.
```ruby
func setAttribute<T: HTMLElement>(key: String, value: String?) -> (element: T) -> Action<HTMLPage>
```

### Execute JavaScript

The returned WKZombie Actions will execute a JavaScript string.

```ruby
func execute(script: JavaScript) -> (page: HTMLPage) -> Action<JavaScriptResult>
func execute(script: JavaScript) -> Action<JavaScriptResult>
```

For example, the following example shows how retrieve the title of the currently loaded website using the *execute()* method:

```ruby
    browser.inspect
>>> browser.execute("document.title")
=== myOutput

func myOutput(result: JavaScriptResult?) {
  // handle result
}
```

The following code shows another way to execute JavaScript, that is e.g. value of an attribute:

```ruby
    browser.open(url)
>>> browser.get(by: .id("div"))
>>> browser.map { $0.objectForKey("onClick")! }
>>> browser.execute
>>> browser.inspect
=== myOutput

func myOutput(result: HTMLPage?) {
  // handle result
}
```

### Fetching

Some HTMLElements, that implement the _HTMLFetchable_ protocol (e.g. _HTMLLink_ or _HTMLImage_), contain attributes like _"src"_ or _"href"_, that link to remote objects or data.
The following method returns a WKZombie Action that can conveniently download this data:

```ruby
func fetch<T: HTMLFetchable>(fetchable: T) -> Action<T>
```

Once the _fetch_ method has been executed, the data can be retrieved and __converted__. The following example shows how to convert data, fetched from a link, into an UIImage:

```ruby
let image : UIImage? = link.fetchedContent()
```

Fetched data can be converted into types, that implement the _HTMLFetchableContent_ protocol. The following types are currently supported:

- UIImage / NSImage
- Data

__Note:__ See the OSX example for more info on how to use this.

### Transform

The returned WKZombie Action will transform a WKZombie object into another object using the specified function *f*.

```ruby
func map<T, A>(f: T -> A) -> (element: T) -> Action<A>
```

This function transforms an object into another object using the specified function *f*.

```ruby
func map<T, A>(f: T -> A) -> (object: T) -> A
```

## Taking Snapshots

Taking snapshots is **available for iOS**. First, a *snapshotHandler* must be registered, that will be called each time a snapshot has been taken:

```ruby
WKZombie.sharedInstance.snapshotHandler = { snapshot in
    let image = snapshot.image
}
```

Secondly, adding the `>>*` operator will trigger the snapshot event:

```ruby
    open(url)
>>* get(by: .id("element"))
=== myOutput
```
**Note: This operator only works with the WKZombie shared instance.**

Alternatively, one can use the *snap* command:

```ruby
    browser.open(url)
>>> browser.snap
>>> browser.get(by: .id("element"))
=== myOutput
```

Take a look at the **iOS example for more information** of how to take snapshots.


## Special Parameters

### 1. PostAction

Some *Actions*, that incorporate a (re-)loading of webpages (e.g. [open](#open-a-website), [submit](#submit-a-form), etc.), have *PostActions* available. A *PostAction* is a wait or validation action, that will be performed after the page has finished loading:

PostAction                | Description
------------------------- | -------------
**wait** (Seconds)        | The time in seconds that the action will wait (after the page has been loaded) before returning. This is useful in cases where the page loading has been completed, but some JavaScript/Image loading is still in progress.
**validate** (Javascript) | The action will complete if the specified JavaScript expression/script returns 'true' or a timeout occurs.

### 2. SearchType

In order to find certain HTML elements within a page, you have to specify a *SearchType*. The return type of [get()](#find-html-elements) and [getAll()](#find-html-elements) is generic and determines which tag should be searched for. For instance, the following would return all links with the class *book*:

```ruby
let books : Action<HTMLLink> = browser.getAll(by: .class("book"))(page: htmlPage)
```

The following 6 types are currently available and supported:

SearchType                     | Description
------------------------------ | -------------
**id** (String)                | Returns an element that matches the specified id.
**name** (String)              | Returns all elements matching the specified value for their *name* attribute.
**text** (String)              | Returns all elements with inner content, that *contain* the specified text.
**class** (String)             | Returns all elements that match the specified class name.
**attribute** (String, String) | Returns all elements that match the specified attribute name/value combination.
**contains** (String, String)  | Returns all elements with an attribute containing the specified value.
**XPathQuery** (String)        | Returns all elements that match the specified XPath query.

## Operators

The following Operators can be applied to *Actions*, which makes chained *Actions* easier to read:

Operator    | iOS | OSX | Description
:----------:|:---:|:---:| ---------------
`>>>`       | x   | x   | This Operator equates to the *andThen()* method. Here, the left-hand side *Action* will be started and the result is used as parameter for the right-hand side *Action*. **Note:** If the right-hand side *Action* doesn't take a parameter, the result of the left-hand side *Action* will be ignored and not passed.
`>>*`       | x   |     | This is a convenience operator for the _snap_ command. It is equal to the `>>>` operator with the difference that a snapshot will be taken after the left Action has been finished. **Note: This operator throws an assert if used with any other than the shared instance.**
`===`       | x   | x   | This Operator starts the left-hand side *Action* and passes the result as **Optional** to the function on the right-hand side.

## Authentication

Once in a while you might need to handle authentication challenges e.g. *Basic Authentication* or *Self-signed Certificates*. WKZombie provides an `authenticationHandler`, which is invoked when the internal web view needs to respond to an authentication challenge.

### Basic Authentication

The following example shows how Basic Authentication could be handled:

```ruby
browser.authenticationHandler = { (challenge) -> (URLSession.AuthChallengeDisposition, URLCredential?) in
	return (.useCredential, URLCredential(user: "user", password: "passwd", persistence: .forSession))
}

```

### Self-signed Certificates

In case of a self-signed certificate, you could use the authentication handler like this:

```ruby
browser.authenticationHandler = { (challenge) -> (URLSession.AuthChallengeDisposition, URLCredential?) in
	return (.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
}

```


## Advanced Action Functions

### Batch

The returned WKZombie Action will make a bulk execution of the specified action function *f* with the provided input elements. Once all actions have finished executing, the collected results will be returned.

```ruby
func batch<T, U>(f: T -> Action<U>) -> (elements: [T]) -> Action<[U]>
```

### Collect

The returned WKZombie Action will execute the specified action (with the result of the previous action execution as input parameter) until a certain condition is met. Afterwards, it will return the collected action results.

```ruby
func collect<T>(f: T -> Action<T>, until: T -> Bool) -> (initial: T) -> Action<[T]>
```

### Swap

**Note:** Due to a XPath limitation, WKZombie can't access elements within an `iframe` directly. The swap function can workaround this issue by switching web contexts.

The returned WKZombie Action will swap the current page context with the context of an embedded `<iframe>`.

```ruby
func swap<T: Page>(iframe : HTMLFrame) -> Action<T>
func swap<T: Page>(then postAction: PostAction) -> (iframe : HTMLFrame) -> Action<T>
```

The following example shows how to press a button that is embedded in an iframe:

```ruby
    browser.open(startURL())
>>> browser.get(by: .XPathQuery("//frame[@name='button_frame']"))
>>> browser.swap
>>> browser.get(by: .id("button"))
>>> browser.press
=== myOutput
```

## Test / Debug

### Dump

This command is useful for **debugging**. It prints out the current state of the WKZombie browser represented as *DOM*.

```ruby
func dump()
```

### Clear Cache and Cookies

Clears the cache/cookie data (such as login data, etc).

```ruby
func clearCache()
```

### Logging

WKZombie logging can be enabled or disabled by setting the following _Logger_ variable:

```ruby
Logger.enabled = false
```

### User Agent

The user agent of WKZombie can be changed by setting the following variable:

```ruby
browser.userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 9_0 like Mac OS X) AppleWebKit/601.1.32 (KHTML, like Gecko) Mobile/13A4254v"
```

### Timeout

An operation is cancelled if the time it needs to complete exceeds the time specified by this property. The default value is 30 seconds.

```ruby
browser.timeoutInSeconds = 15.0
```

### Load Media Content

This value is 'true' by default. If set 'false', the loading progress will finish once the 'raw' HTML data has been transmitted. Media content such as videos or images won't be loaded. 

```ruby
browser.loadMediaContent = false
```

### Show Network Activity

If set to ``true``, it will show the network activity indicator in the status bar. The default is ``true``.

```ruby
browser.showNetworkActivity = true
```


## HTML Elements

When using WKZombie, the following classes are involved when interacting with websites:

### HTMLPage

This class represents a **read-only** DOM of a website. It allows you to search for HTML elements using the [SearchType](#special-parameters) parameter.

### HTMLElement

The *HTMLElement* class is a **base class for all elements in the DOM**. It allows you to inspect attributes or the inner content (e.g. text) of that element. Currently, there are 7 subclasses with additional element-specific methods and variables available:

* HTMLForm
* HTMLLink
* HTMLButton
* HTMLImage
* HTMLTable
* HTMLTableColumn
* HTMLTableRow

**Additional subclasses can be easily implemented and might be added in the future.**

## JSON Elements

As mentioned above, WKZombie as rudimentary support for JSON documents.

### Methods and Protocols

For parsing and decoding JSON, the following methods and protocols are available:

#### Parsing
The returned WKZombie Action will parse Data and create a JSON object.

```ruby
func parse<T: JSON>(data: Data) -> Action<T>
```

#### Decoding
The following methods return a WKZombie Action, that will take a *JSONParsable* (Array, Dictionary and JSONPage) and decode it into a Model object. This particular Model class has to implement the [*JSONDecodable*](#jsondecodable) protocol.

```ruby
func decode<T : JSONDecodable>(element: JSONParsable) -> Action<T>
```

```ruby
func decode<T : JSONDecodable>(array: JSONParsable) -> Action<[T]>
```

#### JSONDecodable
This protocol must be implemented by each class, that is supposed to support JSON decoding.
The implementation will take a *JSONElement* (Dictionary\<String : AnyObject\>) and create an object instance of that class.

```ruby
static func decode(json: JSONElement) -> Self?
```


### Example

The following example shows how to use JSON parsing/decoding in conjunction with WKZombie:

```ruby
    browser.open(bookURL)
>>> browser.decode
=== myOutput
```

```ruby
func myOutput(result: Book?) {
  // handle result
}
```

# Installation

## [CocoaPods](http://cocoapods.org)

To integrate `WKZombie` into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

pod 'WKZombie'
```

Then, run the following command:

```bash
$ pod install
```

## [Carthage](http://github.com/Carthage/Carthage)

To integrate `WKZombie` into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "mkoehnke/WKZombie"
```

## [Swift Package Manager](http://github.com/apple/swift-package-manager)

To build `WKZombie` using the Swift Package Manager, add it as dependency to your `Package.swift` file and run the following command:

```ogdl
swift build -Xcc -I/usr/include/libxml2 -Xlinker -lxml2
```

# FAQ

## How can I use WKZombie and [Alamofire](https://github.com/Alamofire/Alamofire) in the same project?

When using Alamofire and WKZombie in the same project, you might encounter a collision issue with keyword `Result` like this:

```
'Result' is ambiguous for type lookup in this context
```

This is due to the fact, that both modules use the same name for their result enum type. The type can be disambiguated using the following syntax in that particular file:

```ruby
import enum WKZombie.Result
```

From this point on, Result unambiguously refers to the one in the WKZombie module.

If this would still be ambiguous or sub-optimal in some files, you can create a Swift file to rename imports using typealiases:


```ruby
import enum WKZombie.Result
typealias WKZombieResult<T> = Result<T>
```

For more information, take a look at the solution found [here](https://stackoverflow.com/questions/37892621/how-can-i-disambiguate-a-type-and-a-module-with-the-same-name).


# Contributing

See the CONTRIBUTING file for how to help out. You'll need to run

```bash
$ Scripts/setup-framework.sh
```

in the root WKZombie directory to set up a buildable framework project (`WKZombie.xcworkspace`).

# TODOs
* More Unit Tests
* More examples
* Replace hpple with more 'Swifty' implementation
* More descriptive errors

# Author
Mathias Köhnke [@mkoehnke](http://twitter.com/mkoehnke)

# More Resources
* [A list of (almost) all headless web browsers in existence](https://github.com/dhamaniasad/HeadlessBrowsers)

# Attributions
* [Efficient JSON in Swift with Functional Concepts and Generics — Tony DiPasquale](https://robots.thoughtbot.com/efficient-json-in-swift-with-functional-concepts-and-generics)
* [Back to the Futures — Javier Soto](https://speakerdeck.com/javisoto/back-to-the-futures)

# License
WKZombie is available under the MIT license. See the LICENSE file for more info.

# Recent Changes
The release notes can be found [here](https://github.com/mkoehnke/WKZombie/releases).
