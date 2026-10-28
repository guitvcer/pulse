/// How the speed is laid out in the menu bar.
public enum DisplayMode: String, CaseIterable, Sendable {
    /// One combined number for both directions.
    case compact
    /// Upload above download, two small lines.
    case stacked
    /// Upload and download side by side on one line.
    case inline

    public var title: String {
        switch self {
        case .compact: "Compact"
        case .stacked: "Stacked"
        case .inline: "Inline"
        }
    }
}
