//
//  ViewController.swift
//  Notes
//
//  Created by Denis Bystruev on 28/01/2019.
//  Copyright © 2019 Denis Bystruev. All rights reserved.
//

import CoreData
import UIKit

class ViewController: UIViewController {
    
    let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    
    let defaultNote = Note(title: "", text: "")
    
    var note: Note!
    var notesMO: [NoteMO]?
    var noteURL: URL?
    
    var fetchResultsController: NSFetchedResultsController<NoteMO>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupController()
        
//        loadNoteFromPlist(named: "note")
        loadNotesMO()
        
        setupUI()
    }
    
    func loadNoteFromPlist(named name: String) {
        noteURL = directory?.appendingPathComponent(name).appendingPathExtension("plist")
        note = Note(from: noteURL) ?? defaultNote
    }
    
    func loadNotesMO() {
        guard let delegate = AppDelegate.delegate else { return }
        
        let request: NSFetchRequest<NoteMO> = NoteMO.fetchRequest()
        
        let context = delegate.persistentContainer.viewContext
        
        do {
            notesMO = try context.fetch(request)
        } catch {
            print(#function, "ERROR:", error.localizedDescription)
        }
        
        note = Note(notesMO?.first) ?? defaultNote
        
        printNotesMO(function: #function)
    }
    
    func printNotesMO(function: String) {
        if let notes = notesMO {
            notes.forEach {
                let note = Note($0)
                print(function, note ?? "nil")
            }
        }
    }
    
    func saveNotesMO() {
        guard let delegate = AppDelegate.delegate else { return }
        
        let noteMO = NoteMO(context: delegate.persistentContainer.viewContext)
        
        noteMO.title = note.title
        noteMO.text = note.text
        noteMO.timestamp = note.timestamp
        
        delegate.saveContext()
    }
    
    func deleteFirst() {
        delete(notesMO?.first)
    }
    
    func delete(_ object: NSManagedObject?) {
        guard let object = object else { return }
        
        guard let delegate = AppDelegate.delegate else { return }
        
        let context = delegate.persistentContainer.viewContext
        
        context.delete(object)
        
        delegate.saveContext()
    }
    
    func setupUI() {
        var frame = view.frame
        frame.origin.x += 16
        frame.origin.y += 16
        frame.size.height /= 2
        frame.size.width -= 2 * frame.origin.x
        
        let verticalStackView = UIStackView(frame: frame)
        verticalStackView.axis = .vertical
        verticalStackView.distribution = .fillEqually
        view.addSubview(verticalStackView)
        
        for property in note.properties {
            // Horizontal Stack View
            let horizontalStackView = UIStackView()
            verticalStackView.addArrangedSubview(horizontalStackView)
            
            horizontalStackView.spacing = 8
            
            // Label
            let label = UILabel()
            horizontalStackView.addArrangedSubview(label)
            
            let constraint = NSLayoutConstraint(
                item: label,
                attribute: .width,
                relatedBy: .equal,
                toItem: view,
                attribute: .width,
                multiplier: 1 / 3,
                constant: 0
            )
            view.addConstraint(constraint)
            
            label.font = UIFont.systemFont(ofSize: 20)
            label.textAlignment = .right
            label.text = "\(property.capitalized):"
            
            // Text Field
            let textField = UITextField()
            horizontalStackView.addArrangedSubview(textField)
            
            textField.font = UIFont.systemFont(ofSize: 20)
        }
        
        let buttonStackView = UIStackView()
        verticalStackView.addArrangedSubview(buttonStackView)
        
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 16
        
        // Add button
        let addButton = getButton(
            action: #selector(addButtonPressed(button:)),
            color: .green,
            title: "Add"
        )
        buttonStackView.addArrangedSubview(addButton)
        
        // Delete button
        let deleteButton = getButton(
            action: #selector(deleteButtonPressed(button:)),
            color: .red,
            title: "Delete"
        )
        buttonStackView.addArrangedSubview(deleteButton)
        
        syncTextFields(with: &note, fromTextFields: false)
    }
    
    func animate(button: UIButton) {
        UIView.animate(withDuration: 0.3) {
            button.transform = CGAffineTransform(scaleX: 3, y: 3)
            button.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    
    func getButton(action: Selector, color: UIColor, title: String) -> UIButton {
        let button = UIButton()
        
        button.addTarget(self, action: action, for: .touchUpInside)
        button.backgroundColor = color
        button.layer.cornerRadius = 25
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 40)
        
        return button
    }
    
    func syncTextFields(with originalNote: inout Note?, fromTextFields: Bool) {
        let note = originalNote ?? defaultNote
        
        let stackViews = view.subviews.first?.subviews
        
        for (index, property) in note.properties.enumerated() {
            guard let stackView = stackViews?[index] as? UIStackView else { return }
            
            guard let textField = stackView.arrangedSubviews.last as? UITextField else { return }
            
            if fromTextFields {
                let value = textField.text ?? ""
                
                if note.value(forKey: property) is Date {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [
                        .withFullDate,
                        .withFullTime,
                        .withTimeZone,
                        .withSpaceBetweenDateAndTime,
                        .withDashSeparatorInDate,
                        .withColonSeparatorInTime
                    ]
                    
                    let date = formatter.date(from: value) ?? Date()
                    
                    note.setValue(date, forKey: property)
                } else {
                    note.setValue(value, forKey: property)
                }
            } else {
                let value = note.value(forKey: property)
                
                if let date = value as? Date {
                    textField.text = "\(date)"
                } else {
                    textField.text = value as? String
                }
            }
        }
        
        if fromTextFields {
            originalNote = note
        }
    }

    @objc func addButtonPressed(button: UIButton) {
        syncTextFields(with: &note, fromTextFields: true)
        
        if !note.isEmpty {
            animate(button: button)
            
            saveNotesMO()
        } else {
            print(#function, "Fields should not be empty")
        }
        
//        try? note.write(to: noteURL)
    }
    
    @objc func deleteButtonPressed(button: UIButton) {
        guard let notesMO = notesMO else { return }
        
        guard !notesMO.isEmpty else {
            print(#function, "NotesMO is empty")
            return
        }

        animate(button: button)
        
        deleteFirst()
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {
    func setupController() {
        let fetchRequest: NSFetchRequest<NoteMO> = NoteMO.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        guard let delegate = AppDelegate.delegate else { return }
        
        let context = delegate.persistentContainer.viewContext
        
        fetchResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        guard let fetchResultsController = self.fetchResultsController else { return }
        
        fetchResultsController.delegate = self
        
        do {
            try fetchResultsController.performFetch()
            
            if let fetchedObjects = fetchResultsController.fetchedObjects {
                notesMO = fetchedObjects
            }
        } catch {
            print(#function, "ERROR:", error)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        notesMO = controller.fetchedObjects as? [NoteMO]
        
        note = Note(notesMO?.first) ?? defaultNote
        
        syncTextFields(with: &note, fromTextFields: false)
        
        print(#function, "controller.fetchedObjects?.count:", notesMO?.count ?? "nil")
        
        printNotesMO(function: #function)
    }
}
