// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import CoreData
import Pulse

struct ConsoleMessageViewModel {
    let title: String
    let text: String
    let style: ConsoleMessageStyle

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    init(title: String, text: String, style: ConsoleMessageStyle) {
        self.title = title
        self.text = text
        self.style = style
    }

    init(message: LoggerMessage) {
        let time = ConsoleMessageViewModel.timeFormatter
            .string(from: message.createdAt)
        let category = message.category == "default" ? "" : ":\(message.category)"
        self.title = "\(time) | \(message.system)\(category)"
        self.text = message.text
        self.style = ConsoleMessageStyle.make(level: Logger.Level(rawValue: message.level) ?? .debug)
    }
}
