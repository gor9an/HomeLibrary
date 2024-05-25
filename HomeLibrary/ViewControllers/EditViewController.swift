//
//  EditViewController.swift
//  HomeLibrary
//
//  Created by Andrey Gordienko on 24.05.2024.
//

import PostgresClientKit
import UIKit

final class EditViewController: UIViewController {
    
    private let tableView = UITableView()
    private let selectTableButton = UIButton(type: .system)
    private let dropdownMenu = UITableView()
    private let addButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    private let updateButton = UIButton(type: .system)
    private let columnNamesLabel = UILabel()
    
    private let keys = PG_Keys()
    
    var tableNames: [String] = ["authors", "restrictions", "publishing_houses", "genres", "rooms", "shelf", "books", "authors_books", "readers", "read_request", "read_request_lines"]
    var selectedTableName: String?
    var columnNames: [String] = []
    var tableData: [[String]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        dropdownMenu.dataSource = self
        dropdownMenu.delegate = self
        dropdownMenu.isHidden = true
        
        selectedTableName = tableNames.first
        fetchTableData()
    }
    
    private func configureViews() {
        view.backgroundColor = .systemBackground
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorInset = .init(top: 0, left: 5, bottom: 0, right: 5)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        
        selectTableButton.layer.cornerRadius = 22
        selectTableButton.backgroundColor = .label
        selectTableButton.tintColor = .systemBackground
        selectTableButton.addTarget(self, action: #selector(selectTableButtonTapped), for: .touchUpInside)
        view.addSubview(selectTableButton)
        
        columnNamesLabel.numberOfLines = 0
        columnNamesLabel.textAlignment = .center
        view.addSubview(columnNamesLabel)
        
        dropdownMenu.layer.cornerRadius = 22
        dropdownMenu.backgroundColor = .systemGray6
        dropdownMenu.register(UITableViewCell.self, forCellReuseIdentifier: "tableCell")
        view.addSubview(dropdownMenu)
        
        addButton.layer.cornerRadius = 22
        addButton.backgroundColor = .label
        addButton.tintColor = .systemBackground
        addButton.setTitle("Добавить", for: .normal)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        
        deleteButton.layer.cornerRadius = 22
        deleteButton.backgroundColor = .label
        deleteButton.tintColor = .systemBackground
        deleteButton.setTitle("Удалить", for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        updateButton.layer.cornerRadius = 22
        updateButton.backgroundColor = .label
        updateButton.tintColor = .systemBackground
        updateButton.setTitle("Обновить", for: .normal)
        updateButton.addTarget(self, action: #selector(updateButtonTapped), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [addButton, deleteButton, updateButton])
        stackView.axis = .horizontal
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        view.addSubview(stackView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        selectTableButton.translatesAutoresizingMaskIntoConstraints = false
        dropdownMenu.translatesAutoresizingMaskIntoConstraints = false
        columnNamesLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            selectTableButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            selectTableButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            selectTableButton.heightAnchor.constraint(equalToConstant: 44),
            selectTableButton.widthAnchor.constraint(equalToConstant: 200),
            
            dropdownMenu.topAnchor.constraint(equalTo: selectTableButton.bottomAnchor, constant: 10),
            dropdownMenu.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            dropdownMenu.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            dropdownMenu.heightAnchor.constraint(equalToConstant: 200),
            
            columnNamesLabel.topAnchor.constraint(equalTo: selectTableButton.bottomAnchor, constant: 10),
            columnNamesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            columnNamesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            columnNamesLabel.heightAnchor.constraint(equalToConstant: 44),
            
            tableView.topAnchor.constraint(equalTo: columnNamesLabel.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            tableView.bottomAnchor.constraint(equalTo: stackView.topAnchor, constant: -10),
            
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15),
            stackView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Button Actions
    
    @objc func selectTableButtonTapped() {
        dropdownMenu.isHidden.toggle()
    }
    
    @objc func addButtonTapped() {
        showInputAlert(for: "Добавить")
    }
    
    @objc func deleteButtonTapped() {
        if let indexPath = tableView.indexPathForSelectedRow {
            let data = tableData[indexPath.row]
            deleteData(with: data)
        }
    }
    
    @objc func updateButtonTapped() {
        if let indexPath = tableView.indexPathForSelectedRow {
            let data = tableData[indexPath.row]
            showInputAlert(for: "Обновить", with: data)
        }
    }
    
    // MARK: - Fetch Table Data
    
    func fetchTableData() {
        guard let tableName = selectedTableName, let connection = makeConnection() else { return }
        
        do {
            let columnQuery = "SELECT column_name FROM information_schema.columns WHERE table_name = '\(tableName)' AND table_schema = 'main'"
            let columnStatement = try connection.prepareStatement(text: columnQuery)
            defer { columnStatement.close() }
            
            let columnCursor = try columnStatement.execute()
            defer { columnCursor.close() }
            
            columnNames = []
            for row in columnCursor {
                let columnName = try row.get().columns[0].string()
                columnNames.append(columnName)
            }
            
            let query = "SELECT * FROM main.\(tableName)"
            let statement = try connection.prepareStatement(text: query)
            defer { statement.close() }
            
            let cursor = try statement.execute()
            defer { cursor.close() }
            
            tableData = []
            for row in cursor {
                let rowData = try row.get().columns.map { try $0.string() }
                tableData.append(rowData)
            }
            
            DispatchQueue.main.async {
                self.columnNamesLabel.text = self.columnNames.joined(separator: " | ")
                self.tableView.reloadData()
                self.selectTableButton.setTitle(tableName, for: .normal)
            }
        } catch {
            print("Error fetching table data: \(error)")
        }
    }
    
    
    // MARK: - Database Operations
    
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
    
    private func showInputAlert(for action: String, with data: [String]? = nil) {
        let alert = UIAlertController(title: action, message: "Заполните поля", preferredStyle: .alert)
        
        for (index, column) in columnNames.enumerated() {
            alert.addTextField { textField in
                textField.placeholder = column
                if let data = data {
                    textField.text = data[index]
                }
            }
        }
        
        let submitAction = UIAlertAction(title: "Подтвердить", style: .default) { [weak self, weak alert] _ in
            guard let self = self, let textFields = alert?.textFields else { return }
            let inputs = textFields.compactMap { $0.text }
            self.handleDatabaseAction(action, with: inputs)
        }
        
        alert.addAction(submitAction)
        present(alert, animated: true, completion: nil)
    }
    
    private func handleDatabaseAction(_ action: String, with inputs: [String]) {
        switch action {
        case "Добавить":
            addData(with: inputs)
        case "Удалить":
            deleteData(with: inputs)
        case "Обновить":
            updateData(with: inputs)
        default:
            break
        }
    }
    
    private func addData(with inputs: [String]) {
        guard let tableName = selectedTableName, let connection = makeConnection() else { return }
        
        let columns = columnNames.joined(separator: ", ")
        let values = inputs.map { "'\($0)'" }.joined(separator: ", ")
        let query = "INSERT INTO main.\(tableName) (\(columns)) VALUES (\(values))"
        
        do {
            let statement = try connection.prepareStatement(text: query)
            defer { statement.close() }
            _ = try statement.execute()
            fetchTableData()
        } catch {
            print("Error adding data: \(error)")
        }
    }
    
    private func deleteData(with inputs: [String]) {
        guard let tableName = selectedTableName, let connection = makeConnection() else { return }
        
        var conditions: [String] = []
        for (index, column) in columnNames.enumerated() {
            let condition = "\(column) = '\(inputs[index])'"
            conditions.append(condition)
        }
        let conditionString = conditions.joined(separator: " AND ")
        let query = "DELETE FROM main.\(tableName) WHERE \(conditionString)"
        
        do {
            let statement = try connection.prepareStatement(text: query)
            defer { statement.close() }
            _ = try statement.execute()
            fetchTableData()
        } catch {
            print("Error deleting data: \(error)")
        }
    }
    
    private func updateData(with inputs: [String]) {
        guard let tableName = selectedTableName, let connection = makeConnection() else { return }
        
        let idValue = inputs[0]
        
        var setClauses: [String] = []
        for (index, column) in columnNames.enumerated() {
            if index != 0 {
                let setClause = "\(column) = '\(inputs[index])'"
                setClauses.append(setClause)
            }
        }
        
        let setString = setClauses.joined(separator: ", ")
        let query = "UPDATE main.\(tableName) SET \(setString) WHERE \(columnNames[0]) = '\(idValue)'"
        
        do {
            let statement = try connection.prepareStatement(text: query)
            defer { statement.close() }
            _ = try statement.execute()
            fetchTableData()
        } catch {
            print("Error updating data: \(error)")
        }
    }
}

extension EditViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView {
            return tableData.count
        } else {
            return tableNames.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.tableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            let rowData = tableData[indexPath.row]
            cell.textLabel?.text = rowData.joined(separator: " | ")
            cell.backgroundColor = .systemBackground
            cell.textLabel?.numberOfLines = 0
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath)
            cell.textLabel?.text = tableNames[indexPath.row]
            cell.backgroundColor = .systemGray6
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == dropdownMenu {
            selectedTableName = tableNames[indexPath.row]
            fetchTableData()
            dropdownMenu.isHidden = true
            selectTableButton.setTitle(selectedTableName, for: .normal)
        }
    }
}
