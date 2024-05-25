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
        
        let requestsVC = RequestsViewController()
        requestsVC.tabBarItem = UITabBarItem(
            title: "Выборка",
            image: UIImage(systemName: "magnifyingglass"),
            selectedImage: nil)
        
        let editVC = EditViewController()
        editVC.tabBarItem = UITabBarItem(
            title: "Изменение",
            image: UIImage(systemName: "pencil"),
            selectedImage: nil
        )
        
        self.viewControllers = [editVC, requestsVC]
    }
}
