import SwiftUI

enum AppFonts {
    static let title      = Font.system(.title2,   design: .rounded).weight(.bold)
    static let heading    = Font.system(.title3,   design: .rounded).weight(.semibold)
    static let body       = Font.system(.body,     design: .rounded)
    static let bodyBold   = Font.system(.body,     design: .rounded).weight(.semibold)
    static let button     = Font.system(.callout,  design: .rounded).weight(.semibold)
    static let caption    = Font.system(.subheadline, design: .rounded)
    static let meta       = Font.system(.caption,  design: .rounded)
}
