import Foundation

enum CompletionLevel: String, Codable {
    case none = "none"
    case skip = "SKIP"
    case mini = "MINI"
    case more = "MORE"
    case max = "MAX"
    
    var displayName: String {
        switch self {
        case .none:
            return "미완료"
        case .skip:
            return "SKIP"
        case .mini:
            return "MINI"
        case .more:
            return "MORE"
        case .max:
            return "MAX"
        }
    }
    
    var color: String {
        switch self {
        case .none:
            return "gray"
        case .skip:
            return "gray"
        case .mini:
            return "mint"
        case .more:
            return "blue"
        case .max:
            return "purple"
        }
    }
}

