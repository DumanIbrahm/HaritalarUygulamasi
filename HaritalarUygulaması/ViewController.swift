//
//  ViewController.swift
//  HaritalarUygulaması
//
//  Created by İbrahim Duman on 11.03.2023.
//

import UIKit
import CoreData

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource{

    @IBOutlet weak var tableView: UITableView!
    var nameArray = [String]()
    var idArray = [UUID]()
    var chosenPlaceName = ""
    var chosenPlaceID : UUID?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(clickedButton))
        
        takeData()
    }
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(takeData), name: NSNotification.Name("newPlaceCreated"), object: nil)
    }
    @objc func clickedButton(){
        chosenPlaceName = ""
        performSegue(withIdentifier: "toMapsVC", sender: nil)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = nameArray[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            nameArray.count
    }
    
   @objc func takeData(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName:"Yer")
        request.returnsObjectsAsFaults = false
        
        do{
            let sonuclar = try context.fetch(request)
            if(sonuclar.count>0){
                for sonuc in sonuclar as! [NSManagedObject]{
                    if let isim = sonuc.value(forKey: "isim") as? String{
                        nameArray.append(isim)
                    }
                    if let id = sonuc.value(forKey: "id") as? UUID{
                        idArray.append(id)
                    }
                }
                tableView.reloadData()
            }
        }catch{
            print("hata")
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenPlaceName = nameArray[indexPath.row]
        chosenPlaceID = idArray[indexPath.row]
        performSegue(withIdentifier: "toMapsVC", sender: nil)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapsVC"{
            let destinationVC = segue.destination as! MapViewController
            destinationVC.chosenName = chosenPlaceName
            destinationVC.chosenID = chosenPlaceID
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let title = "Sil"
        let deleteAction = UIContextualAction(style: .normal, title: title) { action, view, completion in
            self.removeItem(listItem: self.idArray[indexPath.row])
            self.nameArray.remove(at: indexPath.row)
            tableView.reloadData()
            completion(true)
        }
        deleteAction.backgroundColor = .red
        
        let config = UISwipeActionsConfiguration(actions: [deleteAction])
        return config
    }
    
    func removeItem(listItem: UUID){
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Yer")
        fetchRequest.predicate = NSPredicate(format: "id = %@", listItem.uuidString)
            fetchRequest.returnsObjectsAsFaults = false
            
            if let result = try? managedContext.fetch(fetchRequest){
                for item in result {
                    managedContext.delete(item)
                    
                }
                do{
                    try managedContext.save()
                }catch {
                    print("hata")
                }
            }
        }
    
}
