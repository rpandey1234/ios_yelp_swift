//
//  FiltersViewController.swift
//  Yelp
//
//  Created by Rahul Pandey on 10/20/16.
//  Copyright © 2016 Timothy Lee. All rights reserved.
//

import UIKit

@objc protocol FiltersViewControllerDelegate {
    @objc func filtersViewController(filtersViewController: FiltersViewController, didUpdateFilters filters: [String:AnyObject])
}

class FiltersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SwitchCellDelegate {

    let METERS_IN_MILE: Int = 1609
    let DEAL_SECTION = 0
    let DISTANCE_SECTION = 1
    let SORT_SECTION = 2
    let CATEGORY_SECTION = 3

    @IBOutlet weak var tableView: UITableView!
    var categories: [[String: String]]!
    weak var delegate: FiltersViewControllerDelegate?
    var switchStates = [Int:[Int:Bool]]()
    var filters = [String : AnyObject]()
    var sortCriteriaData: [(String, YelpSortMode)]!
    var distanceData: [(String, Int?)]!
    var isDistanceSectionExpanded = true
    
    @IBAction func onCancelTap(_ sender: AnyObject) {
        dismiss(animated: true) {}
    }
    
    @IBAction func onSearchTap(_ sender: AnyObject) {
        dismiss(animated: true) {}
        var filters = [String: AnyObject]()
        
        // Categories
        var selectedCategories = [String]()
        if let categorySelection = switchStates[CATEGORY_SECTION] {
            for (row, isSelected) in categorySelection {
                if isSelected {
                    selectedCategories.append(categories[row]["code"]!)
                }
            }
        }
        if selectedCategories.count > 0 {
            filters["categories"] = selectedCategories as AnyObject?
        }
        // Offering a deal
        if switchStates[DEAL_SECTION]?[0] != nil {
            filters["offeringDeal"] = switchStates[DEAL_SECTION]?[0] as AnyObject?
        }
        
        // Sort criteria
        var sortCriteria: YelpSortMode?
        for (row, isSelected) in switchStates[SORT_SECTION]! {
            if isSelected {
                sortCriteria = sortCriteriaData[row].1
                break
            }
        }
        if sortCriteria != nil {
            filters["sortCriteria"] = sortCriteria as AnyObject?
        }
        
        // Distance (in meters)
        var distance: Int?
        for (row, isSelected) in switchStates[DISTANCE_SECTION]! {
            if isSelected {
                distance = distanceData[row].1
                break
            }
        }
        if distance != nil {
            filters["distance"] = distance as AnyObject?
        }
        delegate?.filtersViewController(filtersViewController: self, didUpdateFilters: filters)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case DEAL_SECTION:
            return
        case DISTANCE_SECTION:
            if isDistanceSectionExpanded {
                return
            }
        case SORT_SECTION:
            return
        default:
            return
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.dataSource = self
        tableView.delegate = self
        categories = Categories.yelpCategories()
        sortCriteriaData = [
            ("Best Match", YelpSortMode.bestMatched),
            ("Distance", YelpSortMode.distance),
            ("Highly rated", YelpSortMode.highestRated)]
        distanceData = [
            ("Auto", nil),
            ("0.3 miles", Int(Double(self.METERS_IN_MILE) * 0.3)),
            ("1 mile", self.METERS_IN_MILE),
            ("5 miles", self.METERS_IN_MILE * 5),
            ("20 miles", self.METERS_IN_MILE * 20)]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case DEAL_SECTION:
            return 1
        case DISTANCE_SECTION:
            if isDistanceSectionExpanded {
                return distanceData.count
            } else {
                return 1
            }
        case SORT_SECTION:
            return sortCriteriaData.count
        case CATEGORY_SECTION:
            return categories.count
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell") as! HeaderCell
        headerCell.backgroundColor = UIColor.white
        switch section {
        case DEAL_SECTION:
            return nil
        case DISTANCE_SECTION:
            headerCell.headerLabel.text = "Distance"
        case SORT_SECTION:
            headerCell.headerLabel.text = "Sort By"
        default:
            headerCell.headerLabel.text = "Category"
        }
        return headerCell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == DEAL_SECTION {
            return 0
        }
        return 52
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
        cell.preservesSuperviewLayoutMargins = false
        cell.layer.borderColor = UIColor.red.cgColor
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 2
        cell.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 4, right: 8)
        
        cell.delegate = self
        if switchStates[indexPath.section] == nil {
            switchStates[indexPath.section] = [Int:Bool]()
        }
        cell.onSwitch.isOn = switchStates[indexPath.section]?[indexPath.row] ?? false
        var text: String?
        switch indexPath.section {
        case DEAL_SECTION:
            text = "Offering a Deal"
        case DISTANCE_SECTION:
            if isDistanceSectionExpanded {
                text = distanceData[indexPath.row].0
            } else {
                let selectedDistance = "5 miles"
                text = selectedDistance
            }
        case SORT_SECTION:
            text = sortCriteriaData[indexPath.row].0
        default:
            text = categories[indexPath.row]["name"]
        }
        cell.switchLabel.text = text
        return cell
    }
    
    func switchCell(switchCell: SwitchCell, didChange value: Bool) {
        let indexPath = tableView.indexPath(for: switchCell)
        switchStates[(indexPath?.section)!]?[(indexPath?.row)!] = value
        if indexPath?.section == DISTANCE_SECTION || indexPath?.section == SORT_SECTION {
            if value {
                let numberRows = tableView.numberOfRows(inSection: (indexPath?.section)!)
                // Toggle all the others in this section
                for row in 0..<numberRows {
                    if indexPath?.row != row {
                        switchStates[(indexPath?.section)!]?[row] = false
                    }
                }
                tableView.reloadData()
            }
        }
        
    }
}
