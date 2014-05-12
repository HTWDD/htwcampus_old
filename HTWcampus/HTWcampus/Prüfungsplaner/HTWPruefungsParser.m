//
//  HTWPruefungsParser.m
//  test
//
//  Created by Benjamin Herzog on 12.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWPruefungsParser.h"

@interface HTWPruefungsParser () <NSXMLParserDelegate>
{
    void (^completition)(NSArray* erg, NSString *error);
    
    NSString* jahr;
    NSString* gruppe;
    NSString *BDM;
    
    int nummerTR;
    int nummerTD;
    BOOL isInTD;
}

@property (nonatomic, strong) NSXMLParser *parser;

@property (nonatomic, strong) NSMutableArray *pruefungenArray;
@property (nonatomic, strong) NSMutableDictionary *pruefungDic;
@property (nonatomic, strong) NSMutableString *stringFound;

@property (nonatomic, strong) NSArray *keys;

@end

@implementation HTWPruefungsParser


-(id)initWithURL:(NSURL*)url andImmaJahr:(NSString*)ejahr andStudienGruppe:(NSString*)egruppe andBDM:(NSString*)eBDM
{
    if(self = [self init])
    {
        self.pruefungsSeitenURL = url;
        jahr = ejahr;
        gruppe = egruppe;
        BDM = eBDM;
        
        _pruefungenArray = [[NSMutableArray alloc] init];
        _pruefungDic = [[NSMutableDictionary alloc] init];
        
        _keys = @[@"Fakultät",@"Studiengang",@"Jahr/Semester",@"Abschluss",@"Studienrichtung",@"Modul",@"Art",@"Tag",@"Zeit",@"Raum",@"Prüfender",@"Nächste WD"];
    }
    return self;
}

-(void)startWithCompletetionHandler:(void(^)(NSArray *erg, NSString *errorMessage))handler
{
    completition = handler;
    
    // Request String für PHP-Argumente
    NSString *myRequestString = [NSString stringWithFormat:@"was=1&feld1=%@&feld2=%@&feld3=%@", jahr, gruppe, BDM];
    
    // NSData synchron füllen (wird im ViewController durch unterschiedliche Threads ansynchron)
    NSData *myRequestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_pruefungsSeitenURL
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10];
    
    [request setHTTPMethod: @"POST"];
    // Set content-type
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    // Set Request Body
    [request setHTTPBody: myRequestData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if(connectionError) { NSLog(@"%@", connectionError.localizedDescription); return;}
        
        NSMutableString *html = [[NSMutableString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        
        NSRange startRange = [html rangeOfString:@"</h2>"];
        NSMutableString *dataAfterHtml = [NSMutableString stringWithString:[html substringFromIndex:startRange.location + @"</h2>\n".length]];
        NSRange endRange = [dataAfterHtml rangeOfString:@"</table>"];
        dataAfterHtml = [NSMutableString stringWithString:[dataAfterHtml substringToIndex:endRange.location]];
        [dataAfterHtml appendString:@"</table>"];
        [dataAfterHtml replaceOccurrencesOfString:@"&nbsp;" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, dataAfterHtml.length)];
        [dataAfterHtml replaceOccurrencesOfString:@"<br>" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, dataAfterHtml.length)];
        [dataAfterHtml replaceOccurrencesOfString:@"&" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, dataAfterHtml.length)];
        [dataAfterHtml replaceOccurrencesOfString:@"\n" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, dataAfterHtml.length)];
        [dataAfterHtml replaceOccurrencesOfString:@"<table border cellpadding=5>" withString:@"<table>" options:NSCaseInsensitiveSearch range:NSMakeRange(0, dataAfterHtml.length)];
        [dataAfterHtml replaceOccurrencesOfString:@" nowrap" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, dataAfterHtml.length)];

        NSString *parserString = [NSString stringWithFormat:@"<data>%@</data>", dataAfterHtml];
        NSData *dataForParser = [parserString dataUsingEncoding:NSUTF8StringEncoding];
        
        _parser = [[NSXMLParser alloc] initWithData:dataForParser];
        _parser.delegate = self;
        [_parser parse];
    }];
}

-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"%@",parseError.localizedDescription);
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"td"])
    {
        isInTD = YES;
        
    }
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if(isInTD) [_stringFound appendString:string];
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"tr"])
    {
        nummerTR++;
        nummerTD = 0;
        [_pruefungenArray addObject:_pruefungDic];
        _pruefungDic = [NSMutableDictionary new];
    }
    else if ([elementName isEqualToString:@"td"])
    {
        isInTD = NO;
        nummerTD++;
        if(_stringFound.length > 0) [_pruefungDic setObject:_stringFound forKey:_keys[nummerTD-1]];
        else [_pruefungDic setObject:@" " forKey:_keys[nummerTD - 1]];
        _stringFound = [NSMutableString new];
    }
}

-(void)parserDidEndDocument:(NSXMLParser *)parser
{
    completition(_pruefungenArray,nil);
}

@end
