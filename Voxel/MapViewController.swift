//
//  MapViewController.swift
//  Voxel
//
//  Created by Andy Qua on 04/01/2023.
//  Copyright © 2023 Andy Qua. All rights reserved.
//

import UIKit

class MapViewController: UIViewController {

    @IBOutlet weak var collectionView : UICollectionView!
    var selectedMapNr : Int = 0
    var nrMaps = 29
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIImage(named:"C1" ) == nil {
            nrMaps = 0
            
            let lbl = UILabel(frame:.zero)
            lbl.textAlignment = .center
            lbl.numberOfLines = 0
            lbl.text = "No map images found!\nDid you run the getImages.sh script from the tools folder?\n\nPlease see the README.md file for more information."
            view.addSubview(lbl)
            
            lbl.translatesAutoresizingMaskIntoConstraints = false
            lbl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            lbl.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        }
    }
}

extension MapViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return nrMaps
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageViewCell
        
        cell.imageView.image = UIImage(named: "C\(indexPath.row+1)")
        cell.imageView.layer.shadowOffset = CGSize( width:5,height:5 )
        cell.imageView.layer.shadowColor = UIColor.black.cgColor
        cell.imageView.layer.shadowRadius = 1.0
        cell.imageView.layer.shadowOpacity = 0.15
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let vc = segue.destination as? VoxelViewController {
            vc.depthImage = UIImage(named: "D\(selectedMapNr)")
            vc.mapImage = UIImage(named: "C\(selectedMapNr)")
        }
    }

}


extension MapViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedMapNr = indexPath.row+1

        self.performSegue(withIdentifier: "showTerrain", sender: self)
    }
}
