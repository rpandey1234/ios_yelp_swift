//
//  BusinessesViewController.swift
//  Yelp
//
//  Created by Timothy Lee on 4/23/15.
//  Copyright (c) 2015 Timothy Lee. All rights reserved.
//

import UIKit

class BusinessesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIScrollViewDelegate, FiltersViewControllerDelegate {
    
    static let RestaurantQuery = "restaurants"
    var businesses: [Business]!
    var filteredBusinesses: [Business]!
    var isMoreDataLoading = false
    var numShown = 0
    var currentFilters: [String : AnyObject] = [:]
    var loadingMoreView: InfiniteScrollActivityView?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 120
        
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.sizeToFit()
        navigationItem.titleView = searchBar
        
        // Set up Infinite Scroll loading indicator
        let frame = CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
        loadingMoreView = InfiniteScrollActivityView(frame: frame)
        loadingMoreView!.isHidden = true
        tableView.addSubview(loadingMoreView!)
        
        var insets = tableView.contentInset;
        insets.bottom += InfiniteScrollActivityView.defaultHeight;
        tableView.contentInset = insets
        
        loadData(offset: numShown)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print(searchText)
        filteredBusinesses = searchText.isEmpty ? businesses : businesses.filter({ (business: Business) -> Bool in
            if let name = business.name {
                return name.range(of: searchText, options: .caseInsensitive) != nil
            }
            return false
        })
        tableView.reloadData()
    }
    
    func loadData(offset: Int) {
        let categories = currentFilters["categories"] as! [String]?
        let deals = currentFilters["offeringDeal"] as! Bool?
        let sortCriteria = currentFilters["sortCriteria"] as! YelpSortMode?
        let distance = currentFilters["distance"] as! Int?
        
        Business.searchWithTerm(term: BusinessesViewController.RestaurantQuery, sort: sortCriteria, categories: categories, deals: deals, distance: distance, offset: offset) { (businesses: [Business]?, error: Error?) -> Void in
            if offset == 0 {
                self.businesses = businesses
                self.filteredBusinesses = self.businesses
                self.numShown = self.filteredBusinesses.count
            } else {
                if let businesses = businesses {
                    // TODO: find better way to append [Business]! and [Business]
                    for business in businesses {
                        self.businesses.append(business)
                    }
                }
                self.filteredBusinesses = self.businesses
                self.numShown += self.filteredBusinesses.count
            }
            self.tableView.reloadData()
            self.isMoreDataLoading = false
            self.loadingMoreView!.stopAnimating()
        }
    }
    
    func filtersViewController(filtersViewController: FiltersViewController, didUpdateFilters filters: [String : AnyObject]) {
        currentFilters = filters
        numShown = 0
        loadData(offset: numShown)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredBusinesses?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BusinessCell", for: indexPath) as! BusinessCell
        cell.business = filteredBusinesses[indexPath.row]
        return cell
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !isMoreDataLoading {
            // Calculate position of one screen length before the bottom of results
            let scrollViewContentHeight = tableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - tableView.bounds.size.height
            if scrollView.contentOffset.y > scrollOffsetThreshold && tableView.isDragging {
                isMoreDataLoading = true
                // Update position of loadingMoreView, and start loading indicator
                let frame = CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()
                
                // Code to load more results
                loadData(offset: numShown)
            }
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navigationController = segue.destination as! UINavigationController
        let filtersViewController = navigationController.topViewController as! FiltersViewController
        filtersViewController.delegate = self
    }
}
