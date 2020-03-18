//
//  AlbumViewController.swift
//  VirtualTourist-Udacity
//
//  Created by Kyle Wilson on 2020-03-17.
//  Copyright © 2020 Xcode Tips. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class AlbumViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newCollection: UIToolbar!
    
    var dataController: DataController!
    
    var selectedPin: Pin!
    
    var locationRetrieved: CLLocationCoordinate2D?
    
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    
    var photoImages = [UIImage]()
    
    var image: UIImage?
    
    //MARK: VIEWDIDLOAD
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        print("LAT: \(selectedPin.latitude)")
        print("LONG: \(selectedPin.longitude)")
        pin()
        setupFetchedResultsController()
        downloadPhotos()
    }
    
    //MARK: VIEWWILLAPPEAR
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    
    //MARK: GEOCODE LOCATION
    
    func pin() {
        activityIndicator.startAnimating()
        
        let coordinate = CLLocationCoordinate2D(latitude: selectedPin.latitude, longitude: selectedPin.longitude)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        DispatchQueue.main.async {
            self.mapView.addAnnotation(annotation)
            self.mapView.setRegion(region, animated: true)
            self.mapView.regionThatFits(region)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
        }
    }
    
    func downloadPhotos() {
        FlickrClient.searchPhotos(lat: selectedPin!.latitude, lon: selectedPin!.longitude, totalPageAmt: 3) { (result, error) in
            
            DispatchQueue.main.async {
                self.photoImages = result
                self.savePhotosToLocalStorage(photosArray: self.photoImages)
                self.collectionView.reloadData()
            }
        }
    }
    
    func savePhotosToLocalStorage(photosArray:[UIImage]){
        for photo in photosArray{
            addPhotosForPin(photo: photo)
        }
    }
    
    func addPhotosForPin(photo:UIImage){
        let photos = Photo(context: dataController.viewContext)
        let imageData : Data = photo.pngData()!
        photos.photo = imageData
        photos.pin = selectedPin
        try? dataController.viewContext.save()
    }
    
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", selectedPin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "photo", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(selectedPin)-photos")
        //        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
}

//MARK: FIX

extension AlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionCell  = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? PhotoViewCell
        if (photoImages.count > 0){
            DispatchQueue.main.async {
                collectionCell?.photoImageView.image = self.photoImages[indexPath.row]
            }
        } else {
            DispatchQueue.main.async {
                collectionCell?.photoImageView.image = UIImage(named: "")  //FIX
            }
        }
        
        return collectionCell!
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(photoImages.count == 0){
            return 21
        } else {
            return photoImages.count
        }
    }
    
    
}

extension AlbumViewController: MKMapViewDelegate {
    //MARK: MAKE PIN
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView?.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}


