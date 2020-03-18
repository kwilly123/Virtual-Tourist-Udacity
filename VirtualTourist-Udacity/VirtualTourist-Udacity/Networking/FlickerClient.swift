//
//  FlickerClient.swift
//  VirtualTourist-Udacity
//
//  Created by Kyle Wilson on 2020-03-17.
//  Copyright © 2020 Xcode Tips. All rights reserved.
//

import Foundation
import UIKit

class FlickrClient {
    
    enum Endpoints {
        static let flickrAPIKey = "aed2488cdf52eca5a0537d095675300f"
        static let flickrAPISecret = "9cc6ccddbc853415"
        static let baseURL = "https://www.flickr.com/services/rest/?method=flickr.photos.search"
        static let searchMethod = "flickr.photos.search"
        static let numOfPhotos = 20
        case searchURL(Double, Double, Int, Int)
        
        var urlString: String {
            switch self {
            case .searchURL(let lat, let lon, let perPage, let pageNum):
                return Endpoints.baseURL + "&api_key=\(Endpoints.flickrAPIKey)" + "&lat=\(lat)" + "&lon=\(lon)" + "&radius=\(Endpoints.numOfPhotos)" + "&per_page=\(perPage)" + "&page=\(pageNum)" + "&format=json&nojsoncallback=1&extras=url_m"
                
            }
        }
        
        var url: URL {
            return URL(string: urlString)!
        }
    }
    
    class func getRandomPageNumber(totalPictures: Int, picturesDisplayed: Int) -> Int {
        let flickrLimit = 4000
        let numberOfPages = min(totalPictures, flickrLimit) / picturesDisplayed
        let randomPageNumber = Int.random(in: 0...numberOfPages)
        return randomPageNumber
    }
    
    class func getFlickrURL(latitude: Double, longitude: Double, totalPages: Int = 0, picturesPerPage: Int = 15) -> URL {
        let perPage = picturesPerPage
        let pageNum = getRandomPageNumber(totalPictures: totalPages, picturesDisplayed: picturesPerPage)
        let searchURL = Endpoints.searchURL(latitude, longitude, perPage, pageNum).url
        return searchURL
    }
    
    class func searchPhotos(lat: Double, lon: Double, totalPageAmt: Int = 0, completion: @escaping ([UIImage], Error?) -> Void) {
        var parsedResult: [String : AnyObject]!
        let url = getFlickrURL(latitude: lat, longitude: lon, totalPages: totalPageAmt)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                completion([], error)
                print(error?.localizedDescription ?? "error")
                return
            }
            
            guard let data = data else {
                completion([], error)
                return
            }
            
            do {
//                let decoder = JSONDecoder()
//                let response = try decoder.decode(PhotosParser.self, from: data)
//                print(response)
//                completion(response.photos.photo, response.photos.pages, nil)
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : AnyObject]
                print(parsedResult ?? "parsed result nil")
            } catch let error {
                print(error.localizedDescription)
            }
            
            guard let stat = parsedResult[FlickrConstants.FlickrResponseKeys.Status] as? String, stat == FlickrConstants.FlickrResponseValues.OKStatus else {
                fatalError("Flickr API returned an error. See error code and message in \(String(describing: parsedResult))")
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult[FlickrConstants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                fatalError("Cannot find key '\(FlickrConstants.FlickrResponseKeys.Photos)' in \(String(describing: parsedResult))")
            }
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary[FlickrConstants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                fatalError("Cannot find key '\(FlickrConstants.FlickrResponseKeys.Photo)' in \(photosDictionary)")
            }
            
            if photosArray.count == 0 {
                fatalError("No Photos Found. Search Again.")
            } else {
                var imageArray: [UIImage] = []
                for _ in 1...21{
                    let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                    let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                    /* GUARD: Does our photo have a key for 'url_m'? */
                    guard let imageUrlString = photoDictionary[FlickrConstants.FlickrResponseKeys.MediumURL] as? String else {
                        fatalError("Cannot find key '\(FlickrConstants.FlickrResponseKeys.MediumURL)' in \(photoDictionary)")
                    }
                    
                    let imageURL = URL(string: imageUrlString)
                    if let imageData = try? Data(contentsOf: imageURL!) {
                        
                        imageArray.append(UIImage(data: imageData)!)

                    } else {
                        fatalError("Image does not exist at \(String(describing: imageURL))")
                    }

                }
                completion(imageArray, nil)
            }
        }
        task.resume()
    }
    
    class func downloadImage(imageURL: String, completion: @escaping (Data?, Error?) -> Void) {
        let url = URL(string: imageURL)
        guard let imageURL = url else {
            completion(nil, nil)
            return
        }
        let request = URLRequest(url: imageURL)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion(data, nil)
            }
        }
        task.resume()
    }
}
