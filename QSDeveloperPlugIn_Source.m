//
//  QSDeveloperPlugIn_Source.m
//  QSDeveloperPlugIn
//
//  Created by Nicholas Jitkoff on 14/04/05
//	Modified by Patrick Robertson on 14/06/11
//

#import "QSDeveloperPlugIn_Source.h"

@interface DSADocSet : NSObject
- (id)initWithDocRootDirectory:(id)fp8;
@end


#define REFROOT @"/Developer/ADC Reference Library/"

@implementation QSDeveloperPlugIn_Source
- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry {
  return NO;
}

- (NSImage *)iconForEntry:(NSDictionary *)dict {
  return [QSResourceManager imageNamed:@"ADCReferenceLibraryIcon"];
}

// Right arrowing into XCode.app
- (BOOL)loadChildrenForObject:(QSObject *)object {
	NSMutableArray *documentsArray = [[NSMutableArray alloc] init];
	NSURL *url;
	NSError *err;
	
	NSArray *recentDocuments = [(NSArray *)CFPreferencesCopyValue((CFStringRef) @"NSRecentXCProjectDocuments", 
														 (CFStringRef) @"com.apple.Xcode", 
														 kCFPreferencesCurrentUser, 
														 kCFPreferencesAnyHost) autorelease];
	
	for(NSData *bookmarkData in recentDocuments) {
		err = nil;
		url = [NSURL URLByResolvingBookmarkData:bookmarkData 
										options:NSURLBookmarkResolutionWithoutMounting|NSURLBookmarkResolutionWithoutUI 
								  relativeToURL:nil 
							bookmarkDataIsStale:NO 
										  error:&err];
		if (url == nil || err != nil) {
			// couldn't resolve bookmark, so skip
			continue;
		}
		[documentsArray addObject:[url path]];
	}
	if (!documentsArray) {
	return NO;
	}
	NSArray *newChildren = [QSObject fileObjectsWithPathArray:documentsArray];
	for(QSObject * child in newChildren) {
		[child setObject:@"com.apple.Xcode" forMeta:@"QSPreferredApplication"];
	}
	[object setChildren:newChildren];
	return YES;
}
- (NSString *)identifierForObject:(id <QSObject>)object {
  return nil;
}
- (NSArray *)objectsForEntry:(NSDictionary *)theEntry {
  NSMutableArray *objects = [NSMutableArray arrayWithCapacity:1];
  QSObject *newObject;

  [[NSBundle bundleWithPath:@"/Developer/Library/PrivateFrameworks/DocSetAccess.framework"] load];
  NSString *rootDir = @"/Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset";
  NSString *rootDirDocuments = [rootDir stringByAppendingPathComponent:@"Contents/Resources/Documents"];
                       
  NSURL *docsURL = [NSURL fileURLWithPath:rootDir];
  id docSet = [[[NSClassFromString(@"DSADocSet") alloc] performSelector:@selector(initWithDocRootDirectory:) withObject:docsURL] autorelease];
  
  NSFileManager *fm = [NSFileManager defaultManager];
  NSArray *nodes = [docSet valueForKeyPath: @"rootNode.searchableNodesInHierarchy"];
  nodes = [nodes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"domain == %ld", (long)1]];

  for (id node in nodes) {
    //NSLog(@"set %@ %@ %@", [node valueForKey:@"name"] , [node valueForKey:@"path"] , [node valueForKey:@"URL"]);
    NSString *name = [node valueForKey:@"name"];
    NSString *path = [node valueForKey:@"path"];
   		
   		if (!path) continue;
   		path = [rootDirDocuments stringByAppendingPathComponent:path];
   		if (![fm fileExistsAtPath:path]) continue;
   		newObject = [QSObject fileObjectWithPath:path];
   		[newObject setName:name];
    [newObject setObject:@"com.apple.Xcode" forMeta:@"QSPreferredApplication"];
   		//[newObject setIdentifier:[NSString stringWithFormat:@"devdoc:%@", (int) [node nodeID]];
   		if (newObject) [objects addObject:newObject];
  }
  return objects;
  
//  NSXMLElement *root = [xml rootElement];
//	NSXMLElement *documentRoot = [[root elementsForName:@"Documents"] lastObject];
//	NSArray *documents = [documentRoot elementsForName:@"Document"];
//	
//	foreach(document, documents) {
//		
//		
//	}
  
  
  
  if (YES) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *baseDir = @"/Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation/";

    
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:baseDir];
    
    BOOL isDir;
    NSString *file;
    while ((file = [dirEnum nextObject])) {
      
      NSString *path = [baseDir stringByAppendingPathComponent:file];  
      NSString *lcPath = [path lowercaseString];
      
      if (([lcPath hasSuffix:@"_class"] || [lcPath hasSuffix:@"_functions"] || [lcPath hasSuffix:@"_protocol"] || [lcPath hasSuffix:@"_ref"] || [lcPath hasSuffix:@"_reference"]) && [fileManager fileExistsAtPath:path isDirectory:&isDir] && isDir) {
        
        NSString *indexPath = [path stringByAppendingPathComponent:@"index.html"];
        
        newObject = [QSObject fileObjectWithPath:indexPath];
        [newObject setName:[[file lastPathComponent] stringByReplacing:@"_" with:@" "]];
        if (newObject) {
          [objects addObject:newObject];
        }
      }
    }
    
    
    return objects;
  }
  
  
  
  if (YES) {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *dirs = [NSArray arrayWithObjects:@"/Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation/Cocoa/Reference/ApplicationKit/Classes",  
                     @"/Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation/Cocoa/Reference/Foundation/Classes",  
                     nil];
    
    NSEnumerator *e = [dirs objectEnumerator];
    NSString *dir;
    
    while ((dir = [e nextObject]) ) {
      
      
      NSEnumerator *de = [[fileManager contentsOfDirectoryAtPath:dir error:nil] objectEnumerator];
      NSString *junk;
      
      while ((junk = [de nextObject]) ) {
        
        NSRange junkRange = [junk rangeOfString:@"_"];
        if (junkRange.location != NSNotFound) {
          NSString *name = [junk substringToIndex:junkRange.location];
          NSString *path = [[dir stringByAppendingPathComponent:junk] stringByAppendingPathComponent:@"index.html"];
          
          if (![fileManager fileExistsAtPath:path]) {
            continue;
          }
          
          newObject = [QSObject fileObjectWithPath:path];
          [newObject setName:name];
          //[newObject setIdentifier:[NSString stringWithFormat:@"devdoc:%@", [[document attributeForName:@"id"] stringValue]]];
          if (newObject) {
            [objects addObject:newObject];
          }
        }
        
        
        
      }
    }
    
    
    return objects;
  }
  
  
  
	NSURL *url = [NSURL fileURLWithPath:[REFROOT stringByAppendingPathComponent:@"docSet.xml"]];
	NSXMLDocument *xml = [[NSXMLDocument alloc] initWithContentsOfURL:url
                                                         options:NSUncachedRead
                                                           error:nil];
	
	
	
	NSXMLElement *root = [xml rootElement];
	NSXMLElement *documentRoot = [[root elementsForName:@"Documents"] lastObject];
	NSArray *documents = [documentRoot elementsForName:@"Document"];
//	NSFileManager *fm = [NSFileManager defaultManager];
	for(NSXMLElement * document in documents) {
		NSString *name = [[[document elementsForName:@"Name"] lastObject] stringValue];
		NSString *path = [[[document elementsForName:@"Path"] lastObject] stringValue];
		
		if (!path) continue;
		path = [REFROOT stringByAppendingPathComponent:path];
		if (![fm fileExistsAtPath:path]) continue;
		newObject = [QSObject fileObjectWithPath:path];
		[newObject setName:name];
		[newObject setIdentifier:[NSString stringWithFormat:@"devdoc:%@", [[document attributeForName:@"id"] stringValue]]];
		//	[newObject setObject:@"" forType:QSDeveloperPlugInType];
		//	[newObject setPrimaryType:QSDeveloperPlugInType];
		if (newObject) [objects addObject:newObject];
		
		
	}
	
  //	NSArray *categoryObjects = [self categoriesForRoot:[[root elementsForName:@"Category"] lastObject]];
  //	
  //	[objects addObjectsFromArray:categoryObjects];
	//NSLog(@"xml %@", documents);
	
	
	
	[xml release];
  return objects;
  
}

- (NSArray *)documentsForRoot:(NSXMLElement *)root {
	
	return nil;
}
- (NSArray *)categoriesForRoot:(NSXMLElement *)root {
	NSMutableArray *objects = [NSMutableArray arrayWithCapacity:1];
  
	NSXMLElement *categoryRoot = [[root elementsForName:@"Categories"] lastObject];
	NSArray *categories = [categoryRoot elementsForName:@"Category"];
	
	for(NSXMLElement * category in categories) {
		NSString *name = [[[category elementsForName:@"Name"] lastObject] stringValue];
		NSString *path = [[[category elementsForName:@"Path"] lastObject] stringValue];
		NSFileManager *fm = [NSFileManager defaultManager];
    
		if (!path) continue;
		path = [REFROOT stringByAppendingPathComponent:path];
		if (![fm fileExistsAtPath:path]) continue;
		QSObject *newObject = [QSObject fileObjectWithPath:path];
		[newObject setName:name];
		//NSLog(@"categ %@", path);
		[newObject setIdentifier:[NSString stringWithFormat:@"devdoc:%@", [[category attributeForName:@"id"] stringValue]]];
		//	[newObject setObject:@"" forType:QSDeveloperPlugInType];
		//	[newObject setPrimaryType:QSDeveloperPlugInType];
		if (newObject) [objects addObject:newObject];
		
		
	}
  return nil;
}


// Object Handler Methods

/*
 - (void)setQuickIconForObject:(QSObject *)object {
	 [object setIcon:nil]; // An icon that is either already in memory or easy to load
 }
 - (BOOL)loadIconForObject:(QSObject *)object {
	 return NO;
	 id data = [object objectForType:QSDeveloperPlugInType];
	 [object setIcon:nil];
	 return YES;
 }
 */
@end
