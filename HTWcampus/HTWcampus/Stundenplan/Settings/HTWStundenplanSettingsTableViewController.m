//
//  HTWStundenplanSettingsTableViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 02.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWStundenplanSettingsTableViewController.h"
#import "HTWStundenplanSettingsUebersichtTableViewController.h"
#import "HTWAppDelegate.h"
#import "User.h"
#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

@interface HTWStundenplanSettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UITableViewCell *matrikelnummernCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *uebersichtCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *markierungsCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *tageInPortraitCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *tageInLandscapeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *parallaxCell;
@property (weak, nonatomic) IBOutlet UISlider *markierSlider;
@property (weak, nonatomic) IBOutlet UISlider *tageInPortraitSlider;
@property (weak, nonatomic) IBOutlet UISlider *tageInLandscapeSlider;
@property (weak, nonatomic) IBOutlet UILabel *portraitTageSliderWert;
@property (weak, nonatomic) IBOutlet UILabel *landscapeTageSliderWert;
@property (weak, nonatomic) IBOutlet UILabel *tageInPortraitLabel;
@property (weak, nonatomic) IBOutlet UILabel *parallaxLabel;
@property (weak, nonatomic) IBOutlet UISwitch *parallaxSwitch;

@end

@implementation HTWStundenplanSettingsTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Einstellungen";
    
    UIBarButtonItem *fertigButton = [[UIBarButtonItem alloc] initWithTitle:@"Fertig" style:UIBarButtonItemStylePlain target:self action:@selector(fertigPressed:)];
    self.navigationItem.rightBarButtonItem = fertigButton;
}

-(IBAction)fertigPressed:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    HTWAppDelegate *appdelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appdelegate managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"matrnr" ascending:YES]]];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(matrnr == %@)", [defaults objectForKey:@"Matrikelnummer"]]];
    
    NSArray *nummern = [context executeFetchRequest:fetchRequest error:nil];
    
    User *this;
    if(nummern.count >= 1) this = nummern[0];
    if(this.name) _matrikelnummernCell.detailTextLabel.text = this.name;
    else _matrikelnummernCell.detailTextLabel.text = this.matrnr;
    
    
    _markierSlider.value = [defaults floatForKey:@"markierSliderValue"];
    _tageInPortraitSlider.value = (float)[defaults integerForKey:@"tageInPortrait"];
    _tageInLandscapeSlider.value = (float)[defaults integerForKey:@"anzahlTageLandscape"];
    _portraitTageSliderWert.text = [NSString stringWithFormat:@"%.0f min Markierung vor Beginn der Stunde", _markierSlider.value];
    _tageInPortraitLabel.text = [NSString stringWithFormat:@"%.0f Tage im Portrait", _tageInPortraitSlider.value];
    _landscapeTageSliderWert.text = [NSString stringWithFormat:@"%.0f Tage im Landscape", _tageInLandscapeSlider.value];
    
    self.navigationController.navigationBarHidden = NO;
    
    self.tableView.backgroundColor = [UIColor HTWBackgroundColor];
    
    _matrikelnummernCell.backgroundColor = [UIColor HTWWhiteColor];
    _matrikelnummernCell.textLabel.textColor = [UIColor HTWDarkGrayColor];
    _matrikelnummernCell.textLabel.font = [UIFont HTWBaseFont];
    _matrikelnummernCell.detailTextLabel.textColor = [UIColor HTWBlueColor];
    _matrikelnummernCell.detailTextLabel.font = [UIFont HTWBaseFont];
    
    _uebersichtCell.backgroundColor = [UIColor HTWWhiteColor];
    _uebersichtCell.textLabel.textColor = [UIColor HTWDarkGrayColor];
    _uebersichtCell.textLabel.font = [UIFont HTWBaseFont];
    
    _parallaxCell.backgroundColor = [UIColor HTWWhiteColor];
    
    _parallaxLabel.font = [UIFont HTWBaseFont];
    _parallaxLabel.textColor = [UIColor HTWDarkGrayColor];
    _parallaxLabel.numberOfLines = 2;
    _parallaxLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _parallaxSwitch.thumbTintColor = [UIColor HTWWhiteColor];
    _parallaxSwitch.onTintColor = [UIColor HTWBlueColor];
    
    [_parallaxSwitch setOn:[defaults boolForKey:@"parallax"]];
    
    _markierungsCell.backgroundColor = [UIColor HTWWhiteColor];
    _portraitTageSliderWert.textColor = [UIColor HTWDarkGrayColor];
    _portraitTageSliderWert.font = [UIFont HTWBaseFont];
    _portraitTageSliderWert.numberOfLines = 2;
    _portraitTageSliderWert.lineBreakMode = NSLineBreakByWordWrapping;
    
    _tageInLandscapeCell.backgroundColor = [UIColor HTWWhiteColor];
    _landscapeTageSliderWert.textColor = [UIColor HTWDarkGrayColor];
    _landscapeTageSliderWert.font = [UIFont HTWBaseFont];
    _landscapeTageSliderWert.numberOfLines = 2;
    _landscapeTageSliderWert.lineBreakMode = NSLineBreakByWordWrapping;
    
    _tageInPortraitSlider.backgroundColor = [UIColor HTWWhiteColor];
    _tageInPortraitLabel.textColor = [UIColor HTWDarkGrayColor];
    _tageInPortraitLabel.font = [UIFont HTWBaseFont];
    _tageInPortraitLabel.numberOfLines = 2;
    _tageInPortraitLabel.lineBreakMode = NSLineBreakByWordWrapping;
}

#pragma mark - IBActions

- (IBAction)sliderValueChanged:(UISlider *)sender {
    if (sender.tag == 0) {
        [_markierSlider setValue:(int)(sender.value/5)*5];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setFloat:_markierSlider.value forKey:@"markierSliderValue"];
        _portraitTageSliderWert.text = [NSString stringWithFormat:@"%.0f min Markierung vor Beginn der Stunde", _markierSlider.value];
    }
}
- (IBAction)tageInPortraitSliderChangedValue:(UISlider *)sender {
    if (sender.tag == 1) {
        [_tageInPortraitSlider setValue:(int)sender.value];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setInteger:(int)_tageInPortraitSlider.value forKey:@"tageInPortrait"];
        _tageInPortraitLabel.text = [NSString stringWithFormat:@"%.0f Tage im Portrait", _tageInPortraitSlider.value];
    }
}
- (IBAction)tageInLandscapeChangedValue:(UISlider *)sender {
    if (sender.tag == 2) {
        [_tageInLandscapeSlider setValue:(int)(sender.value/5)*5];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setInteger:(int)_tageInLandscapeSlider.value forKey:@"anzahlTageLandscape"];
        _landscapeTageSliderWert.text = [NSString stringWithFormat:@"%.0f Tage im Landscape", _tageInLandscapeSlider.value];
    }
}
- (IBAction)parallaxSwitchChanged:(id)sender {
    UISwitch *switchS = (UISwitch*)sender;
    [[NSUserDefaults standardUserDefaults] setBool:switchS.isOn forKey:@"parallax"];
}

#pragma mark - Hilfsfunktionen

-(NSString*)getNameOf:(NSString*)matrnr
{
    NSManagedObjectContext *context = [HTWAppDelegate alloc].managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:context];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"matrnr = %@", matrnr];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    [request setPredicate:pred];
    
    return [(User*)[context executeFetchRequest:request error:nil][0] name];
}

@end
