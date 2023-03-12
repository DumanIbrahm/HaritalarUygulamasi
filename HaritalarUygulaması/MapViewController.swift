//
//  ViewController.swift
//  HaritalarUygulaması
//
//  Created by İbrahim Duman on 11.03.2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate {
    
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var choosenLatitude = Double()
    var choosenLongtitude = Double()
    var chosenName = ""
    var chosenID : UUID?
    var locationManager = CLLocationManager()
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongtitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if chosenName != "" {
            if let uuidString = chosenID?.uuidString{
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do{
                    let sonuclar = try context.fetch(fetchRequest)
                    if sonuclar.count > 0 {
                        for sonuc in sonuclar as! [NSManagedObject]{
                            if let isim = sonuc.value(forKey: "isim") as? String{
                                annotationTitle = isim
                                if let not = sonuc.value(forKey: "not") as? String{
                                    annotationSubtitle = not
                                    if let latitude = sonuc.value(forKey: "latitude") as? Double{
                                        annotationLatitude = latitude
                                        if let longtitude = sonuc.value(forKey: "longtitude") as? Double{
                                            annotationLongtitude = longtitude
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubtitle
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongtitude)
                                            annotation.coordinate = coordinate
                                            
                                            mapView.addAnnotation(annotation)
                                            titleTextField.text = annotationTitle
                                            descriptionTextField.text = annotationSubtitle
                                            
                                            locationManager.stopUpdatingLocation()
                                            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapView.setRegion(region, animated: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }catch{
                    print("hata")
                }
            }
        }else{
            
        }
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            return nil
        }
        let reuseID = "annatotion"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID)
        if pinView == nil{
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = true
            pinView?.tintColor = .red
            
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        }else{
            pinView?.annotation = annotation
        }
            return pinView
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if chosenName != "" {
            var requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongtitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarkArray, error) in
                if let placeMarks = placemarkArray{
                    if placeMarks.count > 0 {
                        let newPlaceMark = MKPlacemark(placemark: placeMarks[0])
                        let item = MKMapItem(placemark: newPlaceMark)
                        item.name = self.annotationTitle
                        let launcOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launcOptions)
                    }
                }
            }
        }
    }
    @objc func chooseLocation(gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began{
            let touchPoint = gestureRecognizer.location(in: mapView)
            let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            choosenLatitude = touchCoordinate.latitude
            choosenLongtitude = touchCoordinate.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchCoordinate
            annotation.title = titleTextField.text
            annotation.subtitle = descriptionTextField.text
            mapView.addAnnotation(annotation)
            
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if chosenName == ""{
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }else{
            
        }
        
    }
    
    
    @IBAction func SaveButton(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Yer", into: context)
        newPlace.setValue(titleTextField.text, forKey: "isim")
        newPlace.setValue(descriptionTextField.text, forKey: "not")
        newPlace.setValue(choosenLatitude, forKey: "latitude")
        newPlace.setValue(choosenLongtitude, forKey: "longtitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("kaydedildi")
        }catch{
            print("hata")
        }
        NotificationCenter.default.post(name: NSNotification.Name("newPlaceCreated"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    
}

