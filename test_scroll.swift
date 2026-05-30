import SwiftUI

struct TestScroll: View {
    var body: some View {
        ScrollView {
            Text("Hello")
        }
        .scrollTargetBehavior(.viewAligned)
    }
}
