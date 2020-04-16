//
//  VideoController.swift
//  RWFaceCase
//
//  Created by Jonathan Tipton on 4/16/20.
//  Copyright © 2020 Razeware. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class VideoController: UIViewController {

    override func prepare(for segue: UIStoryboardSegue, sender:Any?) {
        let destination = segue.destination as! AVPlayerViewController
        let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8")
        if let movieURL = url {
            destination.player = AVPlayer(url:movieURL)
            //destination.player?.play()
        }
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPicutreStopWithCompletionHandler completionHandler: @escaping(Bool)->Void) {
        let currentViewController = navigationController?.visibleViewController
        if currentViewController != playerViewController {
            if let topViewController = navigationController?.topViewController {
                topViewController.present(playerViewController, animated:true, completion: {();
                    completionHandler(true)
                })
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}

