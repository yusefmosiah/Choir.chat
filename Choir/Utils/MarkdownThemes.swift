import SwiftUI
import MarkdownUI

extension Theme {
    static var normalizedHeadings: Theme {
        Theme()
            // Headings with consistent styling
            .heading1 { cfg in cfg.label.font(.body).bold().lineLimit(nil) }
            .heading2 { cfg in cfg.label.font(.body).bold().lineLimit(nil) }
            .heading3 { cfg in cfg.label.font(.body).bold().lineLimit(nil) }
            .heading4 { cfg in cfg.label.font(.body).bold().lineLimit(nil) }
            .heading5 { cfg in cfg.label.font(.body).bold().lineLimit(nil) }
            .heading6 { cfg in cfg.label.font(.body).bold().lineLimit(nil) }

            // Text elements with improved typography
            .paragraph { cfg in
                cfg.label
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .text {
                ForegroundColor(.primary)
                BackgroundColor(.clear)
                // Use a standard font size instead of .body
                FontSize(16)
            }

            // Link styling - make links blue and bold
            .link {
                ForegroundColor(.blue)
                FontWeight(.bold)
            }

            // List items with proper spacing
            .listItem { cfg in
                cfg.label
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Code blocks with proper formatting
            .codeBlock { cfg in
                cfg.label
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.system(.body, design: .monospaced))
            }

            // Blockquotes with distinct styling
            .blockquote { cfg in
                cfg.label
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 8)
            }

            // Tables with proper spacing
            .table { cfg in
                cfg.label
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
    }
}
