import SwiftUI

enum ScholarType {
    static let masthead = Font.system(.largeTitle, design: .rounded).weight(.semibold)
    static let chapter = Font.system(.caption, design: .rounded).weight(.semibold)
    static let title = Font.system(.title2, design: .rounded).weight(.semibold)
    static let cardTitle = Font.system(.headline, design: .rounded).weight(.semibold)
    static let body = Font.system(.body, design: .rounded)
    static let caption = Font.system(.caption, design: .rounded)
    static let node = Font.system(.footnote, design: .rounded).weight(.semibold)

    static let mastheadTracking: CGFloat = 2.6
    static let chapterTracking: CGFloat = 3.2
    static let titleTracking: CGFloat = 1.1
}
