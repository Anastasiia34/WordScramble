//
//  TableViewController.swift
//  Project5
//
//  Created by Анастасия Стрекалова on 26.02.2020.
//  Copyright © 2020 Анастасия Стрекалова. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    
    var allWords = [String]()
    var usedWords = [String]()
    var savedWords = [String: [String]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(promptForAnswer))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(startGame))

        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL) {
                allWords = startWords.components(separatedBy: "\n")
            }
        }
        
        if allWords.isEmpty {
            allWords = ["silkworm"]
        }
        
        if let savedWords = UserDefaults.standard.object(forKey: "saved words") as? Data {
            do {
                self.savedWords = try JSONDecoder().decode([String: [String]].self, from: savedWords)
                title = self.savedWords.keys.first
                usedWords = self.savedWords[title!]!
            } catch {
                print("Failed to decode")
            }
            tableView.reloadData()
        } else {
            startGame()
        }
    }
    
    @objc private func startGame() {
        title = allWords.randomElement()
        savedWords = [title!: [String]()]
        usedWords.removeAll(keepingCapacity: true)
        tableView.reloadData()
        save()
    }
    
    @objc private func promptForAnswer() {
        let ac = UIAlertController(title: "Enter answer", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak ac] _ in
            guard let answer = ac?.textFields?[0].text else { return }
            self?.submit(answer)
        }
        
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    private func submit(_ answer: String) {
        let lowerAnswer = answer.lowercased()
        
        if notTheSame(word: lowerAnswer) {
            if isPossible(word: lowerAnswer) {
                if isOriginal(word: lowerAnswer) {
                    if isReal(word: lowerAnswer) {
                        usedWords.insert(lowerAnswer, at: 0)
                
                        let indexPath = IndexPath(row: 0, section: 0)
                        tableView.insertRows(at: [indexPath], with: .automatic)
                        
                        save()
                        
                        return
                    } else {
                        showErrorMessage(errorTitle: "Word not recognized", errorMessage: "U can't just make them up, u know!")
                    }
                } else {
                    showErrorMessage(errorTitle: "Word already used", errorMessage: "Try something new!")
                }
            } else {
                guard let title = title else { return }
                showErrorMessage(errorTitle: "Word isn't possible", errorMessage: "U can't spell that word from \(title.lowercased()).")
            }
        } else {
            showErrorMessage(errorTitle: "It's the same word", errorMessage: "They should be different!")
        }
    }
    
    private func showErrorMessage(errorTitle: String, errorMessage: String) {
        let ac = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    private func isPossible(word: String) -> Bool {
        guard var tempWord = title?.lowercased() else { return false }
        
        for letter in word {
            if let position = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: position)
            } else {
                return false
            }
        }
        
        return true
    }
    
    private func isOriginal(word: String) -> Bool {
        return !usedWords.contains(word)
    }
    
    private func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        return misspelledRange.location == NSNotFound && word.utf16.count >= 3
    }
    
    private func notTheSame(word: String) -> Bool {
        if word != title?.lowercased() {
            return true
        } else {
            return false
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return usedWords.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
        cell.textLabel?.text = usedWords[indexPath.row]

        return cell
    }

    private func save() {
        savedWords[title!]! = usedWords
        
        if let savedData = try? JSONEncoder().encode(savedWords) {
            UserDefaults.standard.set(savedData, forKey: "saved words")
        } else {
            print("Failed to save.")
        }
    }
}
