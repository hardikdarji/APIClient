# APIClient_Combine

This repository contains a **generic HTTP network layer** using **Combine** in Swift. It enables sending HTTP requests and decoding JSON responses into Swift models. It manages:

- Request building  
- Encoding the request body  
- Decoding the response  
- Mapping various errors into custom error types  

---

## 📌 Function Signature

```swift
func request<T: Decodable, U: Encodable>(
    endpoint: String,
    method: HTTPMethod,
    requestBody: U?,
    resultType: T.Type
) -> AnyPublisher<APIResponse<T>, APIError>

## Generics:
T: the expected response model (must conform to Decodable)
U: the request body model (must conform to Encodable)
Returns: a Combine Publisher that emits a decoded APIResponse<T> or fails with an APIError.

AuthViewModel.swift ==> shows usage for same, using AESCryption for every requst and response also wrapped in common response model codable

✅ Why This Is a Good Practice
=> Strongly typed API response handling
=> Error isolation and mapping into domain-specific types
=> Combine-friendly to allow reactive chaining
=> Good debug logging (URL, headers, body, and response)
=> Ready for unit testing by injecting URLSession or mocking this layer

✅ Summary
In request, tryMap	Called after receiving data + response
1. Pretty-print	Tries to print the JSON for debugging
2. Validate Response	Ensures it's an HTTP response
3. Decode	Tries to decode into APIResponse<T>
4. Status Handling	Based on statusCode, either returns or throws a specific error
