//
//  CountrySelection.swift
//  ConfirmediOS
//
//  Copyright © 2018 Confirmed Inc. All rights reserved.
//
// Flags - https://www.behance.net/gallery/11709619/181-Flat-World-Flags

import UIKit

class CountrySelection: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    //MARK: - ACTION
    func initializeCountries(_ vpnView : UIView) {
        var vpnFrame = vpnView.frame
        vpnFrame.origin.y = vpnView.frame.size.height
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = vpnFrame
        tableView.frame.size.height -= 74
        
        loadEndpoints()
        
        tableView.rowHeight = 80
        vpnView.addSubview(tableView)
        super.awakeFromNib()
        
        tableView.reloadData()
    }
    
    func loadEndpoints() {
        items.removeAll()
        
        items.append(ServerEndpoint.init(countryName: "United States - West".localized(), flagImagePath: "usa_flag", countryCode: "us", endpoint: Global.endPoint(base: "us-west")))
        items.append(ServerEndpoint.init(countryName: "United States - East".localized(), flagImagePath: "usa_flag", countryCode: "us", endpoint: Global.endPoint(base: "us-east")))
        items.append(ServerEndpoint.init(countryName: "United Kingdom".localized(), flagImagePath: "great_brittain", countryCode: "uk", endpoint: Global.endPoint(base: "eu-london")))
        items.append(ServerEndpoint.init(countryName: "Ireland".localized(), flagImagePath: "ireland_flag", countryCode: "irl", endpoint: Global.endPoint(base: "eu-ireland")))
        items.append(ServerEndpoint.init(countryName: "Germany".localized(), flagImagePath: "germany_flag", countryCode: "de", endpoint: Global.endPoint(base: "eu-frankfurt")))
        items.append(ServerEndpoint.init(countryName: "Canada".localized(), flagImagePath: "canada_flag", countryCode: "ca", endpoint: Global.endPoint(base: "canada")))
        items.append(ServerEndpoint.init(countryName: "Japan".localized(), flagImagePath: "japan_flag", countryCode: "jp", endpoint: Global.endPoint(base: "ap-tokyo")))
        items.append(ServerEndpoint.init(countryName: "Australia".localized(), flagImagePath: "australia_flag", countryCode: "au", endpoint: Global.endPoint(base: "ap-sydney")))
        items.append(ServerEndpoint.init(countryName: "South Korea".localized(), flagImagePath: "korea_flag", countryCode: "kr", endpoint: Global.endPoint(base: "ap-seoul")))
        items.append(ServerEndpoint.init(countryName: "Singapore".localized(), flagImagePath: "singapore_flag", countryCode: "sg", endpoint: Global.endPoint(base: "ap-singapore")))
        items.append(ServerEndpoint.init(countryName: "India".localized(), flagImagePath: "india_flag", countryCode: "in", endpoint: Global.endPoint(base: "ap-mumbai")))
        items.append(ServerEndpoint.init(countryName: "Brazil".localized(), flagImagePath: "brazil_flag", countryCode: "br", endpoint: Global.endPoint(base: "sa")))
    }
    
    
    //MARK: - TABLEVIEW
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            return 80
        }
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NotificationCenter.default.post(name: .changeCountry, object: items[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.textLabel?.textColor = UIColor.white
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.textLabel?.textColor = UIColor.init(white: 0.25, alpha: 1.0)
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let cell = CountryTableViewCell.init()//tableView.dequeueReusableCell(withIdentifier: "Cell")
        
        cell.imageView?.image = UIImage.init(named: items[indexPath.row].flagImagePath)
        if UI_USER_INTERFACE_IDIOM() == .pad {
            cell.textLabel?.font = UIFont.init(name: "AvenirNext-Regular", size: 16)
        }
        else {
            cell.textLabel?.font = UIFont.init(name: "AvenirNext-Regular", size: 14)
        }
        cell.textLabel?.textColor = UIColor.init(white: 0.25, alpha: 1.0)
        cell.imageView?.contentMode = .scaleToFill
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.tunnelsBlueColor
        cell.selectedBackgroundView = bgColorView
        
        
        cell.textLabel?.text = items[indexPath.row].countryName
        return cell
    }
    
    //MARK: - VARIABLES
    var items = [ServerEndpoint]() // = []
    let tableView = UITableView()
}
