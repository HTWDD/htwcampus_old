//
//  notenDetailViewController.m
//  HTWcampus
//
//  Created by Konstantin Werner on 19.03.14.
//  Copyright (c) 2014 Konstantin. All rights reserved.
//

#import "notenDetailViewController.h"
#import "UIColor+HTW.h"

@interface notenDetailViewController ()

@end

@implementation notenDetailViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.fach[@"name"];
    self.tableView.backgroundColor = [UIColor HTWBackgroundColor];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 7;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = @"fachDetailZelle";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    NSString *text;
    NSString *detailedText;
    
    switch (indexPath.row) {
        case 0:
            text = @"Fach";
            detailedText = [self.fach objectForKey:@"name"];
            break;
        case 1:
            text = @"Note";
            detailedText = [self.fach objectForKey:@"note"];
            break;
        case 2:
            text = @"Status";
            detailedText = [self.fach objectForKey:@"status"];
            break;
        case 3:
            text = @"Credits";
            detailedText = [self.fach objectForKey:@"credits"];
            break;
        case 4:
            text = @"Versuch";
            detailedText = [self.fach objectForKey:@"versuch"];
            break;
        case 5:
            text = @"Semester";
            detailedText = [self.fach objectForKey:@"semester"];
            break;
        case 6:
            text = @"Prüfungsnummer";
            detailedText = [self.fach objectForKey:@"nr"];
            break;
            
        default:
            break;
    }
    cell.textLabel.text = text;
    cell.textLabel.textColor = [UIColor HTWDarkGrayColor];
    cell.detailTextLabel.text = detailedText;
    cell.detailTextLabel.textColor = [UIColor HTWBlueColor];
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    return cell;
}

@end
