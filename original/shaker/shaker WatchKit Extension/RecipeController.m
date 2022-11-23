//
//  RecipeController.m
//  shaker
//
//  Created by Stanislav Miasnikov on 7/6/15.
//  Copyright (c) 2015 PhatWare Corp. All rights reserved.
//

#import "RecipeController.h"
#import "CoctailsDatabase.h"
#import "utils.h"

@interface RecipeController ()

@property (nonatomic, weak) IBOutlet WKInterfaceLabel * text;
@property (nonatomic, weak) IBOutlet WKInterfaceImage * image;

@property (nonatomic, strong ) CoctailsDatabase * database;
@property (nonatomic) NSInteger recrd_id;
@property (nonatomic, strong ) NSDictionary * recipe;

@end

@implementation RecipeController

- (void)awakeWithContext:(id)context
{
    [super awakeWithContext:context];
    
    // Configure interface objects here.
    NSDictionary * dict = (NSDictionary *)context;
    
    self.recrd_id = [[dict objectForKey:@"id"] integerValue];
    self.database = (CoctailsDatabase *)[dict objectForKey:@"database"];
    
    if ( self.database == nil )
        return;
    
    // load from database and display
    if ( self.recrd_id > 0 )
    {
        self.recipe = [self.database getRecipe:self.recrd_id alcohol:YES noImage:YES];
    }
    NSString * html = [self htmlString:@""];
    
    NSAttributedString * attr_str = [[NSAttributedString alloc] initWithData:[html dataUsingEncoding:NSUTF8StringEncoding]
                                                                     options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                               NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                          documentAttributes:nil error:nil];
    [self.text setAttributedText:attr_str];
    [self.text setTextColor:[UIColor whiteColor]];
    [self.text sizeToFitWidth];
    [self.text sizeToFitHeight];

    [self performSelector:@selector(loadImage) withObject:nil afterDelay:1.0];
}

- (void) loadImage
{
    dispatch_queue_t q_default;
    q_default = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async( q_default, ^(void)
       {
           @synchronized( self )
           {
               @autoreleasepool
               {
                   // load image in the background thread
                   UIImage * image = [self.database getPhoto:self.recrd_id alcohol:YES];
                   dispatch_queue_t q_main = dispatch_get_main_queue();
                   dispatch_sync(q_main, ^(void)
                     {
                         [self.image setImage:image];
                     });
               }
           }
       });
}

- (NSString *) htmlString:(NSString *)strFootnote
{
    NSString * strRating = @"";
    // NSLog( @"%@", self.recipe );
    int rating = [[self.recipe  objectForKey:@"userrating"] intValue];
    if ( rating > 0 )
    {
        strRating = @"<br><b>Rating:</b><br>";
        for ( int i = 0; i < rating; i++ )
        {
            strRating = [strRating stringByAppendingString:@"⭐️"];
        }
    }
    NSString * strNote = [self.recipe objectForKey:@"note"];
    if ( [strNote length] > 0 )
    {
        strNote = [NSString stringWithFormat:@"<br><b>Personal Note:</b></br><i>%@</i>", strNote];
    }
    else
    {
        strNote = @"";
    }
    
    NSString * ing = [self.recipe  objectForKey:@"ingredients"];
    ing = [ing stringByReplacingOccurrencesOfString:@"<li>" withString:@"• "];
    ing = [ing stringByReplacingOccurrencesOfString:@"</li>" withString:@"<br>"];
    ing = [ing stringByReplacingOccurrencesOfString:@"</ul>" withString:@""];
    ing = [ing stringByReplacingOccurrencesOfString:@"<ul>" withString:@""];
    
    // make localizable in the future...
    NSString * html = [NSString stringWithFormat:@"<html> <head>"
                       "<style type=\"text/css\">body {font-family: \"Verdana\"; font-size: 12px;}\n-webkit-touch-callout: none;</style>\n"
                       "<style type=\"text/css\">a {color:blue; text-decoration:none; font-size: 13px;}</style>\n"
                       "<style type=\"text/css\">b {font-size: 14px;}</style>\n"
                       "</head><body><h2>%@</h2>"
                       "<br><p><b>Glass:</b></p> <p>• %@</p><br><p><b>Ingredients:</b></p><p> %@</p>"
                       "<p><b>Instructions:</b></p><p>%@</p><br><p><b>Shopping list:</b></p><p>%@</p><p>%@</p><br><p>%@</p> </p> %@ </body></html>",
                       [self.recipe  objectForKey:@"name"],
                       [self.recipe  objectForKey:@"glass"],
                       ing,
                       [self.recipe  objectForKey:@"instructions"],
                       [self.recipe  objectForKey:@"shopping"],
                       strRating, strNote, strFootnote];
    
    return html;
}


- (void) dealloc
{
    self.database = nil;
    self.recipe = nil;
}

- (void)willActivate
{
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate
{
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



