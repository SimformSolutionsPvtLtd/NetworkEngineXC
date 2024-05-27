# NetworkEngine

[![Swift 5.0][swift-badge]][swift-org]
[![Swift Package Manager][spm-badge]][compatible-badge]

Network engine is the networking framework on top of [Alamofire][alamofire], for simplified and testable network.
It supports combine (publishers pattern) and swift async await.

## Installation

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. 

Once you have your Swift package set up, adding Alamofire as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/SimformSolutionsPvtLtd/NetworkEngineXC.git", .upToNextMajor(from: "2.0.0"))
]
```
## Usage

### TargetType: Define the network repository

Confirm to `TargetType` protocol and define your network repo as below, based on your requirements you can define multiple repos same as this one.

```swift
protocol NetworkRepo: TargetType & NetworkRequestable {
    static var refreshToken: Self { get }
    static func login(email: String, password: String) -> Self
    static func demo(demoData: DemoRequestModel) -> Self
    static func fetchUsers(userListRequest: UserListRequest) -> Self
}
```
where `NetworkRequestable` defines the available methods for network calls

```swift
protocol NetworkRequestable {

    func request<T: Decodable>(type: T.Type,
                               callback: @escaping (Result<T, CustomError>) -> Void) -> NetworkRequest
}
```

Implement the `NetworkRepo` and define the required variables and methods using enum with example name `APITarget`.

```swift
public enum APITarget: NetworkRepo {
    case refreshToken
    case login(email: String, password: String)
    case demo(demoData: DemoRequestModel)
    case fetchUsers(userListRequest: UserListRequest)
}
```

### NetworkProvider: Make the network calls

For the network calls in `request` method of the `NetworkRequestable`, create `NetworkProvider` instance

```swift
static let interceptor = DefaultInterceptor(refreshTokenCall, isNetworkReachable)
static let provider = NetworkProvider<APITarget>(interceptor: interceptor)
```
where the `DefaultInterceptor` is the default interceptor initialized with `refreshTokenCall` and `isNetworkReachable` closures.

### NetworkRequestInterceptor: Intercept the network calls

Define your own interceptor using `NetworkRequestInterceptor`. Define `retry`, `adapt` methods then pass your custom interceptor to the `NetworkProvider`

### NetworkTask

The `NetworkTask` defines how you can request the data/files.

```swift
case requestPlain
```
This network task just requests the plain URL formed via basURl and path components of `NetworkTask`

```swift
case requestData(Data)
```
This task forms an HTTP request with the given `Data` in body of the request.

```swift
case requestJSONEncodable(Encodable)
```
This task forms and HTTP request by encoding the given `Encodable` using `JSONEncoder` and add setting the encoded data as request body.

```swift
case requestCustomJSONEncodable(Encodable, encoder: JSONEncoder)
```
This task does the same as above one, only difference is that it uses the provided encoder. Use this task if your request body needs some unconventional encoding and you need to handle it yourself by providing you preconfigured encoder.

```swift
case requestParameterEncodable(Encodable)
```
This task converts the given `Encodable` as key value dictionary and passes them as query string for the URL formation.


```swift
case requestParameters(parameters: [String: Any], encoding: ParameterEncoding)
```
Queries the given parameters using given `ParameterEncoding` method.

```swift
case requestCompositeData(bodyData: Data, urlParameters: [String: Any])
```
Set the given url parameters and body data in request.

```swift
case requestCompositeParameters(bodyParameters: [String: Any], urlParameters: [String: Any])
```
Encode the body parameters in to body of the request and append the url parameter in to query string of URL

```swift
case uploadFile(URL)
```
Upload the file at the given URL to the destination endpoint

```swift
case uploadMultipart([MultipartFormData])
```
Upload the multipart from data

```swift
case uploadCompositeMultipart([MultipartFormData], urlParameters: [String: Any])
```
Upload the multiple form data

```swift
case downloadDestination(DownloadDestination)
```
Download the data using given download destination 

```swift
case downloadParameters(parameters: [String: Any],
                        encoding: ParameterEncoding,
                        destination: DownloadDestination)
```
Form a download request using given parameters and download the data using given download destination 

### Errors

Errors are thrown in form of `NetworkError`.

```swift
case networkError(_ error: AFError, _ response: HTTPURLResponse?, _ data: Data?)
```
This error is a wrapper on error thrown from Alamofire side with additional info

```swift
case encodableParameterFailure(error: Error)
```
Thrown when `NetworkTask.requestParameterEncodable` fails to encode the given encodable in to request parameters.

```swift
case jsonDictionaryConversionFailed
```
Json to Dictionary conversion failed for URL parameter encoding

# Writing Testable APIs

Once you have declared `NetworkRepo` which conforms to `TargetType` and `NetworkRequestable`.

Follow below steps to make your APIs testable
1. Use constructor injection to provide the network repo to you **ViewModel** instead of declaring a member inside the **ViewModel**
2. Always pass your `NetowrkRepo` into your ViewModels instead of concrete implementations such as `APITarget`
3. Declare your mock implementations of `NetworkRepo`
4. Inject mock implementation of `NetworkRepo` in to your SUT (system under test, here ViewModel)
5. Write the test cases to for the expected behaviour of the SUT

Let's walk through an example:

### ViewModel Declaration
```swift
class MyViewModel {

    // MARK: Private variables
    private let networkRepo: NetworkRepo.Type
    private var apiCalls = [NetworkRequest]()
    private var pageNumber = 0
    
    // MARK: Dynamic vars
    let userLists: Dynamic<[UserData]> = Dynamic([])
    let error: Dynamic<CustomError?> = Dynamic(nil)
    let showLoading: Dynamic<Bool> = Dynamic(false)

    // MARK: Initialization
    init(networkRepo: NetworkRepo.Type) {
        self.networkRepo = networkRepo
    }
    
    /// Get new page
    func getNewPage() {
        pageNumber += 1
        let requestURLParameters = UserListRequest(results: 10, page: pageNumber)
        let usersListCall = networkRepo.fetchUsers(userListRequest: requestURLParameters)
        showLoading.value = true
        let request = usersListCall.request(type: UserListResponse.self) { [weak self] result in
            self?.showLoading.value = false
            switch result {
            case .success(let userResponse):
                self?.userLists.value = userResponse.results
            case .failure(let error):
                self?.error.value = error
            }
        }
        apiCalls.append(request)
    }

    deinit {
        // Cancel the API calls if the view model is de-initialized
        apiCalls.cancel()
    }
}
```

### NetworkRepo Protocol
Your `NetworkRepo` contains a call to fetch user list
```swift
protocol NetworkRepo: TargetType & NetworkRequestable {
    static func fetchUsers(userListRequest: UserListRequest) -> Self
}
```

### Mock Implementation
Then you can create a `MockAPITarget` using this network repo same as you created the `APITarget`
```swift
public enum MockAPITarget: NetworkRepo {
    case fetchUsers(userListRequest: UserListRequest)
}
```
```swift
extension MockAPITarget {
    Define path, method, task, keyDecodingStrategy, headers for mocks
}
```
```swift
extension MockAPITarget {
    
    static var apiCallDelay = 4 // milliseconds
    static var errorToThrow: CustomError?

    public func request<T: Decodable>(type: T.Type,
                                      callback: @escaping (Result<T, CustomError>) -> Void) -> NetworkRequest {
        self.sendMockResponse(callback)
        return MockNetworkRequest()
    }

    // swift_lint: cyclomatic_complexity
    private func sendMockResponse<T: Decodable>(_ callback: @escaping (Result<T, CustomError>) -> Void) {
        let asyncAfter: DispatchTime = .now() + DispatchTimeInterval.milliseconds(MockAPITarget.apiCallDelay)
        DispatchQueue.global().asyncAfter(deadline: asyncAfter) {
            if let errorToThrow = MockAPITarget.errorToThrow {
                callback(.failure(errorToThrow))
                return
            }
            switch self {
            case .fetchUsers:
                if let response = T.parse(jsonFile: "UserListResponse") {
                    callback(.success(response))
                    return
                }
            }
            callback(.failure(.genericError))
        }
    }
}
```
Where custom error is defined as below
```swift
struct CustomError: Error, Equatable {
    let title: String
    let body: String

    /// No internet error object
    static let noInternetError = CustomError(title: AppStrings.noInternetConnection(),
                                             body: AppStrings.pleaseConnectToInternet())

    /// Generic error object
    static let genericError = CustomError(title: AppStrings.genericError(),
                                          body: AppStrings.somethingWentWrong())
}
```
Where `MockNetworkRequest` is simple conformance to `NetworkRequest`
```swift
class MockNetworkRequest: NetworkRequest {
    
    var isCancelled: Bool = false
    
    func cancel() {
        if isCancelled { return }
        isCancelled = true
    }
}
```
The `parse` method on `Decodable` is declared as below
```swift
extension Decodable {
    
  static func parse(jsonFile: String) -> Self? {
    guard let url = Bundle.main.url(forResource: jsonFile, withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let output = try? JSONDecoder().decode(self, from: data)
        else {
      return nil
    }
    return output
  }
}
```

### Writing Tests
Now, when writing test cases, just pass your mock implementation of NetworkRepo to your ViewModel
```swift
final class MyViewModelTests: XCTestCase {
    
    var sut: MyViewModel!
    
    override func setUpWithError() throws {
        sut = MyViewModel(networkRepo: MockAPITarget.self)
    }

    override func tearDownWithError() throws {
        sut = nil
        MockAPITarget.errorToThrow = nil
    }

    func testUserListAPISuccess() {
        // Given
        MockAPITarget.errorToThrow = nil

        sut.userLists.bind { users in
            // Then
            XCTAssert(!users.isEmpty)
            XCTAssert(users.count == 10)
        }
        sut.error.bind { error in
            // Then
            XCTAssertNil(error)
        }

        // When
        sut.getNewPage()
    }

    func testUserListAPIFailure() {
        // Given
        let errorToThrow = CustomError.noInternetError
        MockAPITarget.errorToThrow = errorToThrow

        sut.userLists.bind { users in
            // Then
            XCTAssert(false)
        }
        sut.error.bind { error in
            // Then
            XCTAssertNotNil(error)
            XCTAssert(error == errorToThrow)
        }

        // When
        sut.getNewPage()
    }
}
```

## License

```
MIT License

Copyright (c) 2023 Simform Solutions

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

[//]: # (These are reference links used in the body of this note and get stripped out when the markdown processor does its job. There is no need to format nicely because it shouldn't be seen. Thanks SO - http://stackoverflow.com/questions/4823468/store-comments-in-markdown-syntax)

   [swift-badge]: <https://img.shields.io/badge/Swift-5.0-orange.svg>
   [swift-org]: <https://swift.org>
   [alamofire]: <https://github.com/Alamofire/Alamofire>
   [compatible-badge]: <https://img.shields.io/badge/Swift_Package_Manager-compatible-orange>
   [spm-badge]: <https://img.shields.io/badge/Swift_Package_Manager-compatible-orange>

