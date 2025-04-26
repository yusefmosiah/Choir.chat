import Foundation
import SwiftUI
import UIKit

/// A singleton manager for caching paginated content across the app.
/// This centralizes pagination logic and improves performance by sharing
/// cache across multiple views and providing memory management.
class PaginationCacheManager {
    // MARK: - Singleton
    
    /// Shared instance for app-wide access
    static let shared = PaginationCacheManager()
    
    // MARK: - Cache Key
    
    /// Key for identifying cached content
    struct PageCacheKey: Hashable {
        let messageId: UUID
        let phase: Phase
        let width: CGFloat
        let height: CGFloat
        let contentHash: Int // Hash of the combined markdown content
        
        /// Creates a cache key with dimensions rounded to reduce cache fragmentation
        static func create(messageId: UUID, phase: Phase, size: CGSize, contentHash: Int) -> PageCacheKey {
            // Round dimensions to reduce cache misses from minor floating point differences
            let roundedWidth = (size.width * 10).rounded() / 10
            let roundedHeight = (size.height * 10).rounded() / 10
            
            return PageCacheKey(
                messageId: messageId,
                phase: phase,
                width: roundedWidth,
                height: roundedHeight,
                contentHash: contentHash
            )
        }
    }
    
    // MARK: - Cache Properties
    
    /// Main cache storage
    private var pageCache: [PageCacheKey: CacheEntry] = [:]
    
    /// LRU tracking for cache eviction
    private var lruQueue: [PageCacheKey] = []
    
    /// Maximum number of entries to keep in cache
    private let maxCacheEntries = 100
    
    /// Paginator instance for content pagination
    private let paginator = MarkdownPaginator()
    
    /// Queue for background pagination operations
    private let paginationQueue = DispatchQueue(label: "com.choir.paginationQueue", qos: .userInitiated)
    
    /// Lock for thread-safe cache access
    private let cacheLock = NSLock()
    
    // MARK: - Cache Entry
    
    /// Struct to store cache entries with metadata
    private struct CacheEntry {
        let pages: [String]
        let timestamp: Date
        let accessCount: Int
        
        init(pages: [String], timestamp: Date = Date(), accessCount: Int = 1) {
            self.pages = pages
            self.timestamp = timestamp
            self.accessCount = accessCount
        }
        
        /// Returns a new entry with incremented access count
        func incrementAccess() -> CacheEntry {
            return CacheEntry(pages: pages, timestamp: Date(), accessCount: accessCount + 1)
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Private initializer to enforce singleton pattern
        
        // Set up periodic cache cleanup
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.performCacheCleanup()
        }
    }
    
    // MARK: - Public Methods
    
    /// Gets paginated content for a specific phase and size
    /// - Parameters:
    ///   - phase: The phase to paginate
    ///   - messageId: The ID of the message
    ///   - content: The content to paginate
    ///   - size: The size constraints for pagination
    ///   - completion: Callback with paginated content
    func getPaginatedContent(
        for phase: Phase,
        messageId: UUID,
        content: String,
        size: CGSize,
        completion: @escaping ([String]) -> Void
    ) {
        // Validate input
        guard size.width > 0, size.height > 0 else {
            print("[PaginationCacheManager] Size invalid (\(size)), returning single page.")
            completion([content])
            return
        }
        
        // Ensure deep links are converted before pagination
        let textToPaginate = content.convertVectorReferencesToDeepLinks()
        let contentHash = textToPaginate.hashValue
        
        // Create cache key
        let cacheKey = PageCacheKey.create(
            messageId: messageId,
            phase: phase,
            size: size,
            contentHash: contentHash
        )
        
        // Check cache first (thread-safe)
        if let cachedPages = getCachedPages(for: cacheKey) {
            print("[PaginationCacheManager] Cache hit for \(phase) size \(size)")
            completion(cachedPages)
            return
        }
        
        // Cache miss - paginate in background
        print("[PaginationCacheManager] Cache miss for \(phase) size \(size). Paginating...")
        paginationQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Calculate available space for text
            let verticalPadding: CGFloat = 4
            let horizontalPadding: CGFloat = 4
            let availableTextHeight = max(20, size.height - verticalPadding)
            let availableTextWidth = max(8, size.width - horizontalPadding)
            
            // Get the current font for accessibility-aware measurement
            let bodyFont = UIFont.preferredFont(forTextStyle: .body)
            
            // Paginate the content
            let newPages = self.paginator.paginateMarkdown(
                textToPaginate,
                width: availableTextWidth,
                height: availableTextHeight,
                font: bodyFont
            )
            
            // Update cache
            self.cacheLock.lock()
            self.pageCache[cacheKey] = CacheEntry(pages: newPages)
            self.updateLRU(key: cacheKey)
            self.cacheLock.unlock()
            
            print("[PaginationCacheManager] Cached \(newPages.count) pages for \(phase) size \(size)")
            
            // Return result on main thread
            DispatchQueue.main.async {
                completion(newPages)
            }
        }
    }
    
    /// Gets paginated content synchronously (for use when immediate result is needed)
    /// - Returns: Array of paginated content strings
    func getPaginatedContentSync(
        for phase: Phase,
        messageId: UUID,
        content: String,
        size: CGSize
    ) -> [String] {
        // Validate input
        guard size.width > 0, size.height > 0 else {
            print("[PaginationCacheManager] Size invalid (\(size)), returning single page.")
            return [content]
        }
        
        // Ensure deep links are converted before pagination
        let textToPaginate = content.convertVectorReferencesToDeepLinks()
        let contentHash = textToPaginate.hashValue
        
        // Create cache key
        let cacheKey = PageCacheKey.create(
            messageId: messageId,
            phase: phase,
            size: size,
            contentHash: contentHash
        )
        
        // Check cache first (thread-safe)
        if let cachedPages = getCachedPages(for: cacheKey) {
            print("[PaginationCacheManager] Cache hit for \(phase) size \(size)")
            return cachedPages
        }
        
        // Cache miss - paginate synchronously
        print("[PaginationCacheManager] Cache miss for \(phase) size \(size). Paginating synchronously...")
        
        // Calculate available space for text
        let verticalPadding: CGFloat = 4
        let horizontalPadding: CGFloat = 4
        let availableTextHeight = max(20, size.height - verticalPadding)
        let availableTextWidth = max(8, size.width - horizontalPadding)
        
        // Get the current font for accessibility-aware measurement
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        
        // Paginate the content
        let newPages = paginator.paginateMarkdown(
            textToPaginate,
            width: availableTextWidth,
            height: availableTextHeight,
            font: bodyFont
        )
        
        // Update cache
        cacheLock.lock()
        pageCache[cacheKey] = CacheEntry(pages: newPages)
        updateLRU(key: cacheKey)
        cacheLock.unlock()
        
        print("[PaginationCacheManager] Cached \(newPages.count) pages for \(phase) size \(size)")
        
        return newPages
    }
    
    /// Preloads pagination for adjacent phases to improve perceived performance
    func preloadAdjacentPhases(
        currentPhase: Phase,
        availablePhases: [Phase],
        messageId: UUID,
        contentProvider: (Phase) -> String,
        size: CGSize
    ) {
        guard let currentIndex = availablePhases.firstIndex(of: currentPhase),
              size.width > 0, size.height > 0 else {
            return
        }
        
        // Define which adjacent phases to preload
        var phasesToPreload: [Phase] = []
        
        // Add previous phase if available
        if currentIndex > 0 {
            phasesToPreload.append(availablePhases[currentIndex - 1])
        }
        
        // Add next phase if available
        if currentIndex < availablePhases.count - 1 {
            phasesToPreload.append(availablePhases[currentIndex + 1])
        }
        
        // Preload each phase in background
        for phase in phasesToPreload {
            let content = contentProvider(phase)
            
            // Skip if content is empty
            if content.isEmpty {
                continue
            }
            
            // Use lower priority for preloading
            DispatchQueue.global(qos: .utility).async { [weak self] in
                self?.getPaginatedContent(
                    for: phase,
                    messageId: messageId,
                    content: content,
                    size: size
                ) { _ in
                    // Preloading complete, no need to do anything with the result
                    print("[PaginationCacheManager] Preloaded pagination for \(phase)")
                }
            }
        }
    }
    
    /// Invalidates cache entries for a specific message
    func invalidateCache(for messageId: UUID) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        // Remove all entries for this message
        let keysToRemove = pageCache.keys.filter { $0.messageId == messageId }
        for key in keysToRemove {
            pageCache.removeValue(forKey: key)
            if let index = lruQueue.firstIndex(of: key) {
                lruQueue.remove(at: index)
            }
        }
        
        print("[PaginationCacheManager] Invalidated \(keysToRemove.count) cache entries for message \(messageId)")
    }
    
    /// Clears the entire cache
    func clearCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        pageCache.removeAll()
        lruQueue.removeAll()
        
        print("[PaginationCacheManager] Cache cleared")
    }
    
    // MARK: - Private Methods
    
    /// Gets cached pages for a key and updates access metadata
    private func getCachedPages(for key: PageCacheKey) -> [String]? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        guard let entry = pageCache[key] else {
            return nil
        }
        
        // Update access metadata
        pageCache[key] = entry.incrementAccess()
        updateLRU(key: key)
        
        return entry.pages
    }
    
    /// Updates the LRU queue for a key
    private func updateLRU(key: PageCacheKey) {
        // Remove key if it exists in the queue
        if let index = lruQueue.firstIndex(of: key) {
            lruQueue.remove(at: index)
        }
        
        // Add key to the front of the queue (most recently used)
        lruQueue.insert(key, at: 0)
        
        // Enforce cache size limit
        if lruQueue.count > maxCacheEntries {
            evictLeastRecentlyUsed()
        }
    }
    
    /// Evicts the least recently used cache entry
    private func evictLeastRecentlyUsed() {
        guard !lruQueue.isEmpty else { return }
        
        // Get the least recently used key
        let keyToEvict = lruQueue.removeLast()
        
        // Remove from cache
        pageCache.removeValue(forKey: keyToEvict)
        
        print("[PaginationCacheManager] Evicted LRU cache entry for \(keyToEvict.phase)")
    }
    
    /// Performs periodic cache cleanup
    private func performCacheCleanup() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        // Get current time
        let now = Date()
        
        // Find entries older than 30 minutes with low access count
        let keysToRemove = pageCache.filter { key, entry in
            let ageInMinutes = now.timeIntervalSince(entry.timestamp) / 60
            return ageInMinutes > 30 && entry.accessCount < 3
        }.keys
        
        // Remove old entries
        for key in keysToRemove {
            pageCache.removeValue(forKey: key)
            if let index = lruQueue.firstIndex(of: key) {
                lruQueue.remove(at: index)
            }
        }
        
        if !keysToRemove.isEmpty {
            print("[PaginationCacheManager] Cleaned up \(keysToRemove.count) old cache entries")
        }
    }
}
