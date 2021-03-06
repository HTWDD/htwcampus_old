//
//  HTWLandscapeViewController.m
//  HTW-App
//
//  Created by Benjamin Herzog on 15.12.13.
//  Copyright (c) 2013 Benjamin Herzog. All rights reserved.
//

#import "HTWLandscapeViewController.h"
#import "HTWAppDelegate.h"
#import "HTWStundenplanButtonForLesson.h"
#import "Stunde.h"
#import "User.h"
#import "HTWPortraitViewController.h"

#import "UIColor+HTW.h"
#import "UIFont+HTW.h"
#import "NSDate+HTW.h"

#define PixelPerMin 0.35
#define DEPTH_FOR_PARALLAX 8

@interface HTWLandscapeViewController () <UIScrollViewDelegate>
{
    HTWAppDelegate *appdelegate;
    BOOL isPortait;
    long ANZAHLTAGE;
}
@property (strong, nonatomic) IBOutlet UIView *zeitenView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong) UIView *detailView;
@property (nonatomic, strong) NSArray *angezeigteStunden;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation HTWLandscapeViewController

@synthesize Matrnr;

#pragma mark - Lazy Getter

-(NSDate *)currentDate
{
    if(!_currentDate) self.currentDate = [NSDate date];
    return _currentDate;
}

#pragma mark - Support methods for Orientation and Swipe

- (void)orientationChanged:(NSNotification *)notification
{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsPortrait(deviceOrientation) && !isPortait && (deviceOrientation != UIDeviceOrientationPortraitUpsideDown))
    {
        if(_raum) [self.navigationController popViewControllerAnimated:NO];
        else [self.navigationController popToRootViewControllerAnimated:NO];
        isPortait = YES;
    }
    else if ((UIDeviceOrientationIsLandscape(deviceOrientation) && isPortait) && UIDeviceOrientationIsValidInterfaceOrientation(deviceOrientation))
    {
        [self dismissViewControllerAnimated:YES completion:nil];
        isPortait = NO;
    }
}

#pragma mark - View Controller Lifecycle

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    ANZAHLTAGE = [[NSUserDefaults standardUserDefaults] integerForKey:@"anzahlTageLandscape"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterInForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterBackground)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    isPortait = NO;
    int degrees;
    if([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft) degrees = 90;
    else if([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight) degrees = 270;
    [UIView animateWithDuration:0.2 animations:^{
        self.view.transform = CGAffineTransformMakeRotation(degrees * M_PI / 180);
    }];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.scrollView setContentOffset:CGPointMake([self getScrollX], 0) animated:YES];
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}


-(void)applicationWillEnterInForeground
{
    [self viewWillAppear:YES];
}

-(void)applicationWillEnterBackground
{
    if(_raum) [self.navigationController popViewControllerAnimated:NO];
    else [self.navigationController popToRootViewControllerAnimated:NO];
    isPortait = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (!UIDeviceOrientationIsLandscape(deviceOrientation) && (deviceOrientation != UIDeviceOrientationPortraitUpsideDown))
    {
        if(_raum) [self.navigationController popViewControllerAnimated:NO];
        else [self.navigationController popToRootViewControllerAnimated:NO];
        isPortait = YES;
    }
    
    self.navigationController.navigationBarHidden = YES;
//    self.scrollView.contentSize = CGSizeMake(508*(ANZAHLTAGE/5)+68*(ANZAHLTAGE/5-1), 320);
    self.scrollView.contentSize = CGSizeMake(103*ANZAHLTAGE+68*(ANZAHLTAGE/5-1), 320);
    _scrollView.delegate = self;
    
    
    _detailView = [[UIView alloc] init];
    _detailView.hidden = YES;
    _detailView.tag = 1;
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:_detailView depth:DEPTH_FOR_PARALLAX];
    [_scrollView addSubview:_detailView];
    
    self.scrollView.backgroundColor = [UIColor HTWSandColor];
    self.zeitenView.backgroundColor = [UIColor HTWDarkGrayColor];
    
    appdelegate = [[UIApplication sharedApplication] delegate];
    _context = [appdelegate managedObjectContext];
    
    
    int weekday = [self.currentDate getWeekDay];
    
    NSDate *letzterMontag = [self.currentDate.getDayOnly dateByAddingTimeInterval:-60*60*24*weekday ];
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = ANZAHLTAGE+(ANZAHLTAGE/5*2);
    
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    
    NSDate *theLastShownDate = [theCalendar dateByAddingComponents:dayComponent toDate:letzterMontag options:0];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Stunde" inManagedObjectContext:_context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = entityDesc;
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"student.matrnr = %@ && anfang > %@ && ende < %@", Matrnr, letzterMontag, theLastShownDate];
    request.predicate = pred;
    
    _angezeigteStunden = [_context executeFetchRequest:request error:nil];
    
    
    [self setUpInterface];
    
    
    
    
}

-(void)dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(orientationChanged:)
               name:UIDeviceOrientationDidChangeNotification
             object:nil];
    [nc removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    isPortait = YES;
}

#pragma mark - UIScrollView Delegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    for (UIView *this in _scrollView.subviews) {
        if (this.tag == 1)
            this.hidden = YES;
    }
}



#pragma mark - Interface

-(void)setUpInterface
{
    [self loadLabels];
    NSDate *today = [NSDate date].getDayOnly;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    for (Stunde *aktuell in self.angezeigteStunden) {
        if(!aktuell.anzeigen.boolValue) continue;
        HTWStundenplanButtonForLesson *button = [[HTWStundenplanButtonForLesson alloc] initWithLesson:aktuell andPortait:NO andCurrentDate:self.currentDate];
        button.tag = -1;
        
        UILongPressGestureRecognizer *longPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(buttonIsPressed:)];
        longPressGR.minimumPressDuration = 0.1;
        [button addGestureRecognizer:longPressGR];
        
        if ([[NSDate date] compare:[button.lesson.anfang dateByAddingTimeInterval:-[defaults floatForKey:@"markierSliderValue"]*60]] == NSOrderedDescending &&
            [[NSDate date] compare:button.lesson.ende] == NSOrderedAscending) {
            [button setNow:YES];
        }
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:button depth:DEPTH_FOR_PARALLAX];
        
        UIView *shadow = [[UIView alloc] initWithFrame:button.frame];
        shadow.layer.cornerRadius = button.layer.cornerRadius;
        shadow.backgroundColor = [UIColor HTWGrayColor];
        shadow.alpha = 0.3;
        shadow.tag = -1;
        [self.scrollView addSubview:shadow];
        [self.scrollView addSubview:button];
    }
    
    if ([[NSDate date] compare:[today dateByAddingTimeInterval:7*60*60+30*60]] == NSOrderedDescending &&
        [[NSDate date] compare:[today dateByAddingTimeInterval:20*60*60]] == NSOrderedAscending)
    {
        UIColor *linieUndClock = [UIColor colorWithRed:255/255.f green:72/255.f blue:68/255.f alpha:1];
        
        CGFloat y = 55 + [[NSDate date] timeIntervalSinceDate:[today dateByAddingTimeInterval:7*60*60+30*60]] / 60 * PixelPerMin;
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(-350, y, self.scrollView.contentSize.width+350-10, 1)];
        lineView.backgroundColor = linieUndClock;
        lineView.alpha = 0.6;
        lineView.tag = -1;
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:lineView depth:DEPTH_FOR_PARALLAX];
        [self.scrollView addSubview:lineView];
    }
    
    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    [tapRecognizer setNumberOfTapsRequired:2];
    [self.scrollView addGestureRecognizer:tapRecognizer];
}

-(void)loadLabels
{
    CGFloat yWertTage = 13;
    NSArray *stringsTage = [NSArray arrayWithObjects:@"Montag", @"Dienstag", @"Mittwoch", @"Donnerstag", @"Freitag", nil];
    
    UIView *heuteMorgenLabelsView = [[UIView alloc] initWithFrame:CGRectMake(-350, 0, _scrollView.contentSize.width+350+350, 36)];
    
    UIImage *indicator = [UIImage imageNamed:@"indicator-gray@2x.png"];
    UIImageView *indicatorView = [[UIImageView alloc] initWithImage:indicator];
    indicatorView.frame = CGRectMake([self getScrollX]+350, 15+18, 90, 7);
    [heuteMorgenLabelsView addSubview:indicatorView];
    
    
    
    heuteMorgenLabelsView.backgroundColor = [UIColor HTWDarkGrayColor];
    heuteMorgenLabelsView.tag = -1;

    NSDate *cDate = [self.currentDate.getDayOnly dateByAddingTimeInterval:(-60*60*24*[self.currentDate getWeekDay]) ];
    CGFloat x = 1;
    for (int i = 0; i < ANZAHLTAGE; i++) {
        int j = i;
        if (i > (ANZAHLTAGE%5)+4) j = (i%5);
        
        if(i != 0) x += 103;
        if(j == 0 && i != 0) x += 61;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x+350, yWertTage, 90, 21)];
        label.text = [stringsTage objectAtIndex:j];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor HTWGrayColor];
        label.font = [UIFont HTWBaseFont];
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:label depth:DEPTH_FOR_PARALLAX];
        
        UILabel *thisDate = [[UILabel alloc] initWithFrame:CGRectMake(label.frame.origin.x+label.frame.size.width/4, label.frame.origin.y-10, label.frame.size.width/2, 15)];
        thisDate.textAlignment = NSTextAlignmentCenter;
        thisDate.font = [UIFont HTWVerySmallFont];
        thisDate.tag = -1;
        thisDate.textColor = [UIColor HTWGrayColor];
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:thisDate depth:DEPTH_FOR_PARALLAX];
        thisDate.text = [cDate getAsStringWithFormat:@"dd.MM."];
        
        if(j == [NSDate getWeekDay])
            label.textColor = thisDate.textColor = [UIColor HTWWhiteColor];
        
        
        [heuteMorgenLabelsView addSubview:thisDate];
        [heuteMorgenLabelsView addSubview:label];
        
        cDate = [cDate addDays:1 months:0 years:0];
//        cDate = [cDate dateByAddingTimeInterval:60*60*24];
        if([cDate getWeekDay] == 5)
        {
            cDate = [cDate addDays:2 months:0 years:0];
//            cDate = [cDate dateByAddingTimeInterval:60*60*24*2];
        }
    }
    [_scrollView addSubview:heuteMorgenLabelsView];
    
    NSDate *today = self.currentDate.getDayOnly;
    
    NSArray *vonStrings = @[@"07:30", @"09:20", @"11:10", @"13:10", @"15:00", @"16:50", @"18:30"];
    NSArray *bisStrings = @[@"09:00", @"10:50", @"12:40", @"14:40", @"16:30", @"18:20", @"20:00"];
    NSArray *stundenZeiten = @[[today dateByAddingTimeInterval:60*60*7+60*30],
                               [today dateByAddingTimeInterval:60*60*9+60*20],
                               [today dateByAddingTimeInterval:60*60*11+60*10],
                               [today dateByAddingTimeInterval:60*60*13+60*10],
                               [today dateByAddingTimeInterval:60*60*15+60*00],
                               [today dateByAddingTimeInterval:60*60*16+60*50],
                               [today dateByAddingTimeInterval:60*60*18+60*30] ];
    
    for (int i = 0; i < stundenZeiten.count; i++) {
        CGFloat y = 45 + [(NSDate*)[stundenZeiten objectAtIndex:i] timeIntervalSinceDate:[today dateByAddingTimeInterval:7*60*60+30*60]] / 60 * PixelPerMin ;
        UIView *vonBisLabel = [[UIView alloc] initWithFrame:CGRectMake(5, y, 30, 90 * PixelPerMin)];
        UILabel *von = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, vonBisLabel.frame.size.width, vonBisLabel.frame.size.height/2)];
        von.text = vonStrings[i];
        von.font = [UIFont HTWVerySmallFont];
        von.textColor = [UIColor HTWWhiteColor];
        [vonBisLabel addSubview:von];
        UILabel *bis = [[UILabel alloc] initWithFrame:CGRectMake(0, vonBisLabel.frame.size.height/2, vonBisLabel.frame.size.width, vonBisLabel.frame.size.height/2)];
        bis.text = bisStrings[i];
        bis.font = [UIFont HTWVerySmallFont];
        bis.textColor = [UIColor HTWWhiteColor];
        [vonBisLabel addSubview:bis];
        
        UIView *strich = [[UIView alloc] initWithFrame:CGRectMake(vonBisLabel.frame.size.width*0.25, von.frame.size.height, vonBisLabel.frame.size.width/2, 1)];
        strich.backgroundColor = [UIColor HTWWhiteColor];
        [vonBisLabel addSubview:strich];
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:vonBisLabel depth:DEPTH_FOR_PARALLAX];
        
        [_zeitenView addSubview:vonBisLabel];
    }
}

#pragma mark - IBActions

-(IBAction)doubleTap:(id)sender
{
    [self.scrollView setContentOffset:CGPointMake([self getScrollX], 0) animated:YES];
}



-(CGFloat)getScrollX
{
    int weekday = (int)[[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:self.currentDate] weekday] - 2;
    if(weekday == -1) weekday=6;
    NSDate *today = self.currentDate.getDayOnly;
    
    NSDate *montag = [self.currentDate.getDayOnly dateByAddingTimeInterval:(-60*60*24*weekday) ];
    NSDate *dienstag = [montag dateByAddingTimeInterval:60*60*24];
    NSDate *mittwoch = [dienstag dateByAddingTimeInterval:60*60*24];
    NSDate *donnerstag = [mittwoch dateByAddingTimeInterval:60*60*24];
    NSDate *freitag = [donnerstag dateByAddingTimeInterval:60*60*24];
    NSDate *montag2 = [self.currentDate.getDayOnly dateByAddingTimeInterval:((-60*60*24*weekday)+60*60*24*7) ];
    NSDate *dienstag2 = [montag2 dateByAddingTimeInterval:60*60*24];
    NSDate *mittwoch2 = [dienstag2 dateByAddingTimeInterval:60*60*24];
    NSDate *donnerstag2 = [mittwoch2 dateByAddingTimeInterval:60*60*24];
    NSDate *freitag2 = [donnerstag2 dateByAddingTimeInterval:60*60*24];
    
    if ([today isEqualToDate:montag]) return 0;
    else if ([today isEqualToDate:dienstag]) return 103;
    else if ([today isEqualToDate:mittwoch]) return 206;
    else if ([today isEqualToDate:donnerstag]) return 309;
    else if ([today isEqualToDate:freitag]) return 412;
    else if ([today isEqualToDate:montag2]) return 576;
    else if ([today isEqualToDate:dienstag2]) return 679;
    else if ([today isEqualToDate:mittwoch2]) return 782;
    else if ([today isEqualToDate:donnerstag2]) return 885;
    else if ([today isEqualToDate:freitag2]) return 988;
    else return 576;
}


-(IBAction)buttonIsPressed:(UILongPressGestureRecognizer*)gesture
{
    HTWStundenplanButtonForLesson *buttonPressed = (HTWStundenplanButtonForLesson*)gesture.view;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        buttonPressed.backgroundColor = [UIColor HTWBlueColor];
        for (UIView *this in buttonPressed.subviews) {
            if([this isKindOfClass:[UILabel class]]) [(UILabel*)this setTextColor:[UIColor HTWWhiteColor]];
            else if (this.tag == -9) this.backgroundColor = [UIColor HTWWhiteColor];
        }
        
        CGFloat x = buttonPressed.frame.origin.x-buttonPressed.frame.size.width/2;
        CGFloat y = buttonPressed.frame.origin.y-220*PixelPerMin;
        CGFloat width = buttonPressed.frame.size.width*2;
        CGFloat height = 220*PixelPerMin;
        
        if (x + width > _scrollView.contentOffset.x + [UIScreen mainScreen].bounds.size.height - _zeitenView.frame.size.width)
            x -= ((x + width) - ([UIScreen mainScreen].bounds.size.height - _zeitenView.frame.size.width + _scrollView.contentOffset.x));
        else if (x < _scrollView.contentOffset.x) x = _scrollView.contentOffset.x;
        if (y < 0) {
            y = buttonPressed.frame.origin.y + buttonPressed.frame.size.height;
        }
        
        _detailView.frame = CGRectMake(x, y, width,height);
        _detailView.layer.cornerRadius = 10;
        _detailView.backgroundColor = [UIColor HTWBlueColor];
        _detailView.alpha = 0.9;
        
        for (UIView *this in _detailView.subviews) {
            [this removeFromSuperview];
        }
        
        UILabel *titel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _detailView.frame.size.width, _detailView.frame.size.height*4/5)];
        titel.text = buttonPressed.lesson.titel;
        titel.textAlignment = NSTextAlignmentCenter;
        titel.font = [UIFont HTWSmallFont];
        titel.lineBreakMode = NSLineBreakByWordWrapping;
        titel.numberOfLines = 3;
        titel.textColor = [UIColor HTWWhiteColor];
        [_detailView addSubview:titel];
        
        UILabel *dozent = [[UILabel alloc] initWithFrame:CGRectMake(0, _detailView.frame.size.height*4/5-9, _detailView.frame.size.width, _detailView.frame.size.height*2/5)];
        if(buttonPressed.lesson.dozent) dozent.text = [NSString stringWithFormat:@"Dozent: %@", buttonPressed.lesson.dozent];
        dozent.textAlignment = NSTextAlignmentCenter;
        dozent.font = [UIFont HTWVerySmallFont];
        dozent.textColor = [UIColor HTWWhiteColor];
        [_detailView addSubview:dozent];
        
        
        [_scrollView bringSubviewToFront:_detailView];
        
        _detailView.hidden = NO;
    }
    else if (gesture.state == UIGestureRecognizerStateEnded){
        _detailView.hidden = YES;
        buttonPressed.backgroundColor = [UIColor HTWWhiteColor];
        for (UIView *this in buttonPressed.subviews) {
            if([this isKindOfClass:[UILabel class]]) [(UILabel*)this setTextColor:[UIColor HTWDarkGrayColor]];
            else if (this.tag == -9) this.backgroundColor = [UIColor HTWDarkGrayColor];
        }
    }
}

#pragma mark - Hilfsfunktionen

- (void)registerEffectForView:(UIView *)aView depth:(CGFloat)depth;
{
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) return;
	UIInterpolatingMotionEffect *effectX;
	UIInterpolatingMotionEffect *effectY;
    effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
	
	
	effectX.maximumRelativeValue = @(depth);
	effectX.minimumRelativeValue = @(-depth);
	effectY.maximumRelativeValue = @(depth);
	effectY.minimumRelativeValue = @(-depth);
	
	[aView addMotionEffect:effectX];
	[aView addMotionEffect:effectY];
}

@end
