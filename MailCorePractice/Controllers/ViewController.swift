//
//  ViewController.swift
//  MailCorePractice
//
//  Created by Koh Jia Rong on 2019/2/1.
//  Copyright © 2019 Koh Jia Rong. All rights reserved.
//

import UIKit
import GTMAppAuth
import AppAuth
import Kanna
import SigmaSwiftStatistics

class ViewController: UITableViewController {

//    let clientID = "382696408917-76dm92efvi9nhmqjnv3fmu56nv71l6j0.apps.googleusercontent.com"
//    let clientSecret = "HF7wjjBXHojp6W774qXLZBSz"
//
    let kIssuer = "https://accounts.google.com"
    let kClientID = "382696408917-r139aava2dj6jlgluatmoqnc019vplo8.apps.googleusercontent.com"
    let kRedirectURI = "com.googleusercontent.apps.382696408917-r139aava2dj6jlgluatmoqnc019vplo8:/oauthredirect"
    let kExampleAuthorizerKey = "googleOAuthCodingKey"
    
    var messages = [Message]()
    
    let edisonAccount = Account(username: "jiarong.xu@edison.tech", password: "S9048009Z", hostname: "imap.gmail.com", port: 993)
    let account126 = Account(username: "jiarongkoh@126.com", password: "edison123", hostname: "smtp.126.com", port: 465)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sent", style: .plain, target: self, action: #selector(alertControllerForSendEmail))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Authenticate", style: .plain, target: self, action: #selector(authenticateGmailIfNeeded))
        
        setupTableView()
//        fetchEmailsFrom126()
//        substringTest()
//        topNPercentile()
        authenticateGmailIfNeeded()
//        testSubstring()

    }
    
    func testSubstring() {
        let strings = ["ON/OFF office lights",
                       "DIM office lights",
                       "VALUE office lights",
                       "FB office lights",
                       "FB VALUE office lights"]
        print(Utilities.substringOf(strings))

    }
    
    @objc func authenticateGmailIfNeeded() {
        GmailHelper.shared.doEmailLoginIfRequired(viewController: self) {
            if
                let authorization = GTMAppAuthFetcherAuthorization(fromKeychainForName: self.kExampleAuthorizerKey),
                let accessToken = authorization.authState.lastTokenResponse?.accessToken {
                self.fetchEmailsFromGmail(accessToken: accessToken)
            }
        }
        
//        substringTest()
    }
    
    @objc func alertControllerForSendEmail() {
        let alert = UIAlertController(title: "Send email", message: nil, preferredStyle: .actionSheet)
        let gmailAction = UIAlertAction(title: "Gmail", style: .default) { (_) in
            self.sendEmail(account: self.edisonAccount)
        }
        let email126Action = UIAlertAction(title: "126", style: .default) { (_) in
            self.sendEmail(account: self.account126)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(gmailAction)
        alert.addAction(email126Action)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    var host = "210.12.48.100"
    
    func fetchEmailsFromGmail(accessToken: String) {
        print("Fetching emails from Gmail...")
        let session = MCOIMAPSession()
        session.hostname = "imap.gmail.com"
        session.port = 993
        session.username = "jiarong.xu@edison.tech"
        session.authType = .xoAuth2
        session.connectionType = .TLS
        session.oAuth2Token = accessToken
        session.dispatchQueue = .global()

        let requestKind: MCOIMAPMessagesRequestKind = [.headers, .flags]
        let folder = "[Gmail]/Sent Mail"
        let uids = MCOIndexSet(range: MCORangeMake(1, UINT64_MAX))
        
        session.connectionLogger = {(connectionID, type, data) in
            if let data = data {
                if let string = String(data: data, encoding: String.Encoding.utf8) {
//                    NSLog("Connectionlogger: \(string)")
                }
            }
        }
        
        downloadEmails(session: session, folder: folder, requestKind: requestKind, uids: uids)
    }
    
    func fetchEmailsFrom126() {
        print("Fetching emails from 126...")

        let session = MCOIMAPSession()
        session.hostname = "imap.126.com"
        session.port = 993
        session.username = "jiarongkoh@126.com"
        session.password = "edison123"
        session.connectionType = .TLS
        session.dispatchQueue = .global()
        
        let requestKind: MCOIMAPMessagesRequestKind = [.headers, .flags]
        let folder = "INBOX"
        let uids = MCOIndexSet(range: MCORangeMake(1, UINT64_MAX))
        
//        fetchFolders(session: session)

        downloadEmails(session: session, folder: folder, requestKind: requestKind, uids: uids)
    }
    
    func sendEmail(account: Account) {
        print("Sending message...")
        
        let smtpSession = MCOSMTPSession()
        smtpSession.hostname = account.hostname
        smtpSession.port = account.port ?? 465
        smtpSession.username = account.username
        smtpSession.password = account.password
        smtpSession.connectionType = .TLS
        
        let builder = MCOMessageBuilder()
        builder.header.from = MCOAddress(displayName: nil, mailbox: account.username)
        
        let newAddress = MCOAddress(displayName: nil, mailbox: account.username)
        builder.header.to = [newAddress!]
        
        builder.header.subject = "Attachment test!!"
        builder.textBody = "Weeee from test app"
        
        let image = UIImage(named: "coffeebeans")
        let imageData = image?.jpegData(compressionQuality: 1)
        let attachment = MCOAttachment(data: imageData, filename: "coffee.png")
        builder.addAttachment(attachment)
        
        let rfc822Data = builder.data()
        let sendOperation = smtpSession.sendOperation(with: rfc822Data)
        sendOperation?.start({ (error) in
            if let error = error {
                print("Error sending message:", error.localizedDescription)
                return
            }
            
            print("Message sent")
        })
    }
    
    func fetchFolders(session: MCOIMAPSession) {
        let fetchFolderOperation = session.fetchAllFoldersOperation()
        fetchFolderOperation?.start({ (error, folders) in
            if let error = error {
                print("Error fetching folders:", error.localizedDescription)
                return
            }
            
            if let folders = folders, !folders.isEmpty {
                print(folders)
            }
        })
    }
    
    func downloadEmails(session: MCOIMAPSession, folder: String, requestKind: MCOIMAPMessagesRequestKind, uids: MCOIndexSet?) {
        fetchMessagesBody(session: session, folder: folder, requestKind: requestKind, uids: uids) { (messages, error) in
            if let error = error {
                print("Error downloading emails:", error.localizedDescription)
                return
            }
            
            if let messages = messages {
                self.messages = messages.reversed()
                
                messages.forEach({ (message) in
                    var htmlString = message.bodyText ?? ""
                    htmlString = htmlString.replacingOccurrences(of: "<blockquote[^>]*>(.*)?</blockquote>", with: "", options: .regularExpression, range: nil)
//                    print("==============")
//                    print(message.bodyText ?? "")
//                    print("\n")
                  
                    
                    if let doc = try? HTML(html: htmlString, encoding: .utf8) {
//                        print(doc.body?.innerHTML)
//                        print(doc.body?.text ?? "")
                        
                        
                        //html//body//div[@dir='ltr']
                        for _ in doc.xpath("//html//body") {

                        }
                    }
                })
                
                DispatchQueue.main.async {
                    NSLog("Finished dowloading emails")
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func fetchMessagesBody(session: MCOIMAPSession, folder: String, requestKind: MCOIMAPMessagesRequestKind, uids: MCOIndexSet?, completion: @escaping (_ messages: [Message]?, _ error: Error?) -> Void) {
        
        let fetchOperation = session.fetchMessagesOperation(withFolder: folder, requestKind: requestKind, uids: uids)
        
        fetchOperation?.start({ (error, messages, vanishedMessages) in
            completion(nil, error)
            
            if let vanishedMessages = vanishedMessages {
                print(vanishedMessages)
            }
            
            if let messages = messages, !messages.isEmpty {
                var messsageArray = [Message]()
                let downloadGroup = DispatchGroup()
                
                messages.forEach({ (message) in
                    downloadGroup.enter()
                    let op = session.fetchMessageOperation(withFolder: folder, uid: message.uid)
                    op?.start({ (error, data) in
                        if let _ = error {
                            downloadGroup.leave()
                        }
                        
                        if let data = data {
                            
                            let messageParser = MCOMessageParser(data: data)
                            let subject = messageParser?.header.subject
                            let reply = messageParser?.header.inReplyTo
                            let htmlBodyText = messageParser?.htmlBodyRendering()
                            let plainBodyText = messageParser?.plainTextRendering()
                            
                            print("====Messages=====")
                            print(reply)
//                            print(htmlBodyText ?? "")
                            print(plainBodyText ?? "")
                            
                            if let doc = try? HTML(html: htmlBodyText ?? "", encoding: .utf8) {
                                print(doc.body?.innerHTML)
                                print(doc.body?.text ?? "")
                                //html//body//div[@dir='ltr']
                                for _ in doc.xpath("//html//body") {
                                    
                                }
                            }
                            
                            let message = Message(subject: subject, bodyText: htmlBodyText)
                            messsageArray.append(message)
                            downloadGroup.leave()
                        }
                    })
                })

                downloadGroup.notify(queue: .global(), execute: {
                    completion(messsageArray, nil)
                })
            }
        })
    }
    
    func substringTest() {
        let messages = ["Hi Prof and Wen RongPls see attached for my submission of my FYP thesis.Yours SincerelyKoh Jia RongA0097723",
                        "Dear Ms LimI would like to make an enquiry on the degree classification for the poly students graduating this year. We realised that our (poly students) degree classification is the new degree classification (Distinction, Merit etc) instead of the former degree classification (First, Second, Third).We felt that there is a need to clarify this standing as it appears to fall in a gray area. While we understand that the new degree classification is implemented for the 'Student Intake from Cohort 2012/13 Onwards', the poly students fall under the intake of 2012 but follows the 2011 cohort. That would mean that our JC counterparts graduating this year will follow the former classification and the poly students will follow the new classification. We appreciate it if you could kindly assist in the above clarifications pls, thank you!Yours SincerelyKoh Jia RongA0097723",
                        "Hi Prof Chui and Wen Rong Apologies for being MIA these few days. Exams ended last week and I have been dealing with NS stuffs ever since till today. I will be able to resume my FYP tmr onwards and was wondering if you might wanna do a meet up tmr? Yours SincerelyKoh Jia Rong",
                        "Dear Zhi YingI am interested to sign up for the Mechanical Engineering FEE Prep Course but realised that there is no course scheduling found on the IES calendar. I searched ard but to no avail too. I see that this course is conducted from July till August last year, so I would like to enquire about the details of the course for this year.If there is no course details release yet, may I ask when would the details likely be released? Appreciate if you could assist with my enquiries, thanks!Yours SincerelyKoh Jia RongA0097723",
                        "Thats all the TA uploaded.Yours SincerelyKoh Jia RongA0097723",
                        "Koh Jia Rong has attached the following presentation:Update Needle Insertion 150215Hi Prof and Wen RongAnother update, this time on the attempt to draw the needle for the insertion. Again I attached a simple slideshow.Here I simulated using a .txt file as if the Kinect data is streaming in 'live'. Reading the txt file and inputting into the rendering class is fine, but the screen freezes everytime it updates. I am still working on this so pls do give me some time.Aside to ProfRegarding photoshop-ping the skin image, I originally did want to perform the photoshop but my computer couldn't handle the software and hence I used some mobile image editting apps to change the exposure at best as I could.I will source for photoshop in school and will update you again.Google Slides: Create and edit presentations online.",
//                        "Dear Ms LimI would like to make an enquiry on the degree classification for the poly students graduating this year. We realised that our (poly students) degree classification is the new degree classification (Distinction, Merit etc) instead of the former degree classification (First, Second, Third).We felt that there is a need to clarify this standing as it appears to fall in a gray area. While we understand that the new degree classification is implemented for the 'Student Intake from Cohort 2012/13 Onwards', the poly students fall under the intake of 2012 but follows the 2011 cohort. That would mean that our JC counterparts graduating this year will follow the former classification and the poly students will follow the new classification. We appreciate it if you could kindly assist in the above clarifications pls, thank you!Yours SincerelyKoh Jia RongA0097723",
//                        "Hi Prof Chui and Wen RongApologies for being MIA these few days. Exams ended last week and I have been dealing with NS stuffs ever since till today. I will be able to resume my FYP tmr onwards and was wondering if you might wanna do a meet up tmr?Yours SincerelyKoh Jia Rong",
//                        "Koh Jia Rong has attached the following presentation:Update 100215Hi Prof and Wen RongI attempted to use a photo of skin as an image marker but the results turn out to be bad. I attached a simple slide show to illustrate the attempts.Yours SincerelyKoh Jia RongA0097723Google Slides: Create and edit presentations online."
        
        ]
        
        
//        let matrix = [1,2,3,4,5,6,7,8,9,10]
        compareStrings(messages: messages.shuffled()) { (lcsArray) in
            if let lcsArray = lcsArray {
                print("Count of LCSArray", lcsArray.count)
                
//                print(lcsArray)
                
                for (index, dictionary) in lcsArray.enumerated() {
                    let count = dictionary.value.count
                    
                    print(dictionary.key, count)
                }
            }
        }
        
        
        
    }
    
    private func lcSubstring(_ X : String  , _ Y : String  ) -> String {
        let m = X.count
        let n = Y.count
        
        var L = Array(repeating: Array(repeating: 0, count: n + 1 ) , count: m + 1)
        var result : (length : Int, iEnd : Int, jEnd : Int) = (0,0,0)
        
        // Following steps build L[m+1][n+1] in bottom up fashion. Note
        // that L[i][j] contains length of LCS of X[0..i-1] and Y[0..j-1]
        for i in stride(from: 0, through: m, by: 1) {
            for j in stride(from: 0, through: n, by: 1) {
                if i == 0 || j == 0 {
                    L[i][j] = 0
                } else if X[X.index( X.startIndex , offsetBy: (i - 1) )] == Y[Y.index( Y.startIndex , offsetBy: (j - 1) )] {
                    L[i][j] = L[i-1][j-1] + 1
                    
                    if result.0 < L[i][j] {
                        result.length = L[i][j]
                        result.iEnd = i
                        result.jEnd = j
                    }
                } else {
                    L[i][j] = 0 //max(L[i-1][j], L[i][j-1])
                }
            }
        }
        
        //Print substring
        let lcs = X.substring(with: X.index(X.startIndex, offsetBy: result.iEnd-result.length)..<X.index(X.startIndex, offsetBy: result.iEnd))
        return lcs
    }
    
    func substringOf(_ strings : [String] ) -> String {
        var answer = strings[0]
        
        //Replace the first index of strings array (answer) with LCS as it loops across the string array
        for i in stride(from: 1, to: strings.count, by: 1) {
            answer = lcSubstring(answer,strings[i])
        }
        
        return answer
    }
    
    
    /*
     Create a table of X by X base on the length of the messages array and compare column to row.
     Taking an array of 5 integers as example, ie [1,2,3,4,5], create a matrix like so:
       1 2 3 4 5
     1 X
     2   X
     3     X
     4       X
     5         X
    
     Each blank space will be filled by the LCS between the row and column.
    */
    func compareStrings(messages: [String], _ completion: @escaping (_ lcsArray:[String: [String]]?) -> Void) {
        var lcsDictionary = [String: [String]]()
        var counter = 0

        DispatchQueue.global(qos: .userInitiated).async {
            print(Thread.current)
            for (i,_) in messages.enumerated() {
                for (j,_) in messages.enumerated() {
                    if i == j {
                        continue
                    }
                    let messagesToCompare = [messages[i], messages[j]]
                    let lcs = self.substringOf(messagesToCompare)
                    if var dictionary = lcsDictionary[lcs] {
                        dictionary.append(messages[i])
                        dictionary.append(messages[j])
                        lcsDictionary[lcs] = dictionary
                        
                    } else {
                        lcsDictionary[lcs] = [messages[i], messages[j]]
                    }
                    counter += 1
                }
            }
            
            print("Counter", counter)
            if counter == (messages.count * messages.count) - messages.count {
                DispatchQueue.main.async {
                    completion(lcsDictionary)
                }
            }
        }
    }

    func topNPercentile() {
        let dictionary = ["!Yours SincerelyKoh Jia Rong": 4,
                          " Yours SincerelyKoh Jia Rong": 4,
                          "Yours Sincerely": 36,
                          "Yours SincerelyKoh Jia Rong": 68,
                          ".Yours SincerelyKoh Jia RongA0097723": 4,
                          ".Yours SincerelyKoh Jia Rong": 8,
                          "Yours SincerelyKoh Jia RongA0097723": 56,
                          ]
        
        let dataset = dictionary.map { (dictionary) -> Double in
            return Double(dictionary.value)
        }
        
        print("Percentile", Sigma.percentile(dataset, percentile: 0.75))
    
    }


}
//
//SentEmailData(messageId: "imap.gmail.com:a0097723@gmail.com``[Gmail]/Sent Mail``348", originalMessage: "<html><body><div id=\"edo-message\"><div></div><a href=\"https://stackoverflow.com/questions/19179358/concurrent-vs-serial-queues-in-gcd/35810608#35810608\">https://stackoverflow.com/questions/19179358/concurrent-vs-serial-queues-in-gcd/35810608#35810608</a></div><div id=\"edo-message\"><br></div><div id=\"edo-message\"><a href=\"https://stackoverflow.com/questions/37805885/how-to-create-dispatch-queue-in-swift-3\">https://stackoverflow.com/questions/37805885/how-to-create-dispatch-queue-in-swift-3</a></div><div id=\"edo-meta\"><style hint=\"edo\">#edo-signature img {max-width: 90%}</style><div id=\"edo-signature\" style=\"font-family: sans-serif, \'Helvetica Neue\', Helvetica, Arial;font:\'-apple-system-body\';\"><br>Yours Sincerely<div>Jia Rong</div></div></div><div id=\"edo-original\"><div></div></div></body></html>", compressedMessage: "``````https://stackoverflow.com/questions/19179358/concurrent-vs-serial-queues-in-gcd/35810608#35810608```````https://stackoverflow.com/questions/37805885/how-to-create-dispatch-queue-in-swift-3````#edo-signature img {max-width: 90%}```Yours Sincerely`Jia Rong`````````")
