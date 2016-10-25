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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.dataSource = self
        tableView.delegate = self
        categories = yelpCategories()
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
    
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        switch section {
//        case DEAL_SECTION:
//            return "Offering a Deal"
//        case DISTANCE_SECTION:
//            return "Distance"
//        case SORT_SECTION:
//            return "Sort By"
//        case CATEGORY_SECTION:
//            return "Category"
//        default:
//            return "not found"
//        }
//    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case DEAL_SECTION:
            return 1
        case DISTANCE_SECTION:
            return distanceData.count
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
        switch section {
        case DEAL_SECTION:
            headerCell.headerLabel.text = "Offering a Deal"
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
        return 52
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
        cell.layer.borderColor = UIColor.gray.cgColor
        cell.layer.borderWidth = 2
        cell.layer.cornerRadius = 2
        cell.layoutMargins.bottom = 2
        cell.layoutMargins.left = 5
        cell.layoutMargins.right = 5
//        cell.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 5, right: 10)
        
        cell.delegate = self
        if switchStates[indexPath.section] == nil {
            switchStates[indexPath.section] = [Int:Bool]()
        }
        print("section \(indexPath.section): \(indexPath.row)")
        cell.onSwitch.isOn = switchStates[indexPath.section]?[indexPath.row] ?? false
        var text: String?
        switch indexPath.section {
        case DEAL_SECTION:
            text = "Offering a Deal"
        case DISTANCE_SECTION:
            text = distanceData[indexPath.row].0
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
                    print("index: \(row)")
                    if indexPath?.row != row {
                        switchStates[(indexPath?.section)!]?[row] = false
                    }
                }
                print(switchStates)
                tableView.reloadData()
            }
        }
        
    }
    
    func yelpCategories() -> [[String:String]] {
        let categories = [["name" : "Afghan", "code": "afghani"],
                          ["name" : "African", "code": "african"],
                          ["name" : "American, New", "code": "newamerican"],
                          ["name" : "American, Traditional", "code": "tradamerican"],
                          ["name" : "Arabian", "code": "arabian"],
                          ["name" : "Argentine", "code": "argentine"],
                          ["name" : "Armenian", "code": "armenian"],
                          ["name" : "Asian Fusion", "code": "asianfusion"],
                          ["name" : "Asturian", "code": "asturian"],
                          ["name" : "Australian", "code": "australian"],
                          ["name" : "Austrian", "code": "austrian"],
                          ["name" : "Baguettes", "code": "baguettes"],
                          ["name" : "Bangladeshi", "code": "bangladeshi"],
                          ["name" : "Barbeque", "code": "bbq"],
                          ["name" : "Basque", "code": "basque"],
                          ["name" : "Bavarian", "code": "bavarian"],
                          ["name" : "Beer Garden", "code": "beergarden"],
                          ["name" : "Beer Hall", "code": "beerhall"],
                          ["name" : "Beisl", "code": "beisl"],
                          ["name" : "Belgian", "code": "belgian"],
                          ["name" : "Bistros", "code": "bistros"],
                          ["name" : "Black Sea", "code": "blacksea"],
                          ["name" : "Brasseries", "code": "brasseries"],
                          ["name" : "Brazilian", "code": "brazilian"],
                          ["name" : "Breakfast & Brunch", "code": "breakfast_brunch"],
                          ["name" : "British", "code": "british"],
                          ["name" : "Buffets", "code": "buffets"],
                          ["name" : "Bulgarian", "code": "bulgarian"],
                          ["name" : "Burgers", "code": "burgers"],
                          ["name" : "Burmese", "code": "burmese"],
                          ["name" : "Cafes", "code": "cafes"],
                          ["name" : "Cafeteria", "code": "cafeteria"],
                          ["name" : "Cajun/Creole", "code": "cajun"],
                          ["name" : "Cambodian", "code": "cambodian"],
                          ["name" : "Canadian", "code": "New)"],
                          ["name" : "Canteen", "code": "canteen"],
                          ["name" : "Caribbean", "code": "caribbean"],
                          ["name" : "Catalan", "code": "catalan"],
                          ["name" : "Chech", "code": "chech"],
                          ["name" : "Cheesesteaks", "code": "cheesesteaks"],
                          ["name" : "Chicken Shop", "code": "chickenshop"],
                          ["name" : "Chicken Wings", "code": "chicken_wings"],
                          ["name" : "Chilean", "code": "chilean"],
                          ["name" : "Chinese", "code": "chinese"],
                          ["name" : "Comfort Food", "code": "comfortfood"],
                          ["name" : "Corsican", "code": "corsican"],
                          ["name" : "Creperies", "code": "creperies"],
                          ["name" : "Cuban", "code": "cuban"],
                          ["name" : "Curry Sausage", "code": "currysausage"],
                          ["name" : "Cypriot", "code": "cypriot"],
                          ["name" : "Czech", "code": "czech"],
                          ["name" : "Czech/Slovakian", "code": "czechslovakian"],
                          ["name" : "Danish", "code": "danish"],
                          ["name" : "Delis", "code": "delis"],
                          ["name" : "Diners", "code": "diners"],
                          ["name" : "Dumplings", "code": "dumplings"],
                          ["name" : "Eastern European", "code": "eastern_european"],
                          ["name" : "Ethiopian", "code": "ethiopian"],
                          ["name" : "Fast Food", "code": "hotdogs"],
                          ["name" : "Filipino", "code": "filipino"],
                          ["name" : "Fish & Chips", "code": "fishnchips"],
                          ["name" : "Fondue", "code": "fondue"],
                          ["name" : "Food Court", "code": "food_court"],
                          ["name" : "Food Stands", "code": "foodstands"],
                          ["name" : "French", "code": "french"],
                          ["name" : "French Southwest", "code": "sud_ouest"],
                          ["name" : "Galician", "code": "galician"],
                          ["name" : "Gastropubs", "code": "gastropubs"],
                          ["name" : "Georgian", "code": "georgian"],
                          ["name" : "German", "code": "german"],
                          ["name" : "Giblets", "code": "giblets"],
                          ["name" : "Gluten-Free", "code": "gluten_free"],
                          ["name" : "Greek", "code": "greek"],
                          ["name" : "Halal", "code": "halal"],
                          ["name" : "Hawaiian", "code": "hawaiian"],
                          ["name" : "Heuriger", "code": "heuriger"],
                          ["name" : "Himalayan/Nepalese", "code": "himalayan"],
                          ["name" : "Hong Kong Style Cafe", "code": "hkcafe"],
                          ["name" : "Hot Dogs", "code": "hotdog"],
                          ["name" : "Hot Pot", "code": "hotpot"],
                          ["name" : "Hungarian", "code": "hungarian"],
                          ["name" : "Iberian", "code": "iberian"],
                          ["name" : "Indian", "code": "indpak"],
                          ["name" : "Indonesian", "code": "indonesian"],
                          ["name" : "International", "code": "international"],
                          ["name" : "Irish", "code": "irish"],
                          ["name" : "Island Pub", "code": "island_pub"],
                          ["name" : "Israeli", "code": "israeli"],
                          ["name" : "Italian", "code": "italian"],
                          ["name" : "Japanese", "code": "japanese"],
                          ["name" : "Jewish", "code": "jewish"],
                          ["name" : "Kebab", "code": "kebab"],
                          ["name" : "Korean", "code": "korean"],
                          ["name" : "Kosher", "code": "kosher"],
                          ["name" : "Kurdish", "code": "kurdish"],
                          ["name" : "Laos", "code": "laos"],
                          ["name" : "Laotian", "code": "laotian"],
                          ["name" : "Latin American", "code": "latin"],
                          ["name" : "Live/Raw Food", "code": "raw_food"],
                          ["name" : "Lyonnais", "code": "lyonnais"],
                          ["name" : "Malaysian", "code": "malaysian"],
                          ["name" : "Meatballs", "code": "meatballs"],
                          ["name" : "Mediterranean", "code": "mediterranean"],
                          ["name" : "Mexican", "code": "mexican"],
                          ["name" : "Middle Eastern", "code": "mideastern"],
                          ["name" : "Milk Bars", "code": "milkbars"],
                          ["name" : "Modern Australian", "code": "modern_australian"],
                          ["name" : "Modern European", "code": "modern_european"],
                          ["name" : "Mongolian", "code": "mongolian"],
                          ["name" : "Moroccan", "code": "moroccan"],
                          ["name" : "New Zealand", "code": "newzealand"],
                          ["name" : "Night Food", "code": "nightfood"],
                          ["name" : "Norcinerie", "code": "norcinerie"],
                          ["name" : "Open Sandwiches", "code": "opensandwiches"],
                          ["name" : "Oriental", "code": "oriental"],
                          ["name" : "Pakistani", "code": "pakistani"],
                          ["name" : "Parent Cafes", "code": "eltern_cafes"],
                          ["name" : "Parma", "code": "parma"],
                          ["name" : "Persian/Iranian", "code": "persian"],
                          ["name" : "Peruvian", "code": "peruvian"],
                          ["name" : "Pita", "code": "pita"],
                          ["name" : "Pizza", "code": "pizza"],
                          ["name" : "Polish", "code": "polish"],
                          ["name" : "Portuguese", "code": "portuguese"],
                          ["name" : "Potatoes", "code": "potatoes"],
                          ["name" : "Poutineries", "code": "poutineries"],
                          ["name" : "Pub Food", "code": "pubfood"],
                          ["name" : "Rice", "code": "riceshop"],
                          ["name" : "Romanian", "code": "romanian"],
                          ["name" : "Rotisserie Chicken", "code": "rotisserie_chicken"],
                          ["name" : "Rumanian", "code": "rumanian"],
                          ["name" : "Russian", "code": "russian"],
                          ["name" : "Salad", "code": "salad"],
                          ["name" : "Sandwiches", "code": "sandwiches"],
                          ["name" : "Scandinavian", "code": "scandinavian"],
                          ["name" : "Scottish", "code": "scottish"],
                          ["name" : "Seafood", "code": "seafood"],
                          ["name" : "Serbo Croatian", "code": "serbocroatian"],
                          ["name" : "Signature Cuisine", "code": "signature_cuisine"],
                          ["name" : "Singaporean", "code": "singaporean"],
                          ["name" : "Slovakian", "code": "slovakian"],
                          ["name" : "Soul Food", "code": "soulfood"],
                          ["name" : "Soup", "code": "soup"],
                          ["name" : "Southern", "code": "southern"],
                          ["name" : "Spanish", "code": "spanish"],
                          ["name" : "Steakhouses", "code": "steak"],
                          ["name" : "Sushi Bars", "code": "sushi"],
                          ["name" : "Swabian", "code": "swabian"],
                          ["name" : "Swedish", "code": "swedish"],
                          ["name" : "Swiss Food", "code": "swissfood"],
                          ["name" : "Tabernas", "code": "tabernas"],
                          ["name" : "Taiwanese", "code": "taiwanese"],
                          ["name" : "Tapas Bars", "code": "tapas"],
                          ["name" : "Tapas/Small Plates", "code": "tapasmallplates"],
                          ["name" : "Tex-Mex", "code": "tex-mex"],
                          ["name" : "Thai", "code": "thai"],
                          ["name" : "Traditional Norwegian", "code": "norwegian"],
                          ["name" : "Traditional Swedish", "code": "traditional_swedish"],
                          ["name" : "Trattorie", "code": "trattorie"],
                          ["name" : "Turkish", "code": "turkish"],
                          ["name" : "Ukrainian", "code": "ukrainian"],
                          ["name" : "Uzbek", "code": "uzbek"],
                          ["name" : "Vegan", "code": "vegan"],
                          ["name" : "Vegetarian", "code": "vegetarian"],
                          ["name" : "Venison", "code": "venison"],
                          ["name" : "Vietnamese", "code": "vietnamese"],
                          ["name" : "Wok", "code": "wok"],
                          ["name" : "Wraps", "code": "wraps"],
                          ["name" : "Yugoslav", "code": "yugoslav"]]
        return categories
    }

}
