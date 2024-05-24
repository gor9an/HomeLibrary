//
//  TableViewController.swift
//  HomeLibrary
//
//  Created by Andrey Gordienko on 24.05.2024.
//

import PostgresClientKit
import UIKit

final class TableViewController: UIViewController {
    
    private let keys = PG_Keys()
    private let pickerView = UIPickerView()
    private let tableView = UITableView()
    private var tables: [String] = []
    private var selectedTableName: String?
    private var tableData: [[String]] = []
    private var columnNames: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        fetchTables()
    }
    
    private func configureViews() {
        view.backgroundColor = .systemBackground
        
        pickerView.delegate = self
        pickerView.dataSource = self
        view.addSubview(pickerView)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorInset = .init(top: 0, left: 5, bottom: 0, right: 5)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pickerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pickerView.heightAnchor.constraint(equalToConstant: 150),
            
            tableView.topAnchor.constraint(equalTo: pickerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 5),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -5),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
// MARK: - UIPickerViewDelegate & UIPickerViewDataSource
extension TableViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return tables.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return tables[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedTableName = tables[row]
        fetchTableData()
    }
}

// MARK: - UITableViewDataSource
extension TableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        
        if indexPath.row == 0 {
            cell.textLabel?.text = columnNames.joined(separator: " | ")
            cell.backgroundColor = .systemGray5
        } else {
            let rowData = tableData[indexPath.row - 1]
            cell.textLabel?.text = rowData.joined(separator: " | ")
            cell.backgroundColor = .systemBackground
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension TableViewController: UITableViewDelegate {
    private func fetchTables() {
        guard let connection = makeConnection() else { return }
        
        do {
            let query = "SELECT table_name FROM information_schema.tables WHERE table_schema = 'main'"
            let statement = try connection.prepareStatement(text: query)
            defer { statement.close() }
            
            let cursor = try statement.execute()
            defer { cursor.close() }
            for row in cursor {
                let columns = try row.get().columns
                let tableName = try columns[0].string()
                tables.append(tableName)
            }
            
            pickerView.reloadAllComponents()
            
            selectedTableName = tables[0]
            fetchTableData()
            
        } catch {
            print("Error fetching tables: \(error)")
        }
    }
    
    private func makeConnection() -> Connection? {
        do {
            var configuration = ConnectionConfiguration()
            configuration.host = keys.host
            configuration.database = keys.databaseName
            configuration.user = keys.username
            configuration.credential = .scramSHA256(password: keys.password)
            configuration.ssl = false // Отключаем SSL
            
            let connection = try Connection(configuration: configuration)
            return connection
        } catch {
            print("Error creating connection: \(error)")
            return nil
        }
    }
    
    // Получение содержимого выбранной таблицы
    private func fetchTableData() {
        guard let tableName = selectedTableName, let connection = makeConnection() else { return }
        
        do {
            // Запрос для получения названий столбцов
            let columnQuery = "SELECT column_name FROM information_schema.columns WHERE table_name = '\(tableName)' AND table_schema = 'main'"
            let columnStatement = try connection.prepareStatement(text: columnQuery)
            defer { columnStatement.close() }
            
            let columnCursor = try columnStatement.execute()
            defer { columnCursor.close() }
            
            // Извлечение названий столбцов из результата запроса
            var columnNames: [String] = []
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
            
            self.columnNames = columnNames
            
            tableView.reloadData()
        } catch {
            print("Error fetching table data: \(error)")
        }
    }
}
