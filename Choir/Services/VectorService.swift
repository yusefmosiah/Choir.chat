import Foundation

/// Service for fetching and managing vector data
class VectorService {
    // MARK: - Singleton
    
    static let shared = VectorService()
    
    // MARK: - Properties
    
    /// Track active vector requests to prevent duplicates
    private var activeVectorRequests: Set<String> = []
    
    // MARK: - Public Methods
    
    /// Fetches a vector by ID from the API
    /// - Parameters:
    ///   - vectorId: The ID of the vector to fetch
    ///   - completion: Callback with the result (success, vectorResult, errorMessage)
    func fetchVector(
        vectorId: String,
        completion: @escaping (Bool, VectorSearchResult?, String?) -> Void
    ) {
        // Check if we're already fetching this vector
        if activeVectorRequests.contains(vectorId) {
            completion(false, nil, "A request for this vector is already in progress")
            return
        }
        
        // Mark this request as active
        activeVectorRequests.insert(vectorId)
        
        Task {
            do {
                let url = ApiConfig.url(for: "\(ApiConfig.Endpoints.vectors)/\(vectorId)")
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                
                // Add authentication if available
                if let authToken = UserDefaults.standard.string(forKey: "authToken") {
                    request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
                }
                
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "Invalid response", code: 0)
                }
                
                // Handle 404 Not Found
                if httpResponse.statusCode == 404 {
                    await MainActor.run {
                        self.activeVectorRequests.remove(vectorId)
                        completion(false, nil, "Vector not found")
                    }
                    return
                }
                
                // Handle other error status codes
                guard httpResponse.statusCode == 200 else {
                    throw NSError(domain: "Server error", code: httpResponse.statusCode)
                }
                
                // Decode the response
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(APIResponse<VectorResult>.self, from: data)
                
                guard apiResponse.success, let vectorData = apiResponse.data else {
                    throw NSError(domain: apiResponse.message ?? "Unknown error", code: 0)
                }
                
                // Convert VectorResult to VectorSearchResult
                let vectorResult = VectorSearchResult(
                    content: vectorData.content,
                    score: 1.0,
                    provider: "qdrant",
                    metadata: vectorData.metadata?.compactMapValues { $0 as? String },
                    id: vectorData.id,
                    content_preview: nil
                )
                
                await MainActor.run {
                    self.activeVectorRequests.remove(vectorId)
                    completion(true, vectorResult, nil)
                }
                
            } catch {
                await MainActor.run {
                    self.activeVectorRequests.remove(vectorId)
                    completion(false, nil, error.localizedDescription)
                }
            }
        }
    }
    
    /// Cancels an active vector request
    /// - Parameter vectorId: The ID of the vector request to cancel
    func cancelRequest(vectorId: String) {
        activeVectorRequests.remove(vectorId)
    }
    
    /// Checks if a vector request is currently active
    /// - Parameter vectorId: The ID of the vector to check
    /// - Returns: True if the vector is being fetched, false otherwise
    func isRequestActive(vectorId: String) -> Bool {
        return activeVectorRequests.contains(vectorId)
    }
}
