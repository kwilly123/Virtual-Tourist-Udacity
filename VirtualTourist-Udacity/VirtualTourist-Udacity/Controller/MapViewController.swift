//
//  MapViewController.swift
//  VirtualTourist-Udacity
//
//  Created by Kyle Wilson on 2020-03-17.
//  Copyright © 2020 Xcode Tips. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    var dataController: DataController!
    
    //MARK: VIEWDIDLOAD
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        view.addGestureRecognizer(longTapGesture)
        
        setupFetchedResultsController()
        drawPinsOnMap()
    }
    
    //MARK: VIEWWILLAPPEAR
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    //MARK: VIEWWILLDISAPPEAR
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }
    
    //MARK: LONG TAP GESTURE
    
    @objc func longTap(sender: UIGestureRecognizer) {
        if sender.state == .ended {
            let location = sender.location(in: self.mapView)
            let locCoords = self.mapView.convert(location, toCoordinateFrom: self.mapView)
            
            let lat : Double = locCoords.latitude
            let lng : Double = locCoords.longitude
            
            
            let pin = Pin(context: dataController.viewContext)
            pin.latitude = lat
            pin.longitude = lng
            try? dataController.viewContext.save()
            
            let latitude = CLLocationDegrees(lat)
            let longitude = CLLocationDegrees(lng)
            
            let coordinate = CLLocationCoordinate2D(latitude: latitude , longitude: longitude)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            self.mapView.addAnnotation(annotation)
            
        }
    }
    
    func drawPinsOnMap(){
        
        var savedPins : [MKAnnotation] = []
        for pin in fetchedResultsController.fetchedObjects!{
            
            let latitude = CLLocationDegrees(pin.latitude)
            let longitude = CLLocationDegrees(pin.longitude)
            
            let coordinate = CLLocationCoordinate2D(latitude: latitude , longitude: longitude)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            savedPins.append(annotation)
            
        }
        mapView.addAnnotations(savedPins)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is AlbumViewController {
            let vc = segue.destination as? AlbumViewController
            vc?.dataController = dataController
            vc?.selectedPin = sender as? Pin
        }
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pin")
//        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
}

extension MapViewController: MKMapViewDelegate {
    
    //MARK: MAKE PIN
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    //MARK: TAPPED ANNOTATION VIEW
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = (view.annotation?.coordinate.latitude)!
        pin.longitude = (view.annotation?.coordinate.longitude)!
        
        performSegue(withIdentifier: "segue", sender: pin)
        
        dataController.viewContext.delete(pin)
        try? dataController.viewContext.save()
        mapView.removeAnnotation(view.annotation!)
    }
}
