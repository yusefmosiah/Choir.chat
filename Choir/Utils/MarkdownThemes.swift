import SwiftUI
import MarkdownUI

extension Theme {
    static var normalizedHeadings: Theme {
        Theme()
            .heading1 { cfg in cfg.label.font(.body).bold() }
            .heading2 { cfg in cfg.label.font(.body).bold() }
            .heading3 { cfg in cfg.label.font(.body).bold() }
            .heading4 { cfg in cfg.label.font(.body).bold() }
            .heading5 { cfg in cfg.label.font(.body).bold() }
            .heading6 { cfg in cfg.label.font(.body).bold() }
    }
}
