//
//  LoginViewController.swift
//  HeadlessDemo
//
//  Created by Mathias Köhnke on 28/11/15.
//  Copyright © 2015 Mathias Köhnke. All rights reserved.
//

import UIKit

class LoginViewController : UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    let landingURLString = "https://developer.apple.com/membercenter/index.action"
    let loginURLString = "https://idmsa.apple.com/IDMSWebAuth/authenticate"
    let accountOverviewURLString = "https://developer.apple.com/account/overview.action"
    
    var headless : Headless!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func loginButtonTouched(sender: AnyObject) {
        headless = Headless(name: "DeveloperPortal")
        let url = NSURL(string: landingURLString)!
        getProvisioningProfiles(url).start { result in
            switch result {
            case .Success(let rows):
                print(rows)
            case .Error(let error):
                print(error)
            }
        }
    }
    
    func submitLoginForm(page: Page) -> Future<Page, Error> {
        if let form = page.formWith("form2") {
            form["appleId"] = "mathias.koehnke@gmail.com" //nameTextField.text
            form["accountPassword"] = "InFezww20JvEYc" //passwordTextField.text
            return headless.submit(form)
        }
        return Future(error: Error.NetworkRequestFailure)
    }
    
    func getAccountOverview(page: Page) -> Future<Page, Error> {
        return headless.get(NSURL(string: accountOverviewURLString)!)
    }
    
    func getProfilesPage(page: Page) -> Future<Page, Error> {
        let link = page.linksWith("//a[contains(@href,'ios') and contains(@href, 'profileList')]/@href")!.first!
        return headless.click(link)
    }
    
    func getProfilesTable(page: Page) -> Future<[Element], Error> {
        if let rows = page.elementsWith("//td") {
            return Future(result: Result.Success(rows))
        }
        return Future(result: Result.Error(.NetworkRequestFailure))
    }
    
    func getProvisioningProfiles(url: NSURL) -> Future<[Element], Error> {
        return headless.get(url) >>> submitLoginForm >>> getAccountOverview >>> getProfilesPage >>> getProfilesTable
    }
}
