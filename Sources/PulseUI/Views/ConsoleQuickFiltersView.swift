// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import Pulse

struct ConsoleQuickFiltersView: View {
    @Binding var onlyErrors: Bool
    @Binding var isShowingSettings: Bool

    var body: some View {
        HStack {
            Picker("Systems", selection: $onlyErrors) {
                Text("All Messages").tag(false)
                Text("Only Errors").tag(true)
            }.pickerStyle(SegmentedPickerStyle())
            Spacer(minLength: 40)
            Button(action: { self.isShowingSettings = true }) {
                Image(systemName: "gear")
                    .frame(width: 44, height: 44)
            }
        }.buttonStyle(BorderlessButtonStyle())
    }

}

struct ConsoleQuickFiltersView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ConsoleQuickFiltersView(onlyErrors: .constant(false), isShowingSettings: .constant(false))
                .previewLayout(.fixed(width: 320, height: 80))
        }
    }
}