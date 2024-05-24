//
//  TabBarController.swift
//  HomeLibrary
//
//  Created by Andrey Gordienko on 24.05.2024.
//

import UIKit

final class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appearance = UITabBarAppearance()
        appearance.backgroundColor = .systemBackground
        self.tabBar.tintColor = .label
        self.tabBar.standardAppearance = appearance
        
        let editVC = EditViewController()
        editVC.tabBarItem = UITabBarItem(
            title: "Изменение",
            image: UIImage(systemName: "pencil"),
            selectedImage: nil
        )
        
        let tableVC = TableViewController()
        tableVC.tabBarItem = UITabBarItem(
            title: "Просмотр",
            image: UIImage(systemName: "book.closed"),
            selectedImage: nil
        )
        
        self.viewControllers = [editVC, tableVC]
    }
}
