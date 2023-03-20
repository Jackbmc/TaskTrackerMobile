import SwiftUI

struct Task: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool
}
