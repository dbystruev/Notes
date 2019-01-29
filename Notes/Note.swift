//
//  Note.swift
//  Notes
//
//  Created by Denis Bystruev on 28/01/2019.
//  Copyright © 2019 Denis Bystruev. All rights reserved.
//

import Foundation

enum NoteError: Error {
    case ok
    case error
}

@objcMembers class Note: NSObject, Codable {
    var title: String
    var text: String
    var timestamp: Date
    
    override var description: String {
        return "Title: \(title), Text: \(text), Timestamp: \(timestamp)"
    }
    
    var encoded: Data? {
        let encoder = PropertyListEncoder()
        
        return try? encoder.encode(self)
    }
    
    var isEmpty: Bool {
        return title.isEmpty && text.isEmpty
    }
    
    var properties: [String] {
        return Mirror(reflecting: self).children.compactMap { $0.label }
    }
    
    init(title: String, text: String) {
        self.title = title
        self.text = text
        timestamp = Date()
    }
    
    convenience init(from data: Data) throws {
        let decoder = PropertyListDecoder()
        
        let note = try decoder.decode(Note.self, from: data)
        
        self.init(title: note.title, text: note.text)
        timestamp = note.timestamp
    }
    
    convenience init?(from url: URL?) {
        guard let url = url else { return nil }
        
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        try? self.init(from: data)
    }
    
    convenience init?(_ noteMO: NoteMO?) {
        guard let noteMO = noteMO else { return nil }
        guard let title = noteMO.title else { return nil }
        guard let text = noteMO.text else { return nil }
        guard let timestamp = noteMO.timestamp else { return nil }
        
        self.init(title: title, text: text)
        self.timestamp = timestamp
    }
    
    func write(to url: URL?) throws {
        guard let url = url else { throw NoteError.error }
        
        try encoded?.write(to: url, options: .noFileProtection)
    }
}

