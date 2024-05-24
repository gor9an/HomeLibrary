//
//  TableViewController.swift
//  HomeLibrary
//
//  Created by Andrey Gordienko on 24.05.2024.
//

import PostgresClientKit
import UIKit

class TableViewController: UIViewController {
    
    private let pickerView = UIPickerView()
    private let tableView = UITableView()
    private let host = "localhost"
    private let port = 5432
    private let username = "postgres"
    private let password = "14265"
    private let databaseName = "home_library"
    private var tables: [String] = [] // Список таблиц
    private var selectedTableName: String?
    private var tableData: [[String]] = [] // Содержимое выбранной таблицы
    private var columnNames: [String] = [] // Названия столбцов выбранной таблицы
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        pickerView.delegate = self
        pickerView.dataSource = self
        view.addSubview(pickerView)
        
        tableView.dataSource = self
        tableView.delegate = self
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
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        fetchTables()
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
        // Добавляем единицу для строки с названиями столбцов
        return tableData.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        
        if indexPath.row == 0 {
            // Если строка - названия столбцов, то показываем их
            cell.textLabel?.text = columnNames.joined(separator: " | ")
        } else {
            // Иначе - показываем данные строки
            let rowData = tableData[indexPath.row - 1]
            cell.textLabel?.text = rowData.joined(separator: " | ")
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension TableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Действия при выборе строки таблицы
    }
    
    // Получение списка таблиц из базы данных
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
        } catch {
            print("Error fetching tables: \(error)")
        }
    }
    
    // Создание соединения с базой данных
    private func makeConnection() -> Connection? {
        do {
            var configuration = ConnectionConfiguration()
            configuration.host = host
            configuration.database = databaseName
            configuration.user = username
            configuration.credential = .scramSHA256(password: password)
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
            
            // Запрос для получения данных из таблицы
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
