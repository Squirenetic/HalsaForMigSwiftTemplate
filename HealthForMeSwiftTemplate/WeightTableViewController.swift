//
//  WeightTableViewController.swift
//  HealthForMeSwiftTemplate
//  Swift Template by Henrik Larsson

import UIKit


class WeightTableViewController: UITableViewController {
    
    var items: HVItemCollection?

    
    //---------------------------
    //
    //# MARK: - Application Startup
    //
    //---------------------------
    
    func startApp() {
        
        let notify: HVNotify = { Void in
            if HVClient.current().provisionStatus == HVAppProvisionSuccess {
                self.startupSuccess()
            }
            else {
                self.startupFailed()
            }
        }
        
        HVClient.current().startWithParentController(self, andStartedCallback: notify)
        
    }
    
    
    func startupSuccess() {
        //
        // Update the UI to show the record owner's display name
        //
        let displayName = HVClient.current().currentRecord.displayName
        self.navigationItem.title = "\(displayName)'s Weight"
        //
        // Fetch list of weights from HealthVault
        //
        self.getWeightsFromHealthVault()
    }
    
    
    func startupFailed() {
        HVUIAlert.showWithMessage("Provisioning not completed. Retry?", callback: {(sender: AnyObject) -> Void in
            let alert = (sender as! HVUIAlert)
            if alert.result == HVUIAlertOK {
                self.startApp()
            }
            } as! HVNotify)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.startApp()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items != nil ? items!.count : 0
    }

    // Customize the appearance of table view cells.
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("WeightCell", forIndexPath: indexPath) as UITableViewCell

        let itemIndex = indexPath.row
        //
        // Retrieve weight information for the given HealthVault item
        //
        if let items = self.items {
        let weight = items.itemAtIndex(UInt(itemIndex)).weight()
        
        //
        // Display it in the table cell for the current row
        //
        cell.textLabel!.text = weight.when.toStringWithFormat("MM/dd/YY hh:mm aaa")
        cell.detailTextLabel!.text = weight.stringInKgWithFormat("%.2f kg")
        }
        return cell
    }

    
    func refreshView() {
        self.tableView.reloadData()
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }


    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            self.removeWeightFromHealthVault(items!.itemAtIndex(UInt(indexPath.row)).key)

            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    

    //-------------------------------------------
    //
    //# MARK: - Add/Remove DataVault Items
    //
    //-------------------------------------------
    
    
    func getWeightsFromHealthVault() {

        
        HVClient.current().currentRecord.getItemsForClass(HVWeight.self, callback: { task in
            do {
                //
                // Save the collection of items retrieved
                //

                self.items = (task as! HVGetItemsTask).itemsRetrieved
                if let items = self.items {
                    print(items.count)
                }
                //
                // Refresh UI
                //
                self.refreshView()
                
            }   catch {
                HVUIAlert.showInformationalMessage("Failed to get weights from HealthVault")
            }
            })
    }

    // Push a new weight into HealthVault
    func putWeightInHealthVault(item: HVItem) {
    
    print("putting item with weight \(item.weight().inKg) in vault")

        HVClient.current().currentRecord.putItem(item, callback: { task in
            
            do {
                //
                // Throws if there was a failure. Look at HVServerException for details
                //
                task.checkSuccess()
                //
                // Refresh with the latest list of weights from HealthVault
                //
                self.getWeightsFromHealthVault()
                
            }  catch {
                HVUIAlert.showInformationalMessage("Failed to add weight to HealthVault")
            }
        })
        
    }
    
    
    func removeWeightFromHealthVault(itemKey: HVItemKey) {
        
        let task: HVTaskCompletion = { task in
            do {
                task.checkSuccess()
                //
                // Refresh
                //
                self.getWeightsFromHealthVault()
            }         catch {
                HVUIAlert.showInformationalMessage("Failed to remove weight from HealthVault")
            }
        }
        HVClient.current().currentRecord.removeItemWithKey(itemKey, callback: task)
    }

    
    // Create a new random weight between 130 and 150 pounds, and the current date&time
    func newWeight() -> HVItem {
        let item = HVWeight.newItem()
        let kilos: Double = roundToPrecision(HVRandom.randomDoubleInRangeMin(50, max: 150), 2)
        item.weight().inKg = kilos
        item.weight().when = HVDateTime.init(now: ())

        return item
    }
    
    
    func changeWeight(item: HVItem) {
        item.weight().inKg = HVRandom.randomDoubleInRangeMin(50, max: 150)
    }
    
    
    func getWeightsForLastNDays(numDays: Int) {
        
        // Set up a filter for HealthVault items
        let itemFilter = HVItemFilter.init(typeClass: HVWeight.self as AnyClass)
        // Querying for weights
        //
        // We only want weights no older than numDays
        //
        itemFilter.effectiveDateMin = NSDate(timeIntervalSinceNow: (-(Double(numDays) * (24 * 3600))))
        // Interval is in seconds
        
        // Create a query to issue
        let query: HVItemQuery =  HVItemQuery.init(filter: itemFilter)
      
        let task: HVTaskCompletion = { task in
            do {
                //
                // Save the collection of items retrieved
                //
//                HVCLEAR(m_items)
                self.items = (task as! HVGetItemsTask).itemsRetrieved
                //
                // Refresh UI
                //
                self.refreshView()
            }  catch {
                HVUIAlert.showInformationalMessage("Failed to retrieve weights")

        }
    }
        
        HVClient.current().currentRecord.getItems(query, callback: task)
    }
    
    
    //-------------------------------------------
    //
    // # MARK: - Button Handlers
    //
    //-------------------------------------------

    
    // Refresh Displayed Data from HealthVault
    @IBAction func refreshButtonClicked(sender: AnyObject) {
        self.getWeightsFromHealthVault()
    }
    
    // Generate a random new weight entry for today and add it to HealthVault
    @IBAction func addButtonClicked(sender: AnyObject) {
        
        let item = self.newWeight()
        self.putWeightInHealthVault(item)
    }
    
    // Delete the selected item from HealthVault
    @IBAction func deleteButtonClicked(sender: AnyObject) {
        if let selection = self.tableView.indexPathForSelectedRow {
            let itemIndex = selection.row
            self.removeWeightFromHealthVault(items!.itemAtIndex(UInt(itemIndex))!.key)
        } else {
            return
        }
    }
    
    // Change the selected item to a new weight and push it to HealthVault
    @IBAction func updateButtonClicked(sender: AnyObject) {
        if let selection = self.tableView.indexPathForSelectedRow {
            let itemIndex = selection.row
            let item = items!.itemAtIndex(UInt(itemIndex))!
            self.changeWeight(item)
            self.putWeightInHealthVault(item)
        } else {
            return
        }
    }


    // User may want to disconnect their account
    @IBAction func disconnectClicked(sender: AnyObject) {
        
        let notifier: HVNotify = { sender in
            let alert = (sender as! HVUIAlert)
            if alert.result != HVUIAlertOK {
                return
            }
            HVClear(self.items)
            self.refreshView()
            //
            // REMOVE RECORD AUTHORIZATION.
            //
            
            let task: HVTaskCompletion = { void in
                HVClient.current().resetProvisioning()
                // Removes local state
                let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
                for cookie: NSHTTPCookie in storage.cookies! {
                    storage.deleteCookie(cookie)
                }
                NSUserDefaults.standardUserDefaults().synchronize()
                //
                // Restart app auth
                //
                self.startApp()
            }
            HVClient.current().user.removeAuthForRecord(HVClient.current().currentRecord, withCallback: task)
        }
        
        let message = "Are you sure you want to disconnect this application from HealthVault?\r\nIf you click Yes, you will need to re-authorize the app."
        HVUIAlert.showYesNoWithMessage(message, callback: notifier)
    }

    
    
}
