//
//  StundenplanButtonForLesson.m
//  University
//
//  Created by Benjamin Herzog on 11.12.13.
//  Copyright (c) 2013 Benjamin Herzog. All rights reserved.
//

#import "HTWStundenplanButtonForLesson.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

#define CornerRadius 5
#define ANZAHLTAGE_LANDSCAPE 10

@interface HTWStundenplanButtonForLesson ()
{
    CGFloat height;
    CGFloat width;
    CGFloat x;
    CGFloat y;
    
    float PixelPerMin;
}

@property (nonatomic, strong) UILabel *kurzel;
@property (nonatomic, strong) UILabel *raum;
@property (nonatomic, strong) UILabel *typ;

@end

@implementation HTWStundenplanButtonForLesson

@synthesize lesson,kurzel,raum,typ;

#pragma mark - INIT

-(id)initWithLesson:(Stunde *)lessonForButton andPortait:(BOOL)portaitForButton
{
    self = [super init];
    
    [self setPortait:portaitForButton];
    [self setLesson:lessonForButton];
    return self;
}

#pragma mark - Setter

-(void)setPortait:(BOOL)portait
{
    if (portait) PixelPerMin = 0.5;
    else PixelPerMin = 0.35;
    _portait = portait;
}

-(void)setNow:(BOOL)now
{
    _now = now;
    
    if (lesson.anzeigen) {
        self.backgroundColor = [UIColor HTWBlueColor];
        kurzel.textColor = [UIColor HTWWhiteColor];
        raum.textColor = [UIColor HTWWhiteColor];
        typ.textColor = [UIColor HTWWhiteColor];
    }
}

-(void)setLesson:(Stunde *)lessonForButton
{
    lesson = lessonForButton;
    
    height = (CGFloat)[lesson.ende timeIntervalSinceDate:lesson.anfang] / 60 * PixelPerMin;
    if (_portait) width = 108;
    else width = 90;

    
    NSDateFormatter *nurTag = [[NSDateFormatter alloc] init];
    [nurTag setDateFormat:@"dd.MM.yyyy"];
    
    
    if(_portait){
        NSDate *today = [nurTag dateFromString:[nurTag stringFromDate:[NSDate date]]];
        
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        dayComponent.day = 1;
        
        NSCalendar *theCalendar = [NSCalendar currentCalendar];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSMutableArray *tage = [[NSMutableArray alloc] init];
        [tage addObject:today];
        for (int i = 1; i < [defaults integerForKey:@"tageInPortrait"]; i++) {
            [tage addObject:[theCalendar dateByAddingComponents:dayComponent toDate:tage[i-1] options:0]];
        }
        for (int i = 0; i < tage.count; i++) {
            if ([self isSameDayWithDate1:lesson.anfang date2:tage[i]]) {
                x = 60+i*116;
                y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[tage[i] dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
                break;
            }
        }
    }
    else {
        
        int weekday = [self weekdayFromDate:[NSDate date]];
        
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        dayComponent.day = 1;
        NSDateComponents *threeDaysComponent = [[NSDateComponents alloc] init];
        threeDaysComponent.day = 3;
        
        NSCalendar *theCalendar = [NSCalendar currentCalendar];
        
        NSDate *montag = [[nurTag dateFromString:[nurTag stringFromDate:[NSDate date]]] dateByAddingTimeInterval:(-60*60*24*weekday) ];
        
        NSMutableArray *tage = [[NSMutableArray alloc] init];
        [tage addObject:montag];
        
        int zaehler = 0;
        for (int i = 1; i < ANZAHLTAGE_LANDSCAPE; i++) {
            if(zaehler < 4) [tage addObject:[theCalendar dateByAddingComponents:dayComponent toDate:tage[i-1] options:0]];
            else [tage addObject:[theCalendar dateByAddingComponents:threeDaysComponent toDate:tage[i-1] options:0]];
            
            zaehler++;
            if (zaehler > 4) zaehler = 0;
        }
        for (int i = 0; i < tage.count; i++) {
            if ([self isSameDayWithDate1:lesson.anfang date2:tage[i]]) {
                x = 1+i*103;
                if(i > 4) x += 61;
                y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[tage[i] dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
                break;
            }
        }

    }
    self.frame = CGRectMake( x, y, width, height);
    
    self.backgroundColor = [UIColor HTWWhiteColor];
    self.layer.cornerRadius = CornerRadius;
    
    if (!kurzel) kurzel = [[UILabel alloc] init];
    if (!raum) raum = [[UILabel alloc] init];
    if (!typ) typ = [[UILabel alloc] init];
    
    kurzel.text = [lesson.kurzel componentsSeparatedByString:@" "][0];
    if(_portait) kurzel.font = [UIFont HTWLargeFont];
    else kurzel.font = [UIFont HTWBaseFont];
    kurzel.textAlignment = NSTextAlignmentLeft;
    kurzel.frame = CGRectMake(x+width*0.02f, y, width*0.98f, height*0.6);
    kurzel.textColor = [UIColor HTWDarkGrayColor];
    
    raum.text = lesson.raum;
    if(_portait) raum.font = [UIFont HTWVerySmallFont];
    else raum.font = [UIFont HTWSmallestFont];
    raum.textAlignment = NSTextAlignmentLeft;
    raum.frame = CGRectMake(x+3, y+(height*0.6), width-6, height*0.4);
    raum.textColor = [UIColor HTWDarkGrayColor];
    
    if([lesson.kurzel componentsSeparatedByString:@" "].count > 1) {
        typ.text = [lesson.kurzel componentsSeparatedByString:@" "][1];
        if(_portait) typ.font = [UIFont HTWLargeFont];
        else typ.font = [UIFont HTWSmallFont];
        typ.textAlignment = NSTextAlignmentRight;
        typ.frame = CGRectMake(x+3, y+(height*0.5), width-6, height*0.4);
        typ.textColor = [UIColor HTWDarkGrayColor];
        [self addSubview:typ];
    }
 
    self.bounds = self.frame;
    [self addSubview:kurzel];
    [self addSubview:raum];
}

#pragma mark - Hilfsfunktionen

- (BOOL)isSameDayWithDate1:(NSDate*)date1 date2:(NSDate*)date2 {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:date1];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:date2];
    
    return [comp1 day]   == [comp2 day] &&
    [comp1 month] == [comp2 month] &&
    [comp1 year]  == [comp2 year];
}

-(int)weekdayFromDate:(NSDate*)date
{
    int weekday = (int)[[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:date] weekday] - 2;
    if(weekday == -1) weekday=6;
    
    return weekday;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"X: %f Y: %f width: %f height: %f stunde: %@", x, y, width, height, lesson.kurzel];
}


@end
