//
//  FlickerConstants.swift
//  VirtualTourist-Udacity
//
//  Created by Kyle Wilson on 2020-03-18.
//  Copyright © 2020 Xcode Tips. All rights reserved.
//

import Foundation

struct FlickrConstants {
    
    struct FlickrResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let MediumURL = "url_m"
        static let Pages = "pages"
        static let Total = "total"
    }
    
    struct FlickrResponseValues {
        static let OKStatus = "ok"
    }
    
}
