//
//  RequestsViewController.swift
//  HomeLibrary
//
//  Created by Andrey Gordienko on 24.05.2024.
//

import UIKit
import PostgresClientKit

class RequestsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let dropdownButton = UIButton(type: .system)
    let tableView = UITableView()
    let dropdownMenu = UITableView()
    
    private let keys = PG_Keys()
    private var data: [[String]] = []
    private var selectedQueryIndex = 0
    
    private let queries = [
        ("Авторы и их книги", "SELECT authors.fio, books.title FROM main.authors JOIN main.authors_books ON authors.author_code = authors_books.author_code JOIN main.books ON authors_books.book_code = books.book_code"),
        ("Книг по жанру(Код)", "SELECT DISTINCT books.title FROM main.books JOIN main.genres ON books.genre_code ="),
        ("Книги на полке(Код)", "SELECT DISTINCT books.title FROM main.books JOIN main.shelf ON books.shelf_code ="),
            ("Издательства и контактные данные", "SELECT * FROM main.publishing_houses"),
            ("Книги определенного издательства(Код)", "SELECT title FROM main.books WHERE publishing_houses_code ="),
            ("Книги с возрастным ограничением", "SELECT title FROM main.books WHERE restriction_code IS NOT NULL"),
            ("Жанры и количество книг в каждом жанре", "SELECT genres.description, COUNT(*) FROM main.books JOIN main.genres ON books.genre_code = genres.genre_code GROUP BY genres.description"),
            ("Запросы на книги для определенного читателя", "SELECT * FROM main.read_request WHERE reader_id =")
        ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupDropdownButton()
        setupTableView()
        setupDropdownMenu()
        
        fetchData()
    }
    
    // MARK: - Setup UI
    
    private func setupDropdownButton() {
        dropdownButton.setTitle(queries[0].0, for: .normal)
        dropdownButton.backgroundColor = .label
        dropdownButton.tintColor = .systemBackground
        dropdownButton.layer.cornerRadius = 20
        dropdownButton.addTarget(self, action: #selector(toggleDropdownMenu), for: .touchUpInside)
        view.addSubview(dropdownButton)
        
        dropdownButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dropdownButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            dropdownButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            dropdownButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            dropdownButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorInset = .init(top: 0, left: 5, bottom: 0, right: -5)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: dropdownButton.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupDropdownMenu() {
        dropdownMenu.dataSource = self
        dropdownMenu.delegate = self
        dropdownMenu.register(UITableViewCell.self, forCellReuseIdentifier: "dropdownCell")
        dropdownMenu.isHidden = true
        dropdownMenu.layer.cornerRadius = 5
        view.addSubview(dropdownMenu)
        
        dropdownMenu.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dropdownMenu.topAnchor.constraint(equalTo: dropdownButton.bottomAnchor),
            dropdownMenu.leadingAnchor.constraint(equalTo: dropdownButton.leadingAnchor),
            dropdownMenu.trailingAnchor.constraint(equalTo: dropdownButton.trailingAnchor),
            dropdownMenu.heightAnchor.constraint(equalToConstant: CGFloat(queries.count * 40))
        ])
    }
    
    @objc private func toggleDropdownMenu() {
        dropdownMenu.isHidden.toggle()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == dropdownMenu {
            return queries.count
        } else {
            return data.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == dropdownMenu {
            let cell = tableView.dequeueReusableCell(withIdentifier: "dropdownCell", for: indexPath)
            cell.textLabel?.text = queries[indexPath.row].0
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = data[indexPath.row].joined(separator: " | ")
            return cell
        }
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == dropdownMenu {
            selectedQueryIndex = indexPath.row
            dropdownButton.setTitle(queries[indexPath.row].0, for: .normal)
            dropdownMenu.isHidden = true
            if ![0,3,5,6].contains(selectedQueryIndex) {
                showInputAlert(for: queries[indexPath.row].0)
            } else {
                fetchData()
            }
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchData(withParameter parameter: String? = nil) {
        guard let connection = makeConnection() else { return }
        
        do {
            var query = queries[selectedQueryIndex].1
            if let parameter = parameter {
                query += " '\(parameter)'"
            }
            
            print("Executing query: \(query)")
            let statement = try connection.prepareStatement(text: query)
            defer { statement.close() }
            
            let cursor = try statement.execute()
            defer { cursor.close() }
            
            data = []
            for row in cursor {
                let rowData = try row.get().columns.map { try $0.string() }
                data.append(rowData)
            }
            
            tableView.reloadData()
        } catch {
            print("Error fetching data: \(error)")
        }
    }
    
    // MARK: - Database Connection
    
    private func makeConnection() -> Connection? {
        do {
            var configuration = ConnectionConfiguration()
            configuration.host = keys.host
            configuration.port = keys.port
            configuration.database = keys.databaseName
            configuration.user = keys.username
            configuration.credential = .scramSHA256(password: keys.password)
            configuration.ssl = false
            
            let connection = try Connection(configuration: configuration)
            return connection
        } catch {
            print("Error creating connection: \(error)")
            return nil
        }
    }
    
    // MARK: - Alert for Input
    
    private func showInputAlert(for query: String) {
        let alert = UIAlertController(title: "Введите параметры", message: "Введите параметры для запроса: \(query)", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Введите параметры"
        }
        let submitAction = UIAlertAction(title: "Отправить", style: .default) { [weak self, weak alert] _ in
            guard let self = self, let textField = alert?.textFields?.first, let text = textField.text else { return }
            self.fetchData(withParameter: text)
        }
        alert.addAction(submitAction)
        present(alert, animated: true, completion: nil)
    }
}
