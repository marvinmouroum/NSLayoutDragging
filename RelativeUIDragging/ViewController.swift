//
//  ViewController.swift
//  RelativeUIDragging
//
//  Created by Marvin Mouroum on 19.12.19.
//  Copyright © 2019 mouroum. All rights reserved.
//

import UIKit

struct BallPosition {
    
    //constants for the ball
    var height:NSLayoutConstraint?
    var width:NSLayoutConstraint?
    
    //dragging coordinates for ball
    var x:NSLayoutConstraint?
    var y:NSLayoutConstraint?
    
    //destination where the ball will bounce after contact
    var groundX:NSLayoutConstraint?
    var groundY:NSLayoutConstraint?
    
    //new start position
    var resetX:NSLayoutConstraint?
    var resetY:NSLayoutConstraint?
    
    //get started
    mutating func start(with view:UIView, in parent:UIView){
        
        self.height?.isActive = true
        self.width?.isActive = true
        
        //clean up
        resetAll()
        
        self.resetX = view.centerXAnchor.constraint(equalTo: parent.leadingAnchor, constant: 75)
        self.resetY = view.centerYAnchor.constraint(equalTo: parent.topAnchor, constant: parent.frame.height - 50)
        
        self.resetX?.isActive = true
        self.resetY?.isActive = true
    }
    
    //before changing the constraints, we need to clean up
    func resetAll(){
        x?.isActive = false
        y?.isActive = false
        groundX?.isActive = false
        groundY?.isActive = false
        resetX?.isActive = false
        resetY?.isActive = false
    }
    
    mutating func updatePosition(x:CGFloat,y:CGFloat,for view:UIView, in parent:UIView){
        //clean up
        resetAll()
        //update the position
        self.x = view.centerXAnchor.constraint(equalTo: parent.leadingAnchor, constant: x)
        self.y = view.centerYAnchor.constraint(equalTo: parent.topAnchor, constant: y)
        
        self.x?.isActive = true
        self.y?.isActive = true
        
    }
    
    mutating func freeFall(from point:CGPoint,for view:UIView, in parent:UIView){
        
        //clean up
        resetAll()
        
        self.groundX = view.centerXAnchor.constraint(equalTo: parent.leadingAnchor, constant: point.x)
        self.groundY = view.centerYAnchor.constraint(equalTo: parent.bottomAnchor, constant: -50)
        
        self.groundX?.isActive = true
        self.groundY?.isActive = true
    }
}

class ViewController: UIViewController {
    
    
    @IBOutlet weak var trashCan: UIImageView!
    
    
    lazy var ball:UIView = {
        return spawnBall()
    }()
    
    //the NSLayoutConstraints are stored in this structure
    var position = BallPosition()
    
    //spawn a new object
    func spawnBall()->UIView{
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        
        //select a random color to differentiate the objects
        view.backgroundColor = UIColor(
            displayP3Red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue:  .random(in: 0...1),
            alpha: 1)
        
        view.layer.borderWidth = 3
        view.layer.cornerRadius = 25
        let drag = UIPanGestureRecognizer(target: self, action: #selector(dragging))
        view.addGestureRecognizer(drag)
        return view
    }
    
    //put the object onto the view
    func placeBall(){
        position.height = ball.heightAnchor.constraint(equalToConstant: 50)
        position.width = ball.widthAnchor.constraint(equalToConstant: 50)
        
        self.view.insertSubview(ball, belowSubview: trashCan)
        position.start(with: ball, in: self.view)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        placeBall()
        
    }
    
    //the position of the ball before it was dragged
    var start:CGPoint = CGPoint()
    
    //the place where our logic is stored
    @objc func dragging(sender:UIPanGestureRecognizer){
        
        if sender.state == .began {
            print("begin dragging")
            //saving the initial position
            start = ball.center
        }
        
        //get the translation
        let current = sender.translation(in: self.view)
        
        //update the layout constraints
        position.updatePosition(x: start.x + current.x, y: start.y + current.y, for: ball, in: self.view)
        
        //display the result
        self.view.setNeedsDisplay()
        self.view.setNeedsLayout()
        
        //when the touch was released
        if sender.state == .ended {
            print("dragging ended")
            //let the ball drop - set position
            position.freeFall(from: ball.center, for: ball, in: self.view)
            //more or less realistic animation
            UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 1.1, initialSpringVelocity: 1.0, options: .curveEaseIn, animations: {
                //let the ball drop - visualize result in animation
                self.view.layoutIfNeeded()
                self.view.setNeedsDisplay()
            }) { (_) in
                //250ms time before it drops
                usleep(250)
                //check if the ball is inside the trash can
                if self.ball.frame.inside(frame: self.trashCan.frame){
                    self.ball.removeFromSuperview()
                    self.ball = self.spawnBall()
                    self.placeBall()
                }
                    // if the ball touched the can reset it
                else if self.ball.center.x > self.trashCan.center.x - self.trashCan.frame.width*0.75 &&
                self.ball.center.x < self.trashCan.center.x + self.trashCan.frame.width*0.75 {
                    //reset the position
                    self.position.start(with: self.ball, in: self.view)
                }
                
            }
        }
        
    }
    
    
}

extension CGRect {
    
    func inside(frame:CGRect)->Bool{
        
        if frame.origin.x * 1.05 < self.origin.x &&
            frame.origin.x + frame.size.width * 0.95 > self.origin.x
            && self.origin.x + self.size.width < frame.origin.x + frame.size.width * 0.95 {
            
            if frame.origin.y * 1.05 < self.origin.y &&
                self.origin.y + frame.size.height * 0.95 > self.origin.y
                && self.origin.y + self.size.height < frame.origin.y + frame.size.height * 0.95 {
                return true
            }
            
        }
        
        return false
        
    }
}

