import SwiftUI

struct PaginatedTextView: View {
    let text: String
    let availableSize: CGSize
    @Binding var currentPage: Int

    // Add callbacks for phase navigation
    var onNavigateToPreviousPhase: (() -> Void)?
    var onNavigateToNextPhase: (() -> Void)?

    // Internal state
    @State private var pages: [String] = [""]
    @State private var totalPages: Int = 1
    @Environment(\.sizeCategory) private var sizeCategory
    
    // Use monospace font for predictable text layout
    private let textFont = Font.system(.body, design: .monospaced)
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Text container with fixed size
                ZStack(alignment: .topLeading) {
                    // Background for the text area
                    Rectangle()
                        .fill(Color.clear)
                    
                    // The actual text content
                    if pages.indices.contains(currentPage) {
                        Text(pages[currentPage])
                            .font(textFont)
                            .lineSpacing(4)
                            .padding([.horizontal, .top], 4)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height - 40 // Reserve space for controls
                )
                
                Spacer(minLength: 0)
                
                // Page controls
                HStack {
                    Button(action: {
                        if currentPage > 0 {
                            currentPage -= 1
                        } else if let navigateToPrevious = onNavigateToPreviousPhase {
                            navigateToPrevious()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .imageScale(.small)
                            .padding(4)
                    }
                    .disabled(currentPage <= 0 && onNavigateToPreviousPhase == nil)
                    .foregroundColor(currentPage <= 0 && onNavigateToPreviousPhase == nil ? .gray : .accentColor)

                    Spacer()

                    Text("Page \(currentPage + 1) of \(totalPages)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button(action: {
                        if currentPage < totalPages - 1 {
                            currentPage += 1
                        } else if let navigateToNext = onNavigateToNextPhase {
                            navigateToNext()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .imageScale(.small)
                            .padding(4)
                    }
                    .disabled(currentPage >= totalPages - 1 && onNavigateToNextPhase == nil)
                    .foregroundColor(currentPage >= totalPages - 1 && onNavigateToNextPhase == nil ? .gray : .accentColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.secondarySystemBackground).opacity(0.6))
                .cornerRadius(8)
                .padding(.bottom, 2)
                .frame(height: 36)
            }
            .onAppear {
                splitTextIntoPages(size: geometry.size)
            }
            .onChange(of: text) { _, _ in
                splitTextIntoPages(size: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                splitTextIntoPages(size: newSize)
            }
            .onChange(of: sizeCategory) { _, _ in
                splitTextIntoPages(size: geometry.size)
            }
        }
    }
    
    // This is a completely new approach that creates a temporary view 
    // to measure text and find the optimal page breaks
    private func splitTextIntoPages(size: CGSize) {
        guard !text.isEmpty else {
            pages = [""]
            totalPages = 1
            currentPage = 0
            return
        }
        
        // Create a TextMeasurer to help us split text
        let measurer = TextMeasurer(sizeCategory: sizeCategory)
        
        // Reserve space for the pagination controls
        let textHeight = size.height - 40
        
        // Start with conservative estimates - we'll refine with actual measurement
        var resultPages: [String] = []
        var workingText = text
        
        // Process text until we've gone through it all
        while !workingText.isEmpty {
            // Try to fit as much text as possible in the current page
            let pageText = measurer.fitTextToHeight(text: workingText, width: size.width - 8, height: textHeight)
            
            // Add this chunk as a page
            resultPages.append(pageText)
            
            // Remove the used portion from our working text
            if pageText.count < workingText.count {
                let index = workingText.index(workingText.startIndex, offsetBy: pageText.count)
                workingText = String(workingText[index...])
            } else {
                workingText = ""
            }
        }
        
        // Update state 
        if self.pages != resultPages {
            self.pages = resultPages
            self.totalPages = resultPages.count
            
            // Keep the current page valid
            if currentPage >= totalPages {
                currentPage = max(0, totalPages - 1)
            }
        }
        
        print("PaginatedTextView: Created \(totalPages) pages for \(sizeCategory) size")
    }
}

// Helper class to measure text
class TextMeasurer {
    let sizeCategory: ContentSizeCategory
    
    init(sizeCategory: ContentSizeCategory) {
        self.sizeCategory = sizeCategory
    }
    
    // Monospace font for consistent measurement
    private var font: UIFont {
        let style = UIFont.TextStyle.body
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
            .withDesign(.monospaced) ?? UIFontDescriptor()
        
        return UIFont(descriptor: descriptor, size: 0) // 0 means use the size from the descriptor
    }
    
    // Find how much text fits within a given height constraint
    func fitTextToHeight(text: String, width: CGFloat, height: CGFloat) -> String {
        // If text is empty, return empty string
        if text.isEmpty { return "" }
        
        // Start with a paragraph that breaks naturally at word boundaries
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineSpacing = 4
        
        // Create the attributed string
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        
        // Create a text container and layout manager
        let textContainer = NSTextContainer(size: CGSize(width: width, height: height))
        textContainer.lineFragmentPadding = 0
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        
        let textStorage = NSTextStorage(attributedString: attributedText)
        textStorage.addLayoutManager(layoutManager)
        
        // Determine how much text fits
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        
        // Safety check - ensure we're not cutting in the middle of a word
        let fittingText = text.prefix(characterRange.length)
        
        // If we're not at the end, try to break at a natural point
        if characterRange.length < text.count {
            let searchRange = max(0, characterRange.length - 30)..<characterRange.length
            let nsText = text as NSString
            
            // Try to find paragraph break
            let paraRange = nsText.range(of: "\n\n", options: .backwards, range: NSRange(searchRange))
            if paraRange.location != NSNotFound {
                return String(text.prefix(paraRange.location + 2))
            }
            
            // Try to find line break
            let lineRange = nsText.range(of: "\n", options: .backwards, range: NSRange(searchRange))
            if lineRange.location != NSNotFound {
                return String(text.prefix(lineRange.location + 1))
            }
            
            // Try to find sentence end
            for pattern in [".", "!", "?"] {
                let sentenceRange = nsText.range(of: pattern + " ", options: .backwards, range: NSRange(searchRange))
                if sentenceRange.location != NSNotFound {
                    return String(text.prefix(sentenceRange.location + 2))
                }
            }
            
            // Finally, find the last space
            let spaceRange = nsText.range(of: " ", options: .backwards, range: NSRange(searchRange))
            if spaceRange.location != NSNotFound {
                return String(text.prefix(spaceRange.location + 1))
            }
        }
        
        return String(fittingText)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var currentPage = 0
        @State private var selectedSize: ContentSizeCategory = .medium

        var body: some View {
            VStack {
                Picker("Text Size", selection: $selectedSize) {
                    Text("XS").tag(ContentSizeCategory.extraSmall)
                    Text("S").tag(ContentSizeCategory.small)
                    Text("M").tag(ContentSizeCategory.medium)
                    Text("L").tag(ContentSizeCategory.large)
                    Text("XL").tag(ContentSizeCategory.extraLarge)
                    Text("XXL").tag(ContentSizeCategory.accessibilityMedium)
                    Text("XXXL").tag(ContentSizeCategory.accessibilityLarge)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                Text("Page size adapts to text size")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                PaginatedTextView(
                    text: """
                    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec a diam lectus. Sed sit amet ipsum mauris. Maecenas congue ligula ac quam viverra nec consectetur ante hendrerit. Donec et mollis dolor. Praesent et diam eget libero egestas mattis sit amet vitae augue. Nam tincidunt congue enim, ut porta lorem lacinia consectetur. Donec ut libero sed arcu vehicula ultricies a non tortor. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean ut gravida lorem. Ut turpis felis, pulvinar a semper sed, adipiscing id dolor. Pellentesque auctor nisi id magna consequat sagittis. Curabitur dapibus enim sit amet elit pharetra tincidunt feugiat nisl imperdiet. Ut convallis libero in urna ultrices accumsan. Donec sed odio eros. Donec viverra mi quis quam pulvinar at malesuada arcu rhoncus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. In rutrum accumsan ultricies. Mauris vitae nisi at sem facilisis semper ac in est.

                    Vivamus fermentum semper porta. Nunc diam velit, adipiscing ut tristique vitae, sagittis vel odio. Maecenas convallis ullamcorper ultricies. Curabitur ornare, ligula semper consectetur sagittis, nisi diam iaculis velit, id fringilla sem nunc vel mi. Nam dictum, odio nec pretium volutpat, arcu ante placerat erat, non tristique elit urna et turpis. Quisque mi metus, ornare sit amet fermentum et, tincidunt et orci. Fusce eget orci a orci congue vestibulum. Ut dolor diam, elementum et vestibulum eu, porttitor vel elit. Curabitur venenatis pulvinar tellus gravida ornare.
                    """,
                    availableSize: CGSize(width: 300, height: 400),
                    currentPage: $currentPage
                )
                .frame(width: 300, height: 400)
                .border(Color.gray.opacity(0.5), width: 1)
                .environment(\.sizeCategory, selectedSize)
            }
        }
    }

    return PreviewWrapper()
}