//
//  ACEDetailViewController.h
//  ACECoreDataManagerDemo
//
//  Created by Stefano Acerbetti on 4/9/14.
//  Copyright (c) 2014 Aceland. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACEDetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
