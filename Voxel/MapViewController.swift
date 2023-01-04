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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension MapViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 29
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
