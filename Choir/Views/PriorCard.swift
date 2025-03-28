import SwiftUI

struct PriorCard: View {
    let prior: Prior
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Prior ID: \(prior.id)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Similarity: \(Int(prior.similarity * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(prior.content)
                .font(.body)
                .lineLimit(3)
            
            HStack {
                if let threadID = prior.threadID {
                    Text("Thread: \(threadID)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let step = prior.step {
                    Text("Phase: \(step)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let createdAt = prior.createdAt {
                    Text("Created: \(formattedDate(createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground)) // Use semantic color
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

//#Preview {
//    PriorCard(
//        prior: Prior(
//            id: "prior-123",
//            content: "This is a sample prior content for testing the card view. It might contain multiple lines of text to show how line wrapping works.",
//            similarity: 0.86,
//            threadID: "thread-abc",
//            step: "experience",
//            createdAt: "2025-03-20T14:30:45.123Z"
//        )
//    )
//    .padding()
//    .frame(width: 350)
//}
